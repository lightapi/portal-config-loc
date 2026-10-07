#!/usr/bin/env python3
"""Read-only validation for the explicitly authorized local fresh-start path."""
import argparse
import json
import subprocess
import sys

ROLE = 'portal_loc_runtime'
QUERY = """BEGIN READ ONLY;
SELECT json_build_object(
'role_exists',EXISTS(SELECT 1 FROM pg_roles WHERE rolname='portal_loc_runtime'),
'role_safe',(SELECT NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb AND NOT rolreplication AND NOT rolbypassrls AND rolcanlogin FROM pg_roles WHERE rolname='portal_loc_runtime'),
'role_memberships_absent',NOT EXISTS(SELECT 1 FROM pg_roles WHERE rolname<>'portal_loc_runtime' AND pg_has_role('portal_loc_runtime',oid,'MEMBER')),
'connect',has_database_privilege('portal_loc_runtime',current_database(),'CONNECT'),
'schema_usage',has_schema_privilege('portal_loc_runtime','configserver','USAGE'),
'policy_reads',has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','SELECT'),
'policy_locking',has_column_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','profile_id','UPDATE'),
'policy_admission_update_forbidden',NOT has_column_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','admission_enabled','UPDATE'),
'policy_insert_forbidden',NOT has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','INSERT'),
'policy_delete_forbidden',NOT has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','DELETE'),
'policy_truncate_forbidden',NOT has_table_privilege('portal_loc_runtime','configserver.workflow_expression_profile_policy_t','TRUNCATE'),
'policy_off',(SELECT NOT admission_enabled FROM configserver.workflow_expression_profile_policy_t WHERE profile_id='cel-workflow-v2'),
'required_tables',(SELECT bool_and(has_table_privilege('portal_loc_runtime','configserver.'||name,privileges)) FROM (VALUES
('wf_definition_t','SELECT,INSERT,UPDATE,DELETE'),('wf_definition_version_t','SELECT,INSERT'),
('process_info_t','SELECT,INSERT,UPDATE,DELETE'),('task_info_t','SELECT,INSERT,UPDATE,DELETE'),
('workflow_worker_capability_t','SELECT,INSERT,UPDATE'),('workflow_command_receipt_t','SELECT,INSERT'),
('workflow_delivery_intent_t','SELECT,INSERT,UPDATE'),('workflow_sync_target_t','SELECT,INSERT,UPDATE'),
('workflow_start_request_t','SELECT,INSERT,UPDATE')) required(name,privileges)),
'required_claim_function',has_function_privilege('portal_loc_runtime','configserver.workflow_claim_host_task_v1(uuid,integer)','EXECUTE'));
ROLLBACK;"""

# Normal startup validates the policy row without prescribing its enabled state.
PRESERVED_QUERY = QUERY.replace(
    "'policy_off',(SELECT NOT admission_enabled",
    "'policy_present',(SELECT admission_enabled IS NOT NULL")

def validate(container='postgres', database='configserver', *, fixture=False, require_admission_off=True):
    if fixture:
        if not (container.startswith('e04-parserq-') and database.startswith('parserq_')):
            raise ValueError('FIXTURE_IDENTITY')
        inspected=json.loads(subprocess.check_output(['docker','inspect',container]))[0]
        if any(m.get('Name')=='all-in-lt_postgres-data' for m in inspected['Mounts']):
            raise ValueError('PROTECTED_VOLUME')
    elif (container,database)!=('postgres','configserver'):
        raise ValueError('LOCAL_IDENTITY')
    result=subprocess.run(['docker','exec','-i',container,'psql','-X','-qAt','-U','postgres','-d',database,'-v','ON_ERROR_STOP=1'],input=QUERY if require_admission_off else PRESERVED_QUERY,text=True,capture_output=True,timeout=60)
    if result.returncode:
        # PostgreSQL may include statement text. Do not print database diagnostics.
        raise ValueError('REQUIRED_OBJECT_OR_ROLE_MISSING')
    values=json.loads(result.stdout)
    failed=[name for name,value in values.items() if value is not True]
    if failed:raise ValueError('MISSING_OR_UNSAFE_ACCESS:'+','.join(failed))
    return values

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--preserve-admission', action='store_true', help='Validate existing policy without requiring admission OFF.')
    args=parser.parse_args()
    try:validate(require_admission_off=not args.preserve_admission)
    except (ValueError,OSError,subprocess.SubprocessError) as error:
        print('LOCAL_PORTAL_RUNTIME_ACCESS_REFUSED:'+str(error) if isinstance(error,ValueError) else 'LOCAL_PORTAL_RUNTIME_ACCESS_REFUSED:READBACK_FAILED',file=sys.stderr);return 2
    print('LOCAL_PORTAL_RUNTIME_READ_ONLY_ACCESS_VERIFIED');return 0

if __name__=='__main__':sys.exit(main())
