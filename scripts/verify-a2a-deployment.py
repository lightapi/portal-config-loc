#!/usr/bin/env python3
"""Explicit A2A diagnostic; requires an already bootstrapped, running database."""
import datetime
import json
import subprocess
import sys
from pathlib import Path

import yaml


def run(command, **kwargs):
    return subprocess.run(command, check=True, capture_output=True, text=True, **kwargs).stdout


def validate_snapshot(record, identity):
    if not record:
        raise ValueError('no current activated snapshot for the configured A2A identity')
    properties = record.get('properties') or {}
    if not isinstance(properties, dict):
        raise ValueError('snapshot properties must be an object')
    # Match the non-empty defaults in a2a.yml. Explicit NULL values are invalid,
    # rather than silently treated as an omitted property.
    defaults = {'runtimePolicy.serviceId': 'com.networknt.light-a2a-1.0.0',
                'runtimePolicy.envTag': 'dev', 'runtimePolicy.audience': 'light-a2a'}
    effective = defaults | properties
    for key, expected in identity.items():
        if effective.get('runtimePolicy.' + key) != expected:
            raise ValueError('activated runtimePolicy.' + key + ' does not match startup')
    if effective.get('runtimePolicy.audience') != 'light-a2a':
        raise ValueError('activated snapshot is not a light-a2a policy')
    raw_bindings = properties.get('a2aPolicy.bindings')
    if not isinstance(raw_bindings, str):
        raise ValueError('activated a2aPolicy.bindings must be a JSON list string')
    bindings = json.loads(raw_bindings)
    if not isinstance(bindings, list) or not bindings:
        raise ValueError('activated A2A policy has no backend bindings')
    now = datetime.datetime.now(datetime.timezone.utc)
    for key in ('validFrom', 'expiresAt'):
        raw_value = properties.get('runtimePolicy.' + key)
        if not isinstance(raw_value, str) or not raw_value:
            raise ValueError('activated runtimePolicy.' + key + ' must be a timestamp string')
        value = datetime.datetime.fromisoformat(raw_value.replace('Z', '+00:00'))
        if value.tzinfo is None or (key == 'expiresAt' and value <= now) or (key == 'validFrom' and value > now):
            raise ValueError('activated A2A policy is outside its validity window')
    # Store bindings are supplied by local values.yml; the runtime validates the
    # effective store configuration and database identity when it starts.
    for key in ('runtimePolicy.publicationId', 'runtimePolicy.policyDigest'):
        if not properties.get(key):
            raise ValueError('activated A2A snapshot is missing ' + key)


def verify(runtime, compose):
    config = json.loads(run(compose + ['config', '--format', 'json']))
    services = config['services']
    service = services.get('light-a2a')
    if service is None:
        return
    image = service.get('image')
    if not image:
        raise ValueError('light-a2a has no image selected')
    try:
        run([runtime, 'image', 'inspect', image])
    except subprocess.CalledProcessError:
        try:
            run([runtime, 'pull', image])
        except subprocess.CalledProcessError as error:
            raise ValueError('A2A image is unavailable: ' + image +
                             '; build apps/light-a2a/build.sh and set LIGHT_A2A_IMAGE') from error
    mounts = {mount['target']: mount.get('source') for mount in service.get('volumes', [])}
    values = yaml.safe_load((Path(mounts['/config']) / 'values.yml').read_text())
    identity = {'host': str(values['startup.host']), 'serviceId': str(values['server.serviceId']),
                'envTag': str(values['server.environment'])}
    postgres = services['postgres'].get('container_name', 'postgres')
    command = [runtime, 'exec', '-i', postgres, 'psql', '-X', '-U', 'postgres', '-d',
               'configserver', '-At', '-v', 'ON_ERROR_STOP=1']
    for key, value in identity.items():
        command += ['-v', key + '=' + value]
    sql = """
SELECT json_build_object('properties', (
    SELECT json_object_agg(p.property_name, p.property_value)
    FROM configserver.config_snapshot_property_t p WHERE p.snapshot_id=s.snapshot_id
)) FROM configserver.config_snapshot_t s
JOIN configserver.instance_t i ON i.instance_id=s.instance_id AND i.host_id=s.host_id
JOIN configserver.host_t h ON h.host_id=s.host_id
WHERE s.current AND i.active AND h.active
  AND s.service_id=:'serviceId' AND s.env_tag=:'envTag'
  AND concat_ws('.', NULLIF(h.sub_domain,''), h.domain)=:'host';
"""
    try:
        output = run(command, input=sql).strip()
    except subprocess.CalledProcessError as error:
        raise ValueError('cannot read A2A activation from the local Config Server database; '
                         'start/bootstrap the database and author the A2A instance first') from error
    records = [json.loads(line) for line in output.splitlines() if line]
    if len(records) != 1:
        raise ValueError('expected one current activated A2A snapshot; found ' + str(len(records)))
    validate_snapshot(records[0], identity)
    print('Verified A2A image and activated snapshot prerequisites: ' + image)


def main():
    try:
        verify(sys.argv[1], sys.argv[2:])
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print('A2A diagnostic failed: ' + str(error) + '. This diagnostic does not stop services. '
              'See docs/light-a2a-setup.md.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
