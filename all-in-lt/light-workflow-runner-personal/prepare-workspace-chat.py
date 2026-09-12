#!/usr/bin/env python3
"""Prepare a private native runner deployment and Portal authoring profile; does not start or publish."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import yaml


def digest(value):
    return 'sha256:' + hashlib.sha256(value).hexdigest()


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--store', type=Path, default=Path('/home/steve/.local/share/light-workspace'))
    parser.add_argument('--workspace-id', default='personal')
    parser.add_argument('--subject', required=True)
    parser.add_argument('--authorization-revision', type=int, default=1)
    parser.add_argument('--output', type=Path, required=True, help='New private deployment directory')
    args = parser.parse_args()
    base = Path(__file__).resolve().parent
    sources = base.parents[2] / 'light-fabric'
    old = base / '.runtime/codex-personal'
    dest = args.output.resolve()
    if dest.exists():
        raise SystemExit('Use a new output directory to preserve an active deployment')
    config = yaml.safe_load((old / 'runner.yml').read_text())
    profile = json.loads((old / 'coding-profile.json').read_text())
    registration = json.loads((args.store / args.workspace_id / 'workspace.json').read_text())
    agent = config['agentWorker']['originServiceId']
    if registration['hostId'] != config['hostId'] or agent not in registration['agents']:
        raise SystemExit('Registered workspace must match the real Portal Host and grant this agent')
    if not {'edit', 'review'}.issubset(registration['operations']):
        raise SystemExit('Workspace requires edit and review grants')
    if args.authorization_revision < 1:
        raise SystemExit('authorization revision must be positive')
    repositories = [{key: repo[key] for key in ('name', 'source', 'integrationBranch', 'releaseBranch')}
                    for repo in sorted(registration['repositories'], key=lambda repo: repo['name'])]
    revision = digest(json.dumps([registration['schemaVersion'], registration['id'], registration['hostId'], repositories],
                                separators=(',', ':'), ensure_ascii=False).encode())
    binding = dict(schemaVersion=1, workspaceId=registration['id'], hostId=registration['hostId'],
                   environment='dev', runnerId=config['runnerId'], membershipRevision=revision,
                   authorizationRevision=args.authorization_revision, subjects=[args.subject], agents=[agent], intents=['inspect', 'implement', 'review'])
    dest.mkdir(mode=0o700, parents=True)

    def write(name, value):
        path = dest / name
        with path.open('x') as stream:
            os.chmod(path, 0o600)
            stream.write(value)

    for name in ('light-agent-worker', 'light-workflow-runner'):
        shutil.copyfile(sources / 'target/x86_64-unknown-linux-musl/release' / name, dest / name)
        (dest / name).chmod(0o700)
    worker = dest / 'light-agent-worker'
    capabilities = json.loads(subprocess.check_output([worker, 'print-capabilities']))
    worker_digest = digest(worker.read_bytes())
    template = dict(name='personal-codex-worker-v1', executable=str(worker), binaryDigest=worker_digest,
                    capabilityDigest=capabilities['capabilityDigest'])
    template_digest = digest(canonical(template))
    config['agentWorker'].update(executable=str(worker), binaryDigest=worker_digest,
                                capabilityDigest=capabilities['capabilityDigest'], workspaceConfig=str(dest / 'workspace.json'))
    config['backend']['compatibilityDigest'] = template_digest
    config['allowedCommandTemplateDigests'] = [template_digest]
    write('workspace.json', json.dumps(dict(store=str(args.store.resolve()), bindings=[binding]), indent=2)+'\n')
    write('runner.yml', yaml.safe_dump(config, sort_keys=False))
    write('command-template.json', json.dumps(template, indent=2)+'\n')
    profile.update(imageDigest=worker_digest, capabilityDigest=capabilities['capabilityDigest'],
                   compatibilityDigest=template_digest, templateDigest=template_digest, workspaceBindings=[binding])
    keys = 'schemaVersion adapterId adapterVersion adapterProtocolVersion actionKind compatibilityDigest imageDigest capabilityDigest templateId templateVersion templateDigest executable binaryDigest schemaDigest requiredFeatures'.split()
    profile['qualification']['contractDigest'] = digest(canonical({key: profile[key] for key in keys}))
    write('coding-profile.json', json.dumps(profile, indent=2)+'\n')
    env = dict(os.environ, LIGHT_WORKFLOW_RUNNER_CONFIG_FILE=str(dest / 'runner.yml'))
    admission = json.loads(subprocess.check_output([dest / 'light-workflow-runner', 'print-admission',
                           'urn:lightapi:runner:'+config['runnerId'], 'light-workflow'], env=env))
    if 'task-workspace-v1' not in admission['enrollments'][0]['backends'][0]['features']:
        raise SystemExit('Rebuilt runner does not advertise task-workspace-v1')
    write('admission.json', json.dumps(admission, indent=2)+'\n')
    # Non-secret manifest is read by the unprivileged Controller container.
    (dest / 'admission.json').chmod(0o644)
    write('workspace-chat.conf', '[Service]\nExecStart=\nExecStart='+str(dest / 'light-workflow-runner')+'\nEnvironment=LIGHT_WORKFLOW_RUNNER_CONFIG_FILE='+str(dest / 'runner.yml')+'\n')
    print(json.dumps(dict(prepared=str(dest), workspaceId=registration['id'], repositories=len(repositories), membershipRevision=revision)))


if __name__ == '__main__':
    main()
