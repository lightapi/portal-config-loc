#!/usr/bin/env python3
"""Prepare two native runner upgrades sharing one store; never publish or restart."""
import argparse, copy, hashlib, json, os
from pathlib import Path
import shutil, subprocess
import yaml


def digest(data):return 'sha256:'+hashlib.sha256(data).hexdigest()
def canonical(value):return digest(json.dumps(value,sort_keys=True,separators=(',',':')).encode())


def main():
    p=argparse.ArgumentParser(description=__doc__)
    for key in ['codex-config','claude-config','codex-profile','claude-profile','workspace-config','fabric','output']:
        p.add_argument('--'+key,type=Path,required=True)
    p.add_argument('--workflow-subject',action='append',default=[],help='Explicit workflow-agent:<definition UUID> grant')
    args=p.parse_args();output=args.output.resolve()
    output.mkdir(mode=0o700,parents=True,exist_ok=False)
    shared=json.loads(args.workspace_config.read_text())
    profiles={name:json.loads(getattr(args,name+'_profile').read_text()) for name in ['codex','claude']}
    configs={name:yaml.safe_load(getattr(args,name+'_config').read_text()) for name in profiles}
    agents=sorted(c['agentWorker']['originServiceId'] for c in configs.values())
    for name in profiles:
        config=copy.deepcopy(configs[name]);profile=copy.deepcopy(profiles[name]);dest=output/name;dest.mkdir(mode=0o700)
        def write(file,text):
            path=dest/file;path.write_text(text);path.chmod(0o600)
        for binary in ['light-workflow-runner','light-claude-worker' if name=='claude' else 'light-agent-worker']:
            shutil.copyfile(args.fabric/'target/debug'/binary,dest/binary);(dest/binary).chmod(0o700)
        worker=dest/('light-claude-worker' if name=='claude' else 'light-agent-worker')
        caps=json.loads(subprocess.check_output([worker,'print-capabilities']))
        template=dict(name='personal-'+name+'-worker-v1',executable=str(worker),binaryDigest=digest(worker.read_bytes()),capabilityDigest=caps['capabilityDigest'])
        template_digest=canonical(template)
        bindings=copy.deepcopy(shared['bindings'])
        for binding in bindings:
            registration=json.loads((Path(shared['store'])/binding['workspaceId']/'workspace.json').read_text())
            if not set(agents).issubset(registration['agents']):raise ValueError('Registration must already grant both Agent service IDs; do not rewrite existing task metadata')
            if binding['hostId']!=config['hostId']:raise ValueError('Workspace Host differs from runner')
            binding.update(runnerId=config['runnerId'],agents=agents,intents=['inspect','implement','review'],authorizationRevision=binding['authorizationRevision']+1)
            binding['subjects']=sorted(set(binding['subjects']+args.workflow_subject))
        write('workspace.json',json.dumps(dict(store=shared['store'],bindings=bindings),indent=2)+'\n')
        config['agentWorker'].update(executable=str(worker),binaryDigest=template['binaryDigest'],capabilityDigest=caps['capabilityDigest'],workspaceConfig=str(dest/'workspace.json'))
        config['backend']['compatibilityDigest']=template_digest;config['allowedCommandTemplateDigests']=[template_digest]
        write('runner.yml',yaml.safe_dump(config,sort_keys=False));write('command-template.json',json.dumps(template,indent=2)+'\n')
        profile.update(imageDigest=template['binaryDigest'],capabilityDigest=caps['capabilityDigest'],compatibilityDigest=template_digest,templateDigest=template_digest,workspaceBindings=bindings)
        keys='schemaVersion adapterId adapterVersion adapterProtocolVersion actionKind compatibilityDigest imageDigest capabilityDigest templateId templateVersion templateDigest executable binaryDigest schemaDigest requiredFeatures'.split()
        profile['qualification']['contractDigest']=canonical({k:profile[k] for k in keys})
        write('coding-profile.json',json.dumps(profile,indent=2)+'\n')
        env=dict(os.environ,LIGHT_WORKFLOW_RUNNER_CONFIG_FILE=str(dest/'runner.yml'))
        admission=json.loads(subprocess.check_output([dest/'light-workflow-runner','print-admission','urn:lightapi:runner:'+config['runnerId'],'light-workflow'],env=env))
        if 'task-workspace-v1' not in admission['enrollments'][0]['backends'][0]['features']:raise ValueError('Runner lacks workspace capability')
        write('admission.json',json.dumps(admission,indent=2)+'\n')
        write('shared-workspace.conf','[Service]\nExecStart=\nExecStart='+str(dest/'light-workflow-runner')+'\nEnvironment=LIGHT_WORKFLOW_RUNNER_CONFIG_FILE='+str(dest/'runner.yml')+'\n')
    print('Prepared both runners and publishable profiles:',output)


if __name__=='__main__':main()
