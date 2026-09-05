#!/usr/bin/env python3
"""Enroll the local personal runner using the existing local OAuth issuer.

Run after building the runner/worker and installing the qualified Codex binary
at .runtime/codex-0.153.4/bin/codex. Private keys stay in memory; generated credentials are 0600.
"""
import base64
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

import yaml
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding

root = Path(__file__).resolve().parent
workspace = root.parents[2]
runtime = root / '.runtime'
runtime.mkdir(mode=0o700, exist_ok=True)
runtime.chmod(0o700)


def output(*args, **kwargs):
    return subprocess.check_output(args, text=True, **kwargs)


def write_private(path, text):
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, 'w') as stream:
        stream.write(text)
    path.chmod(0o600)


def digest(value):
    return 'sha256:' + hashlib.sha256(value).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':')).encode()


def b64(value):
    return base64.urlsafe_b64encode(value).decode().rstrip('=')


containers = {name: json.loads(output('docker', 'inspect', name))[0]
              for name in ['controller', 'light-agent', 'light-agent-advisor', 'light-agent-tech-support']}
agent_env = dict(v.split('=', 1) for v in containers['light-agent']['Config']['Env'])
original = agent_env['LIGHT_PORTAL_AUTHORIZATION'].removeprefix('Bearer ')
agent_claims = json.loads(base64.urlsafe_b64decode(original.split('.')[1] + '=='))
header = json.loads(base64.urlsafe_b64decode(original.split('.')[0] + '=='))
kid = header['kid']
assert all(c.isalnum() or c in '-_' for c in kid)
material = output('docker', 'exec', 'postgres', 'psql', '-U', 'postgres', '-d', 'configserver', '-Atc',
                  "SELECT private_key FROM configserver.auth_provider_key_t WHERE kid='" + kid + "';").strip()
if 'BEGIN' not in material:
    material = '-----BEGIN PRIVATE KEY-----\n' + material + '\n-----END PRIVATE KEY-----\n'
key = serialization.load_pem_private_key(material.encode(), password=None)
del material


def sign(claims):
    message = (b64(canonical({'alg': 'RS256', 'typ': 'JWT', 'kid': kid})) + '.' + b64(canonical(claims))).encode()
    return message.decode() + '.' + b64(key.sign(message, padding.PKCS1v15(), hashes.SHA256()))


host = '01964b05-552a-7c4b-9184-6857e7f3dc5f'
subject = 'urn:lightapi:runner:personal-codex-runner'
now = int(time.time())
claims = {'sub': subject, 'host': host, 'runner_id': 'personal-codex-runner',
          'enrollment_id': 'personal-codex-runner-enrollment', 'scp': ['runner.connect'],
          'aud': 'urn:lightapi:runner', 'iss': 'urn:com:networknt:oauth2:v1',
          'iat': now, 'nbf': now - 30, 'exp': now + 30 * 86400}
write_private(runtime / 'runner.jwt', sign(claims) + '\n')
worker = runtime / 'light-agent-worker'
runner = runtime / 'light-workflow-runner'
capabilities = json.loads(output(str(worker), 'print-capabilities'))
template = {'name': 'personal-codex-worker-v1', 'executable': str(worker),
            'binaryDigest': digest(worker.read_bytes()), 'capabilityDigest': capabilities['capabilityDigest']}
(runtime / 'command-template.json').write_text(json.dumps(template, indent=2) + '\n')
config = yaml.safe_load((root / 'runner.yml.example').read_text())
config.update(jwtFile=str(runtime / 'runner.jwt'), dataDirectory=str(runtime / 'data'))
config['backend']['compatibilityDigest'] = digest(canonical(template))
config['allowedCommandTemplateDigests'] = [digest(canonical(template))]
config['agentWorker'].update(originServiceId=agent_claims['sid'], executable=str(worker), binaryDigest=template['binaryDigest'],
                            capabilityDigest=capabilities['capabilityDigest'], codexHome=str(Path.home() / '.codex'),
                            codexExecutable=str(runtime / 'codex-0.153.4' / 'bin' / 'codex'))
(runtime / 'runner.yml').write_text(yaml.safe_dump(config, sort_keys=False))
env = dict(os.environ, LIGHT_WORKFLOW_RUNNER_CONFIG_FILE=str(runtime / 'runner.yml'))
admission = output(str(runner), 'print-admission', subject, 'light-workflow', env=env)
(runtime / 'admission.json').write_text(admission)
services = {'controller': {'image': containers['controller']['Config']['Image'],
    'ports': ['127.0.0.1:8438:8438'],
    'environment': {'CONTROLLER_RUNNER_ENABLED': 'true',
                    'CONTROLLER_RUNNER_ADMISSION_PATH': '/run/runner-admission.json',
                    'CONTROLLER_RUNNER_JWT_AUDIENCE': 'urn:lightapi:runner'},
    'volumes': [str(runtime / 'admission.json') + ':/run/runner-admission.json:ro']}}
for name in ['light-agent', 'light-agent-advisor', 'light-agent-tech-support']:
    values = dict(v.split('=', 1) for v in containers[name]['Config']['Env'])
    token = values['LIGHT_PORTAL_AUTHORIZATION'].removeprefix('Bearer ')
    claims = json.loads(base64.urlsafe_b64decode(token.split('.')[1] + '=='))
    scopes = claims.get('scp', [])
    if isinstance(scopes, str):
        scopes = scopes.split()
    claims['scp'] = sorted(set(scopes) | {'execution.invoke'})
    claims['scope'] = ' '.join(claims['scp'])
    services[name] = {'image': containers[name]['Config']['Image'],
                      'environment': {'LIGHT_PORTAL_AUTHORIZATION': 'Bearer ' + sign(claims)}}
write_private(runtime / 'compose.yml', yaml.safe_dump({'services': services}, sort_keys=False))
print('Generated exact runner admission and private local Compose overlay. Runner JWT expires in 30 days.')
