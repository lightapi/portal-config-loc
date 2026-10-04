#!/usr/bin/env python3
"""Owner-approved local E04 companion. No normal W7/production integration.

Clearance is input evidence, never a qualification reference. A live invocation
always holds the source-table locks on the same psql connection through commit.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
PATCH_ID = 'patch_20261003_01_local_parser_workflow_expression_profile'
OLD_ID = 'patch_20261002_01_workflow_expression_profile'
DELIVERY_ID = 'patch_20261002_02_workflow_delivery_ledger'
PATCH = ROOT / 'all-in-lt/postgres-db/local-fresh' / (PATCH_ID + '.sql')

class Refusal(Exception):
    pass

def require(value, code):
    if not value:
        raise Refusal(code)

def digest(path):
    path = Path(path)
    if path.is_file():
        return hashlib.sha256(path.read_bytes()).hexdigest()
    require(path.is_dir(), 'PARSER_ASSET_MISSING')
    inventory = [(str(f.relative_to(path)), digest(f)) for f in sorted(path.rglob('*')) if f.is_file()]
    return hashlib.sha256(json.dumps(inventory, separators=(',', ':')).encode()).hexdigest()

def records(data):
    out = []
    for group in ('heads', 'versions', 'process_snapshots'):
        for row in data[group]:
            source = row['definition_snapshot'] if group == 'process_snapshots' else row['definition']
            require(isinstance(source, str), 'SOURCE_NOT_TEXT')
            out.append(dict(group=group, identity={k:v for k,v in row.items() if k not in ('definition','definition_snapshot')},
                            source=source, source_sha256=hashlib.sha256(source.encode()).hexdigest(),
                            format='jsonb' if group == 'process_snapshots' else 'yaml'))
    return out

def inventory(rows):
    return [{k:v for k,v in r.items() if k != 'source'} for r in rows]

EXPORT = """SELECT json_build_object(
'database',current_database(), 'database_oid',(SELECT oid FROM pg_database WHERE datname=current_database()),
'heads',(SELECT coalesce(json_agg(x ORDER BY host_id,wf_def_id),'[]') FROM (SELECT host_id,wf_def_id,namespace,name,version,aggregate_version,active,definition FROM configserver.wf_definition_t) x),
'versions',(SELECT coalesce(json_agg(x ORDER BY host_id,wf_def_id,version),'[]') FROM (SELECT host_id,wf_def_id,namespace,name,version,aggregate_version,active,definition FROM configserver.wf_definition_version_t) x),
'process_snapshots',(SELECT coalesce(json_agg(x ORDER BY host_id,process_id),'[]') FROM (SELECT host_id,process_id,wf_def_id,status_code,definition_snapshot::text AS definition_snapshot FROM configserver.process_info_t WHERE definition_snapshot IS NOT NULL) x),
'null_process_snapshots',(SELECT count(*) FROM configserver.process_info_t WHERE definition_snapshot IS NULL),
'definition_snapshot_columns',(SELECT coalesce(json_agg(x),'[]') FROM (SELECT table_schema,table_name,column_name,data_type FROM information_schema.columns WHERE table_schema IN ('configserver','public') AND column_name='definition_snapshot' ORDER BY table_schema,table_name) x));"""

CATALOG = """SELECT json_build_object(
'tables',(SELECT json_agg(x ORDER BY name) FROM (SELECT relname name,pg_get_userbyid(relowner) owner,ARRAY(SELECT a::text FROM unnest(relacl) a ORDER BY a::text) acl FROM pg_class WHERE relnamespace='configserver'::regnamespace AND relname IN ('workflow_expression_profile_policy_t','workflow_worker_capability_t','process_expression_profile_claim_idx')) x),
'policy_columns',(SELECT json_agg(x ORDER BY name) FROM (SELECT attname name,format_type(atttypid,atttypmod) type,attnotnull not_null,ARRAY(SELECT a::text FROM unnest(attacl) a ORDER BY a::text) acl FROM pg_attribute WHERE attrelid=to_regclass('configserver.workflow_expression_profile_policy_t') AND attnum>0 AND NOT attisdropped) x),
'columns',(SELECT json_agg(x ORDER BY name) FROM (SELECT attname name,format_type(atttypid,atttypmod) type,attnotnull not_null,pg_get_expr(adbin,adrelid) default_expr FROM pg_attribute LEFT JOIN pg_attrdef ON adrelid=attrelid AND adnum=attnum WHERE attrelid='configserver.process_info_t'::regclass AND attname='expression_profile') x),
'constraints',(SELECT json_agg(x ORDER BY name) FROM (SELECT conname name,convalidated validated,pg_get_constraintdef(oid) definition FROM pg_constraint WHERE conrelid IN (to_regclass('configserver.workflow_expression_profile_policy_t'),to_regclass('configserver.workflow_worker_capability_t')) OR (conrelid='configserver.process_info_t'::regclass AND conname='process_expression_profile_snapshot_ck')) x),
'functions',(SELECT json_agg(x ORDER BY name) FROM (SELECT proname name,pg_get_function_identity_arguments(oid) args,pg_get_userbyid(proowner) owner,prosecdef security_definer,proacl::text acl,pg_get_functiondef(oid) definition FROM pg_proc WHERE pronamespace='configserver'::regnamespace AND proname IN ('workflow_claim_host_task_v1','workflow_claim_host_task_v2')) x),
'indexes',(SELECT json_agg(x ORDER BY indexname) FROM (SELECT indexname,indexdef FROM pg_indexes WHERE schemaname='configserver' AND (tablename IN ('workflow_expression_profile_policy_t','workflow_worker_capability_t') OR indexname='process_expression_profile_claim_idx')) x));"""

class Session:
    def __init__(self, container, database, log):
        self.error = open(log, 'a')
        self.process = subprocess.Popen(['docker','exec','-i',container,'psql','-X','-qAt','-U','postgres','-d',database,'-v','ON_ERROR_STOP=1'],
                                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.error, text=True, bufsize=1)
    def sql(self, text):
        marker = 'E04_END_' + uuid.uuid4().hex
        try:
            self.process.stdin.write(text + '\n\\echo ' + marker + '\n')
            self.process.stdin.flush()
        except (BrokenPipeError,OSError):
            raise Refusal('SQL_FAILED') from None
        output=[]
        # psql output is never printed; error log remains private.
        deadline=time.monotonic()+120
        while True:
            require(time.monotonic()<deadline, 'SQL_TIMEOUT')
            line=self.process.stdout.readline()
            require(line != '', 'SQL_FAILED')
            if line.strip()==marker:
                return '\n'.join(output).strip()
            output.append(line.rstrip('\n'))
    def close(self):
        if self.process.poll() is None:
            try:
                self.process.stdin.write('ROLLBACK;\n\\q\n'); self.process.stdin.flush()
            except (BrokenPipeError,OSError):
                pass
            self.process.stdin.close()
            try:self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:self.process.kill();self.process.wait()
        self.error.close()

def parse_locked(rows, clearance, directory):
    for path, sha in clearance['parser_assets'].items():
        require(digest(path)==sha, 'PARSER_IDENTITY_CHANGED')
    source=directory/'locked-input.private.json'; source.write_text(json.dumps(rows))
    java=directory/'locked-java.private.json'; rust=directory/'locked-rust.private.json'
    with (directory/'parser.log').open('a') as log:
        for argv in ([clearance['java'], '-cp', clearance['java_classpath'], 'ParserAudit', str(source), str(java)],
                     [clearance['rust_binary'], str(source), str(rust)]):
            result=subprocess.run(argv,stdout=log,stderr=log,timeout=120)
            require(result.returncode==0, 'PARSER_EXECUTION_FAILED')
    a=json.loads(java.read_text());b=json.loads(rust.read_text())
    require(len(a)==len(b)==len(rows), 'PARSER_CARDINALITY')
    for raw,x,y in zip(rows,a,b):
        require(all(z['source_sha256']==raw['source_sha256'] and z['identity']==raw['identity'] and z['group']==raw['group'] for z in (x,y)), 'PARSER_RECORD_IDENTITY')
        require(x['parse']==y['parse']==y['strict_parse']=='PASS', 'PARSE_OR_DUPLICATE_AMBIGUITY')
        require(x.get('decoded')==y.get('decoded'), 'PARSER_INTERPRETATION_DIFFERENCE')
        require(not x['reserved'] and not y['reserved'] and 'profile_error' not in x, 'RESERVED_OR_PROFILE_AMBIGUITY')
    for path,sha in clearance['parser_assets'].items():
        require(digest(path)==sha,'PARSER_IDENTITY_CHANGED')

def apply(clearance, directory, container='postgres', database='configserver', *, fixture=False, boundary=None):
    """fixture is only used by the isolated regression harness, never the CLI."""
    directory=Path(directory); directory.mkdir(mode=0o700,parents=True,exist_ok=False)
    os.chmod(directory,0o700)
    if fixture:
        require(container.startswith('e04-parserq-') and database.startswith('parserq_'), 'FIXTURE_IDENTITY')
        inspected=json.loads(subprocess.check_output(['docker','inspect',container]))[0]
        require(all(m.get('Name')!='all-in-lt_postgres-data' for m in inspected['Mounts']), 'PROTECTED_VOLUME')
    else:
        require(container=='postgres' and database=='configserver', 'LOCAL_IDENTITY')
        ctx=json.loads(subprocess.check_output(['docker','context','inspect']))[0]
        require(ctx['Endpoints']['docker']['Host']=='unix:///var/run/docker.sock','LOCAL_SOCKET')
        inspected=json.loads(subprocess.check_output(['docker','inspect','postgres']))[0]
        require(inspected['Config']['Labels']['com.docker.compose.project']=='all-in-lt','LOCAL_PROJECT')
        require(any(m.get('Name')=='all-in-lt_postgres-data' and m['Destination']=='/var/lib/postgresql/data' for m in inspected['Mounts']),'LOCAL_VOLUME')
        backup=Path(clearance['backup']['path'])
        require(not backup.is_symlink() and digest(backup)==clearance['backup']['sha256'],'BACKUP_HASH')
        with backup.open('rb') as stream, (directory/'backup-readability.log').open('w') as log:
            require(subprocess.run(['docker','exec','-i','postgres','pg_restore','--file=/dev/null'],stdin=stream,stdout=log,stderr=log).returncode==0,'BACKUP_UNREADABLE')
    require(digest(PATCH)==clearance['companion_sha256'],'COMPANION_IDENTITY')
    for path,sha in clearance['source_assets'].items():require(digest(path)==sha,'SOURCE_IDENTITY_CHANGED')
    session=Session(container,database,directory/'sql-errors.private.log')
    try:
        session.sql("BEGIN ISOLATION LEVEL REPEATABLE READ; SET LOCAL lock_timeout='5s'; SET LOCAL statement_timeout='120s'; LOCK TABLE configserver.wf_definition_t, configserver.wf_definition_version_t, configserver.process_info_t, configserver.portal_schema_patch_t IN SHARE MODE;")
        data=json.loads(session.sql(EXPORT))
        require(str(data['database_oid'])==str(clearance['database_oid']) and data['database']==database,'DATABASE_IDENTITY_CHANGED')
        rows=records(data)
        require(inventory(rows)==clearance['inventory'] and data['null_process_snapshots']==clearance['null_process_snapshots'] and data['definition_snapshot_columns']==clearance['definition_snapshot_columns'],'REVIEWED_RECORDS_CHANGED')
        parse_locked(rows,clearance,directory)
        (directory/'locked-inventory.json').write_text(json.dumps(inventory(rows),indent=2))
        if boundary:boundary('locked',session)
        ledger=json.loads(session.sql("SELECT coalesce(json_object_agg(patch_id,checksum),'{}') FROM configserver.portal_schema_patch_t;"))
        expected=dict(clearance['baseline_ledger'])
        require(OLD_ID not in ledger,'ORIGINAL_PATCH_UNEXPECTED')
        repeated=PATCH_ID in ledger
        if repeated:
            expected[PATCH_ID]=clearance['companion_sha256']
            if DELIVERY_ID in ledger:expected[DELIVERY_ID]=clearance['delivery_sha256']
        require(ledger==expected,'UNEXPECTED_LEDGER_STATE')
        if repeated:
            catalog=json.loads(session.sql(CATALOG))
            (directory/'postinstall-catalog.private.json').write_text(json.dumps(catalog,indent=2))
            require(catalog==clearance['expected_catalog'],'POSTINSTALL_CATALOG_DRIFT')
        else:
            require(session.sql("SELECT to_regclass('configserver.workflow_expression_profile_policy_t') IS NULL AND to_regclass('configserver.workflow_worker_capability_t') IS NULL AND NOT EXISTS(SELECT 1 FROM pg_attribute WHERE attrelid='configserver.process_info_t'::regclass AND attname='expression_profile' AND NOT attisdropped);")=='t','UNEXPECTED_PREINSTALL_SCHEMA')
            # The companion refuses unmediated execution: its transaction-local
            # clearance is created only after the locked readback above.
            certificate=hashlib.sha256(json.dumps(inventory(rows),sort_keys=True).encode()).hexdigest()
            session.sql("CREATE TEMP TABLE e04_parser_clearance(contract text, inventory_sha256 text, backend_pid integer) ON COMMIT DROP; INSERT INTO e04_parser_clearance VALUES('e04-local-parser-v1','"+certificate+"',pg_backend_pid());")
            body='\n'.join(line for line in PATCH.read_text().splitlines() if line not in ('BEGIN;','COMMIT;'))
            # Use the same reviewed renderer as apply-db-patches, never a text
            # substitution of source schemas inside arbitrary definition data.
            rendered=directory/'companion-rendered.sql'
            env=os.environ.copy();env.update(PORTAL_DB_CONFIGSERVER_SOURCE=str(PATCH),PORTAL_DB_STRIP_TOP_LEVEL_TRANSACTIONS='true')
            result=subprocess.run([str(ROOT/'all-in-lt/postgres-db/lib/render-schema.sh'),'configserver','configserver',str(rendered)],env=env,capture_output=True)
            require(result.returncode==0,'RENDER_FAILED')
            session.sql(rendered.read_text())
            if boundary:boundary('after_ddl',session)
            catalog=json.loads(session.sql(CATALOG))
            (directory/'postinstall-catalog.private.json').write_text(json.dumps(catalog,indent=2))
            require(catalog==clearance['expected_catalog'],'POSTINSTALL_CATALOG_MISMATCH')
            session.sql("INSERT INTO configserver.portal_schema_patch_t(patch_id,checksum) VALUES('"+PATCH_ID+"','"+clearance['companion_sha256']+"');")
        require(session.sql("SELECT admission_enabled=false FROM configserver.workflow_expression_profile_policy_t WHERE profile_id='cel-workflow-v2';")=='t','ADMISSION_NOT_OFF')
        require(session.sql("SELECT has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','SELECT') AND has_column_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','profile_id','UPDATE') AND NOT has_column_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','admission_enabled','UPDATE') AND NOT has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','INSERT,DELETE,TRUNCATE') AND NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname<>'portal_loc_runtime' AND pg_has_role('portal_loc_runtime',oid,'MEMBER'));")=='t','RUNTIME_POLICY_AUTHORITY_UNSAFE')
        after=json.loads(session.sql(EXPORT))
        require(inventory(records(after))==clearance['inventory'] and after['null_process_snapshots']==clearance['null_process_snapshots'],'RECORD_PRESERVATION_FAILED')
        if boundary:boundary('before_commit',session)
        session.sql('COMMIT;')
        if boundary:boundary('after_commit',session)
        (directory/'result.json').write_text(json.dumps(dict(result='PASS',retry=repeated,admission='OFF',companion=PATCH_ID,checksum=clearance['companion_sha256'],supersedes_guard_of=OLD_ID,original_recorded=False,records=len(rows)),indent=2))
        return repeated
    finally:session.close()

def main():
    os.umask(0o077)
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--clearance',required=True);parser.add_argument('--clearance-sha256',required=True);parser.add_argument('--evidence',required=True)
    args=parser.parse_args()
    try:
        require(digest(args.clearance)==args.clearance_sha256,'CLEARANCE_IDENTITY_CHANGED')
        apply(json.loads(Path(args.clearance).read_text()),args.evidence)
    except (Refusal,OSError,ValueError,KeyError,subprocess.SubprocessError) as error:
        print('LOCAL_PARSER_COMPANION_REFUSED: '+(str(error) if isinstance(error,Refusal) else type(error).__name__),file=sys.stderr);return 2
    print('LOCAL_PARSER_COMPANION_COMMITTED_ADMISSION_OFF');return 0

if __name__=='__main__':sys.exit(main())
