#!/usr/bin/env python3
"""Exercise the exact operational bundle in disposable, network-isolated fixtures."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
DBS = ('operations', 'operations_networknt', 'operations_taiji')

def qualify(baseline, output):
    output = Path(output).resolve(); output.mkdir(parents=True, exist_ok=False)
    results = []
    def run(args, text=None, log=None):
        r = subprocess.run(args, input=text, text=True, capture_output=True, timeout=300)
        if log: (output / log).write_text(r.stdout + r.stderr)
        if r.returncode: raise RuntimeError('fixture command failed: ' + (log or args[0]) + ': ' + (r.stderr if not log else 'see retained log'))
        return r.stdout.strip()
    for version in ('2.7.0', '2.6.0'):
        name = 'host-bundle-q-' + version.replace('.', '-') + '-' + uuid.uuid4().hex[:8]
        with tempfile.TemporaryDirectory(prefix='host-bundle-q-') as temp:
            checkout = Path(temp); scripts = checkout / 'scripts'; scripts.mkdir()
            for file in ('prepare-local-operational-bundle.py', 'check-local-fresh-start.py', 'check-local-portal-runtime.py'):
                shutil.copy2(ROOT / 'scripts' / file, scripts / file)
            stack = checkout / 'all-in-lt'; ops = stack / 'postgres-db/operations'
            shutil.copytree(ROOT / 'all-in-lt/postgres-db/operations', ops, ignore=shutil.ignore_patterns('.runtime', '__pycache__'))
            shutil.copytree(ROOT / 'all-in-lt/postgres-db/local-fresh', stack / 'postgres-db/local-fresh')
            if version == '2.6.0':
                shutil.rmtree(ops / 'bundle'); shutil.copytree(Path(baseline) / 'bundle', ops / 'bundle')
            state_dir = ops / '.runtime/w7'; state_dir.mkdir(parents=True)
            (state_dir / 'w7.lock').touch()
            try:
                run(['docker','run','-d','--pull','never','--network','none','--label','purpose=host-tool-bundle-disposable','--name',name,'-e','POSTGRES_HOST_AUTH_METHOD=trust','-v',str(ops)+':/opt/operational-store','timescale/timescaledb:latest-pg17'])
                for _ in range(60):
                    r = subprocess.run(['docker','exec',name,'pg_isready','-h','127.0.0.1','-U','postgres'],capture_output=True)
                    if r.returncode == 0: break
                    time.sleep(.5)
                else: raise RuntimeError('fixture PostgreSQL did not become ready')
                def sql(db, body):
                    return run(['docker','exec','-i',name,'psql','-X','-qAt','-U','postgres','-d',db,'-v','ON_ERROR_STOP=1'],body)
                for db in DBS + ('configserver',): run(['docker','exec',name,'createdb','-U','postgres',db])
                bootstrap = ['docker','exec','-e','E04_LOCAL_FRESH_INIT=true','-e','PORTAL_DB_TOPOLOGY=separate','-e','OPERATIONAL_BUNDLE_VERSION='+version,name,'bash','/opt/operational-store/bin/bootstrap-operational-databases.sh']
                run(bootstrap, log=version+'-fresh.log')
                # Synthetic catalog fixture for the unchanged local OFF/runtime guard.
                tables = {'wf_definition_t':'SELECT,INSERT,UPDATE,DELETE','wf_definition_version_t':'SELECT,INSERT','process_info_t':'SELECT,INSERT,UPDATE,DELETE','task_info_t':'SELECT,INSERT,UPDATE,DELETE','workflow_worker_capability_t':'SELECT,INSERT,UPDATE','workflow_command_receipt_t':'SELECT,INSERT','workflow_delivery_intent_t':'SELECT,INSERT,UPDATE','workflow_sync_target_t':'SELECT,INSERT,UPDATE','workflow_start_request_t':'SELECT,INSERT,UPDATE'}
                body = 'CREATE ROLE portal_loc_runtime LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS; CREATE SCHEMA configserver; GRANT USAGE ON SCHEMA configserver TO portal_loc_runtime;'
                for table, privileges in tables.items(): body += f'CREATE TABLE configserver.{table}(id integer); GRANT {privileges} ON configserver.{table} TO portal_loc_runtime;'
                body += "CREATE FUNCTION configserver.workflow_claim_host_task_v1(uuid,integer) RETURNS integer LANGUAGE sql AS 'SELECT 1'; CREATE TABLE configserver.workflow_expression_profile_policy_t(profile_id text PRIMARY KEY,admission_enabled boolean NOT NULL); INSERT INTO configserver.workflow_expression_profile_policy_t VALUES('cel-workflow-v2',false); GRANT SELECT,UPDATE(profile_id) ON configserver.workflow_expression_profile_policy_t TO portal_loc_runtime; CREATE TABLE configserver.portal_schema_patch_t(patch_id text PRIMARY KEY,checksum text);"
                companion = 'patch_20261003_01_local_parser_workflow_expression_profile'
                patches = {companion:hashlib.sha256((stack / 'postgres-db/local-fresh' / (companion+'.sql')).read_bytes()).hexdigest(),'patch_20261002_02_workflow_delivery_ledger':'726eb3549e85be0f31deb21163a6d2addb0dd4fe34d5dfc85be9c5060540f4a3'}
                for patch, digest in patches.items(): body += f"INSERT INTO configserver.portal_schema_patch_t VALUES('{patch}','{digest}');"
                sql('configserver',body)
                backup = checkout / 'synthetic-backup'; backup.write_text('synthetic fixture backup reference\n')
                state = {'mode':'local-fresh-operational-off','historical_qualification':'UNQUALIFIED','recreated_databases':list(DBS),'configserver_backup':{'path':str(backup),'sha256':hashlib.sha256(backup.read_bytes()).hexdigest()},'configserver_oid':sql('postgres',"SELECT oid FROM pg_database WHERE datname='configserver';"),'operational_oids':{},'identities':{},'portal_patches':patches}
                for db in DBS:
                    state['operational_oids'][db]=sql('postgres',f"SELECT oid FROM pg_database WHERE datname='{db}';")
                    state['identities'][db]=json.loads(sql(db,'SELECT row_to_json(x) FROM (SELECT scope_root_id,database_identity,host_fqdn FROM operational_meta.operational_database_identity_t) x;'))
                    assert sql(db,'SELECT count(*) FROM operational_meta.operational_schema_migration_t;') == ('45' if version=='2.7.0' else '44')
                state_file = state_dir / 'prepared.json'; state_file.write_text(json.dumps(state))
                original_state = state_file.read_bytes()
                if version == '2.6.0':
                    shutil.rmtree(ops / 'bundle'); shutil.copytree(ROOT / 'all-in-lt/postgres-db/operations/bundle',ops / 'bundle')
                spec = importlib.util.spec_from_file_location('fixture_prepare_'+version.replace('.',''),scripts / 'prepare-local-operational-bundle.py')
                module=importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
                # Imports must use this fixture's BASE (Python caches shared module names).
                module.guard.BASE=stack
                first=module.prepare(state_file,name); repeat=module.prepare(state_file,name)
                assert first['appliedDatabases'] == ([] if version=='2.7.0' else list(DBS))
                assert repeat['appliedDatabases'] == [] and state_file.read_bytes()==original_state
                run(['docker','exec',name,'bash','/opt/operational-store/bin/w7-startup-guard.sh','/opt/operational-store'],log=version+'-startup-guard.log')
                validate=['docker','exec',name,'bash','/opt/operational-store/bin/validate-operational-databases.sh']
                run(validate,log=version+'-database-validation.log')
                # Normal startup: no missing migration replay; private fixture credentials only.
                run(['docker','exec',name,'bash','/opt/operational-store/bin/bootstrap-operational-databases.sh'],log=version+'-normal-startup.log')
                run(validate,log=version+'-repeat-validation.log')
                module.guard.check(state_file,fixture_container=name)
                results.append({'baseline':version,'freshMigrationCount':45 if version=='2.7.0' else 44,'firstPreparation':first,'repeatPreparation':repeat,'normalStartupPassed':True,'ownershipAndRuntimeACLsPassed':True,'admissionOff':True,'syntheticCatalogGuardFixture':True})
            finally:
                subprocess.run(['docker','rm','-f','-v',name],capture_output=True,check=True)
                assert subprocess.run(['docker','inspect',name],capture_output=True).returncode != 0
    (output / 'results.json').write_text(json.dumps({'qualified':True,'paths':results,'fixturesRemoved':True},indent=2)+'\n')
    print('BUNDLE_FRESH_UPGRADE_REPEAT_STARTUP_QUALIFIED')

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__); parser.add_argument('--baseline',required=True); parser.add_argument('--output',required=True); args=parser.parse_args()
    qualify(args.baseline,args.output)
