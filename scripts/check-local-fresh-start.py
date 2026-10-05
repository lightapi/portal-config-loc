#!/usr/bin/env python3
"""Read-only OFF barrier for this local fresh-operational-database startup.

This is not historical migration qualification or a W7 qualification reference.
Normal deployment continues to use the existing W7 evidence path.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys

BASE = Path(__file__).resolve().parents[1] / 'all-in-lt'
DATABASES = ('operations', 'operations_networknt', 'operations_taiji')
CONTAINER = 'postgres'
sys.path.insert(0, str(BASE / 'postgres-db/operations/bin'))
from bundle_contract import verify_bundle

def demand(value):
    if not value:
        raise ValueError('local fresh startup identity/schema/OFF check failed')

def command(argv, text=None):
    result = subprocess.run(argv, input=text, text=True, capture_output=True, timeout=120)
    demand(result.returncode == 0)
    return result.stdout.strip()

def sql(database, text):
    demand(database in ('postgres', 'configserver') + DATABASES)
    return command(['docker', 'exec', '-i', CONTAINER, 'psql', '-X', '-qAt', '-U', 'postgres', '-d', database, '-v', 'ON_ERROR_STOP=1'], text)

def check(path, *, upgrade_baseline=False, fixture_container=None):
    global CONTAINER
    if fixture_container:
        demand(fixture_container.startswith('host-bundle-q-'))
        CONTAINER = fixture_container
    else:
        CONTAINER = 'postgres'
    path = Path(path).resolve()
    demand(path == BASE / 'postgres-db/operations/.runtime/w7/prepared.json')
    state = json.loads(path.read_text())
    demand(state.get('mode') == 'local-fresh-operational-off' and state.get('historical_qualification') == 'UNQUALIFIED')
    demand(tuple(state['recreated_databases']) == DATABASES)
    endpoint = json.loads(command(['docker', 'context', 'inspect']))[0]['Endpoints']['docker']['Host']
    demand(endpoint == 'unix:///var/run/docker.sock')
    container = json.loads(command(['docker', 'inspect', CONTAINER]))[0]
    if fixture_container:
        demand(container['Config']['Labels'].get('purpose') == 'host-tool-bundle-disposable')
        demand(not any(m.get('Name') == 'all-in-lt_postgres-data' for m in container['Mounts']))
    else:
        demand(container['Config']['Labels']['com.docker.compose.project'] == 'all-in-lt')
        demand(any(m.get('Name') == 'all-in-lt_postgres-data' and m['Destination'] == '/var/lib/postgresql/data' for m in container['Mounts']))
    backup = Path(state['configserver_backup']['path'])
    demand(backup.is_file() and not backup.is_symlink() and hashlib.sha256(backup.read_bytes()).hexdigest() == state['configserver_backup']['sha256'])
    demand(sql('postgres', "SELECT oid FROM pg_database WHERE datname='configserver';") == state['configserver_oid'])
    rows = (BASE / 'postgres-db/operations/bundle/migration-order.tsv').read_text().splitlines()
    expected = [r.split('\t') for r in rows if r and not r.startswith('#')]
    version, verified = verify_bundle(BASE / 'postgres-db/operations/bundle')
    demand(version == '2.7.0')
    demand(expected == [[str(v) for v in row] for row in verified])
    for db in DATABASES:
        demand(sql('postgres', "SELECT oid FROM pg_database WHERE datname='"+db+"';") == state['operational_oids'][db])
        gate = json.loads(sql(db, "SELECT json_build_object('identity',(SELECT row_to_json(x) FROM (SELECT scope_root_id,database_identity,host_fqdn FROM operational_meta.operational_database_identity_t) x),'ledger',(SELECT coalesce(json_agg(x),'[]') FROM (SELECT migration_owner,schema_name,migration_id,migration_digest FROM operational_meta.operational_schema_migration_t ORDER BY migration_id,migration_owner) x));"))
        demand(gate['identity'] == state['identities'][db])
        actual = {(r['migration_owner'],r['schema_name'],r['migration_id']):r['migration_digest'] for r in gate['ledger']}
        full = {(r[1],r[2],r[3]):'sha256:'+r[5] for r in expected}
        baseline = {(r[1],r[2],r[3]):'sha256:'+r[5] for r in expected[:-1]}
        demand(actual == full or (upgrade_baseline and actual == baseline))
        demand(sql(db,"SELECT admission_enabled FROM workflow_ops.workflow_expression_profile_policy_t WHERE profile_id='cel-workflow-v2';") == 'f')
        demand(sql(db,"SELECT count(*) FROM pg_class WHERE oid IN ('workflow_ops.wf_definition_t'::regclass,'workflow_ops.wf_definition_version_t'::regclass,'workflow_ops.process_info_t'::regclass) AND relowner='"+db+"_workflow_migrator'::regrole;") == '3')
        demand(sql(db,"SELECT bool_and(proowner='"+db+"_workflow_migrator'::regrole AND NOT prosecdef) FROM pg_proc WHERE oid IN ('workflow_ops.workflow_claim_host_task_v1(uuid,integer)'::regprocedure,'workflow_ops.workflow_claim_host_task_v2(uuid,integer,text[])'::regprocedure);") == 't')
        role=db+'_workflow_runtime'
        demand(sql(db,f"SELECT NOT rolsuper AND NOT rolcreatedb AND NOT rolcreaterole AND NOT rolreplication AND NOT rolbypassrls AND NOT has_schema_privilege('{role}','workflow_ops','CREATE') AND NOT has_database_privilege('{role}','{db}','CREATE') AND has_table_privilege('{role}','workflow_ops.process_info_t','SELECT,INSERT,UPDATE,DELETE') AND has_table_privilege('{role}','workflow_ops.workflow_expression_profile_policy_t','SELECT') AND NOT has_table_privilege('{role}','workflow_ops.workflow_expression_profile_policy_t','UPDATE') AND NOT has_column_privilege('{role}','workflow_ops.workflow_expression_profile_policy_t','admission_enabled','UPDATE') AND has_table_privilege('{role}','workflow_ops.workflow_operation_receipt_t','SELECT,INSERT') AND NOT has_table_privilege('{role}','workflow_ops.workflow_operation_receipt_t','UPDATE,DELETE,TRUNCATE') FROM pg_roles WHERE rolname='{role}';") == 't')
        demand(sql(db,f"SELECT NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname<>'{role}' AND pg_has_role('{role}',oid,'MEMBER'));") == 't')
        demand(sql(db,"SELECT count(*) FROM pg_constraint WHERE conrelid='workflow_ops.process_info_t'::regclass AND conname='process_expression_profile_snapshot_ck' AND convalidated;") == '1')
    demand(sql('configserver',"SELECT admission_enabled FROM configserver.workflow_expression_profile_policy_t WHERE profile_id='cel-workflow-v2';") == 'f')
    for mid,sha in state['portal_patches'].items():
        demand(sql('configserver',"SELECT checksum FROM configserver.portal_schema_patch_t WHERE patch_id='"+mid+"';") == sha)
    companion = 'patch_20261003_01_local_parser_workflow_expression_profile'
    delivery = 'patch_20261002_02_workflow_delivery_ledger'
    demand(state['portal_patches'] == {
        companion: hashlib.sha256((BASE / 'postgres-db/local-fresh' / (companion+'.sql')).read_bytes()).hexdigest(),
        delivery: '726eb3549e85be0f31deb21163a6d2addb0dd4fe34d5dfc85be9c5060540f4a3'})
    demand(sql('configserver',"SELECT count(*) FROM configserver.portal_schema_patch_t WHERE patch_id='patch_20261002_01_workflow_expression_profile';") == '0')
    runtime_check = Path(__file__).with_name('check-local-portal-runtime.py')
    if fixture_container:
        import importlib.util
        spec=importlib.util.spec_from_file_location('runtime_check',runtime_check)
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        values=json.loads(sql('configserver',module.QUERY))
        demand(values and all(value is True for value in values.values()))
    else:
        command(['python3','-B',str(runtime_check)])
    return state

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--state',required=True);args=parser.parse_args()
    try:check(args.state)
    except (ValueError,KeyError,OSError,subprocess.SubprocessError,json.JSONDecodeError):
        print('LOCAL_FRESH_START_REFUSED',file=sys.stderr);return 2
    print('LOCAL_FRESH_DATABASES_VERIFIED_ADMISSION_OFF_HISTORICAL_UNQUALIFIED');return 0

if __name__ == '__main__':sys.exit(main())
