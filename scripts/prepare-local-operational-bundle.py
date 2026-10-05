#!/usr/bin/env python3
"""Prepare only the reviewed 2.6.0 -> 2.7.0 local OFF upgrade; no credentials/admission changes."""
import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('local_guard',HERE/'check-local-fresh-start.py')
guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)
sys.path.insert(0,str(guard.BASE/'postgres-db/operations/bin'))
from w7_rollout import serialized,verify_assets,Refusal
from w7_ownership import OwnershipError

def prepare(state, fixture_container=None):
    root=guard.BASE/'postgres-db/operations'
    state=Path(state).resolve()
    guard.demand(state==root/'.runtime/w7/prepared.json')
    pins,rows=verify_assets(root)
    last=rows[-1]
    guard.demand(last[:4]==(45,'workflow-store','workflow_ops','0026_host_tool_workflow_access'))
    guard.demand(last[5]=='d7a0c9a82e698d5d2d09849fcc5ed40fe530aa4296d4d66cc0f97f6dacc6ae9b')
    folder=state.parent
    with serialized(folder):
        guard.check(state,upgrade_baseline=True,fixture_container=fixture_container)
        # Preflight all databases before installing anywhere. No role provisioning.
        credentials=guard.sql('postgres',"SELECT md5(string_agg(rolname||coalesce(rolpassword,''),',' ORDER BY rolname)) FROM pg_authid;")
        marker=folder/'startup-ready.sha256'
        guard.demand(not marker.is_symlink())
        mode=marker.stat().st_mode & 0o777 if marker.exists() else state.stat().st_mode & 0o777
        # Keep old readiness inode/group permissions; truncate under the common
        # lock so interrupted preparation cannot leave valid restart permission.
        with marker.open('w') as stream:
            stream.flush();os.fsync(stream.fileno())
        applied=[]
        for database in guard.DATABASES:
            guard.check(state,upgrade_baseline=True,fixture_container=fixture_container)
            recorded=guard.sql(database,"SELECT migration_digest FROM operational_meta.operational_schema_migration_t WHERE migration_owner='workflow-store' AND schema_name='workflow_ops' AND migration_id='0026_host_tool_workflow_access';")
            if recorded:
                guard.demand(recorded=='sha256:'+last[5])
                continue
            body=(root/'bundle'/last[4]).read_text().replace('operations_',database+'_')
            body='\n'.join(line for line in body.splitlines() if line not in ('BEGIN;','COMMIT;'))
            transaction=f"BEGIN; SET LOCAL ROLE {database}_workflow_migrator;\n"+body+f"\nRESET ROLE; INSERT INTO operational_meta.operational_schema_migration_t(migration_owner,schema_name,migration_id,migration_digest,bundle_version,contract_generation) VALUES('workflow-store','workflow_ops','0026_host_tool_workflow_access','sha256:{last[5]}','2.7.0',2); COMMIT;"
            guard.sql(database,transaction)
            applied.append(database)
        guard.check(state,fixture_container=fixture_container)
        for database in guard.DATABASES:
            role=database+'_workflow_runtime'
            result=guard.sql(database,f"SELECT bool_and(has_table_privilege('{role}','workflow_ops.'||name,'SELECT') AND has_table_privilege('{role}','workflow_ops.'||name,'INSERT') AND NOT has_table_privilege('{role}','workflow_ops.'||name,'UPDATE') AND NOT has_table_privilege('{role}','workflow_ops.'||name,'DELETE') AND NOT has_table_privilege('{role}','workflow_ops.'||name,'TRUNCATE')) FROM (VALUES('workflow_accepted_tool_authority_t'),('workflow_tool_authority_acceptance_t')) required(name);")
            guard.demand(result=='t')
            guard.demand(guard.sql(database,"SELECT count(*) FROM pg_class WHERE oid IN ('workflow_ops.tool_workflow_access_t'::regclass,'workflow_ops.workflow_accepted_tool_authority_t'::regclass,'workflow_ops.workflow_tool_authority_acceptance_t'::regclass) AND relowner='"+database+"_workflow_migrator'::regrole;")=='3')
        guard.demand(credentials==guard.sql('postgres',"SELECT md5(string_agg(rolname||coalesce(rolpassword,''),',' ORDER BY rolname)) FROM pg_authid;"))
        paths=['w7-assets.json','bundle/bundle.sha256','.runtime/w7/prepared.json','w7-ownership-v1.json','bin/w7_rollout.py','bin/w7_ownership.py','bin/bundle_contract.py']
        content=''.join(hashlib.sha256((root/name).read_bytes()).hexdigest()+'  '+name+'\n' for name in paths)
        with marker.open('w') as stream:
            stream.write(content);stream.flush();os.fsync(stream.fileno())
        marker.chmod(mode)
        return {'bundleVersion':'2.7.0','migrations':45,'appliedDatabases':applied,'admissionOff':True,'credentialsPreserved':True,'historicalPreparationRecordPreserved':True}

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--state',required=True)
    parser.add_argument('--fixture-container')
    args=parser.parse_args()
    try:print(json.dumps(prepare(args.state,args.fixture_container)))
    except (ValueError,KeyError,OSError,subprocess.SubprocessError,Refusal,OwnershipError):
        raise SystemExit('LOCAL_BUNDLE_PREPARATION_REFUSED') from None
