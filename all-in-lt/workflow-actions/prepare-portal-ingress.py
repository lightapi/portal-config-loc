#!/usr/bin/env python3
"""Explicit local-development ingress activation; never print credential material.

Uses the same local issuer fixture policy as prepare.py. No database writes.
Existing Workflow policy entries and CA trust are preserved. Output must be new.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

SERVICE = 'com.networknt.portal.workflow-ingress-local-1.0.0'


def run(*args, data=None):
    return subprocess.check_output(args, input=data, stderr=subprocess.DEVNULL)


def private(path, data):
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), 'wb') as f:
        f.write(data.encode() if isinstance(data, str) else data)


def b64(value):
    return base64.urlsafe_b64encode(value).decode().rstrip('=')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--activate', action='store_true')
    args = parser.parse_args()
    out = args.output.resolve()
    out.mkdir(mode=0o700, parents=True, exist_ok=False)
    previous = run('docker', 'exec', 'light-gateway', 'cat', '/config/workflow-actions.yml')
    config = json.loads(previous.decode().removeprefix('authorization: '))
    assert SERVICE not in config['policy']['apps'], 'Ingress already configured'
    assert all(p['origin'] != 'interactive' for p in config['policy']['apps'].values())
    private(out / 'gateway-policy.previous.yml', previous)
    old_ca = run('docker', 'exec', 'light-gateway', 'cat', config['incomingClientCaFile'])
    run('openssl', 'req', '-x509', '-newkey', 'rsa:3072', '-nodes', '-keyout', str(out/'ca.key'),
        '-out', str(out/'ca.pem'), '-days', '3650', '-sha256', '-subj', '/CN=Local Portal ingress CA')
    run('openssl', 'req', '-new', '-newkey', 'rsa:2048', '-nodes', '-keyout', str(out/'client.key'),
        '-out', str(out/'client.csr'), '-subj', '/CN=Local Portal workflow ingress')
    private(out/'client.ext', 'basicConstraints=CA:FALSE\nextendedKeyUsage=clientAuth\nkeyUsage=digitalSignature\n')
    run('openssl', 'x509', '-req', '-in', str(out/'client.csr'), '-CA', str(out/'ca.pem'),
        '-CAkey', str(out/'ca.key'), '-CAcreateserial', '-out', str(out/'client.pem'),
        '-days', '3650', '-sha256', '-extfile', str(out/'client.ext'))
    fingerprint = hashlib.sha256(run('openssl', 'x509', '-in', str(out/'client.pem'), '-outform', 'DER')).hexdigest()
    # Local fixture signing only; material stays in memory, never in output/logs.
    inspect = json.loads(run('docker', 'inspect', 'light-gateway'))[0]
    env = dict(v.split('=', 1) for v in inspect['Config']['Env'] if '=' in v)
    token = env['LIGHT_PORTAL_AUTHORIZATION'].removeprefix('Bearer ')
    kid = json.loads(base64.urlsafe_b64decode(token.split('.')[0] + '=='))['kid']
    assert kid and all(c.isalnum() or c in '-_' for c in kid)
    key_pem = run('docker', 'exec', 'postgres', 'psql', '-U', 'postgres', '-d', 'configserver', '-Atc',
                  "SELECT private_key FROM auth_provider_key_t WHERE kid='" + kid + "';").decode().strip()
    if 'BEGIN' not in key_pem:
        key_pem = '-----BEGIN PRIVATE KEY-----\n' + key_pem + '\n-----END PRIVATE KEY-----\n'
    key = serialization.load_pem_private_key(key_pem.encode(), password=None)
    del key_pem, token, env, inspect
    now = int(time.time())
    policy = config['policy']
    claims = dict(iss=policy['issuer'], aud=policy['audience'], sub=SERVICE, sid=SERVICE,
                  cid=SERVICE, client_id=SERVICE, host=policy['hostId'], token_use='app',
                  iat=now, nbf=now-30, exp=now+86400, scp=[], scope='')
    encode = lambda v: b64(json.dumps(v, separators=(',', ':'), sort_keys=True).encode())
    message = (encode(dict(alg='RS256', typ='JWT', kid=kid)) + '.' + encode(claims)).encode()
    private(out/'scope-token', 'Bearer ' + message.decode() + '.' + b64(key.sign(message, padding.PKCS1v15(), hashes.SHA256())) + '\n')
    private(out/'gateway-ca.pem', run('docker', 'exec', 'light-gateway', 'cat', '/config/ca.pem'))
    private(out/'client-ca-bundle.pem', old_ca + b'\n' + (out/'ca.pem').read_bytes())
    policy['apps'][SERVICE] = dict(origin='interactive', peerSha256=[fingerprint])
    config['incomingClientCaFile'] = '/run/workflow-actions/portal-ingress-client-ca.pem'
    proposed = ('authorization: ' + json.dumps(config, separators=(',', ':')) + '\n').encode()
    private(out/'gateway-policy.proposed.yml', proposed)
    private(out/'ingress.json', json.dumps(dict(origin='https://localhost:3000', target='https://localhost/mcp',
        caFile='gateway-ca.pem', certificateFile='client.pem', keyFile='client.key', scopeTokenFile='scope-token')))
    private(out/'manifest.json', json.dumps(dict(serviceId=SERVICE, peerSha256=fingerprint,
        appExpiresAt=now+86400, previousPolicySha256=hashlib.sha256(previous).hexdigest(),
        proposedPolicySha256=hashlib.sha256(proposed).hexdigest()), indent=2))
    for p in out.iterdir():
        p.chmod(0o600)
    if args.activate:
        # Dedicated mounts are read-only inside Gateway. Resolve only its two
        # known mount destinations, then use an isolated helper for runtime files.
        mounts = json.loads(run('docker', 'inspect', 'light-gateway'))[0]['Mounts']
        sources = {m['Destination']: m['Source'] for m in mounts}
        policy_path = sources['/config/workflow-actions.yml']
        pki_path = sources['/run/workflow-actions']
        assert run('docker', 'exec', 'light-gateway', 'cat', '/config/workflow-actions.yml') == previous
        script = ('set -eu; test ! -e /pki/portal-ingress-client-ca.pem; '
                  'cp /source/client-ca-bundle.pem /pki/portal-ingress-client-ca.pem; '
                  'chmod 644 /pki/portal-ingress-client-ca.pem; '
                  'cat /source/gateway-policy.proposed.yml > /policy')
        run('docker', 'run', '--rm', '--network', 'none', '--user', '0',
            '-v', str(out)+':/source:ro', '-v', policy_path+':/policy', '-v', pki_path+':/pki',
            'networknt/light-gateway:2.3.5-dev.20260909.2338', 'sh', '-ec', script)
        assert run('docker', 'exec', 'light-gateway', 'cat', '/config/workflow-actions.yml') == proposed
    print('Local ingress ' + ('activated on disk' if args.activate else 'prepared') + '; restart Gateway to load policy.')
    print('Server-only configuration: ' + str(out/'ingress.json'))


if __name__ == '__main__':
    main()
