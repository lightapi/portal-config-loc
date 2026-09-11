#!/usr/bin/env python3
"""Render non-secret Controller admission from the installed personal runner unit."""
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

import yaml

UNIT = 'light-workflow-runner-personal.service'


def property_value(name):
    return subprocess.check_output(
        ['systemctl', '--user', 'show', UNIT, '-p', name, '--value'],
        text=True, stderr=subprocess.DEVNULL).strip()


def admission_document(runtime):
    try:
        installed = property_value('LoadState') == 'loaded'
    except (FileNotFoundError, subprocess.CalledProcessError):
        installed = False
    if not installed:
        if (runtime / 'credentials.compose.yml').exists():
            raise ValueError('Personal runner credentials exist but its user service is not installed. Complete the one-time runner enrollment first.')
        # A developer without a personal enrollment can still start the stack.
        # Empty admission grants no runner or execution origin access.
        return {'version': 1, 'origins': [], 'enrollments': []}
    environment = dict(item.split('=', 1) for item in shlex.split(property_value('Environment')) if '=' in item)
    config_path = Path(environment.get('LIGHT_WORKFLOW_RUNNER_CONFIG_FILE', ''))
    match = re.search(r'\bpath=(.*?) ; argv\[\]=', property_value('ExecStart'))
    if not config_path.is_absolute() or not config_path.is_file() or not match:
        raise ValueError('Installed runner must specify an absolute LIGHT_WORKFLOW_RUNNER_CONFIG_FILE and ExecStart executable.')
    executable = Path(match.group(1))
    if not executable.is_absolute() or not executable.is_file():
        raise ValueError('Installed runner executable is missing; rebuild the enrolled runner.')
    config = yaml.safe_load(config_path.read_text())
    runner_id = config['runnerId']
    env = dict(os.environ, **environment)
    document = json.loads(subprocess.check_output(
        [str(executable), 'print-admission', 'urn:lightapi:runner:' + runner_id, 'light-workflow'],
        env=env, text=True))
    if document.get('version') != 1 or not document.get('enrollments'):
        raise ValueError('Runner produced an invalid admission document.')
    if config.get('agentWorker', {}).get('workspaceConfig'):
        if not any('task-workspace-v1' in backend.get('features', [])
                   for entry in document['enrollments'] for backend in entry.get('backends', [])):
            raise ValueError('Installed workspace runner does not advertise task-workspace-v1.')
    return document


def sync(runtime):
    document = admission_document(runtime)
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    destination = runtime / 'admission.json'
    content = json.dumps(document, indent=2) + '\n'
    if destination.is_file() and destination.read_text() == content:
        return
    # Validate everything before replacing a working manifest. Never print credentials.
    with tempfile.NamedTemporaryFile(mode='w', dir=runtime, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
            os.fchmod(stream.fileno(), 0o644)
            os.replace(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)


if __name__ == '__main__':
    try:
        sync(Path(sys.argv[1]))
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        print('Cannot prepare personal runner admission: ' + str(error), file=sys.stderr)
        sys.exit(1)
    print('Prepared personal runner admission for the default Compose stack.')
