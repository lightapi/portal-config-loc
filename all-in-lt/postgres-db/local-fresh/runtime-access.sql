-- Read-only validation for the explicit local-fresh Compose one-shot.
-- Keep validate-environment.sh ahead of this file. Never repair roles or ACLs.
\set ON_ERROR_STOP on
\connect :configserver_database
BEGIN READ ONLY;
SET LOCAL search_path = :"configserver_schema", public;
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='portal_loc_runtime'
        AND rolcanlogin AND NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb
        AND NOT rolreplication AND NOT rolbypassrls)
       OR EXISTS (SELECT FROM pg_roles WHERE rolname<>'portal_loc_runtime'
           AND pg_has_role('portal_loc_runtime',oid,'MEMBER')) THEN
        RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: unsafe or missing Portal runtime role';
    END IF;
    IF NOT has_database_privilege('portal_loc_runtime',current_database(),'CONNECT')
       OR NOT has_schema_privilege('portal_loc_runtime',current_schema(),'USAGE') THEN
        RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: missing Portal database/schema access';
    END IF;
    IF NOT has_table_privilege('portal_loc_runtime','workflow_expression_profile_policy_t','SELECT')
       OR NOT has_column_privilege('portal_loc_runtime','workflow_expression_profile_policy_t','profile_id','UPDATE')
       OR has_column_privilege('portal_loc_runtime','workflow_expression_profile_policy_t','admission_enabled','UPDATE')
       OR has_table_privilege('portal_loc_runtime','workflow_expression_profile_policy_t','INSERT,DELETE,TRUNCATE')
       OR (SELECT admission_enabled FROM workflow_expression_profile_policy_t WHERE profile_id='cel-workflow-v2') IS DISTINCT FROM false THEN
        RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: unsafe policy ACL or missing/OFF policy';
    END IF;
    IF EXISTS (SELECT FROM (VALUES
        ('wf_definition_t','SELECT,INSERT,UPDATE,DELETE'),
        ('wf_definition_version_t','SELECT,INSERT'),
        ('process_info_t','SELECT,INSERT,UPDATE,DELETE'),
        ('task_info_t','SELECT,INSERT,UPDATE,DELETE'),
        ('workflow_worker_capability_t','SELECT,INSERT,UPDATE'),
        ('workflow_command_receipt_t','SELECT,INSERT'),
        ('workflow_delivery_intent_t','SELECT,INSERT,UPDATE'),
        ('workflow_sync_target_t','SELECT,INSERT,UPDATE'),
        ('workflow_start_request_t','SELECT,INSERT,UPDATE')) required(name,privileges)
        WHERE NOT has_table_privilege('portal_loc_runtime',name,privileges))
       OR NOT has_function_privilege('portal_loc_runtime','workflow_claim_host_task_v1(uuid,integer)','EXECUTE') THEN
        RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: missing required Portal table/function access';
    END IF;
END $$;
ROLLBACK;
\connect :knowledge_database
BEGIN READ ONLY;
SET LOCAL search_path = :"knowledge_schema", public;
DO $$
DECLARE pair record;
BEGIN
    FOR pair IN SELECT * FROM (VALUES
        ('light_knowledge_loc_runtime','light_knowledge_api_role'),
        ('light_knowledge_loc_runtime','light_knowledge_worker_role'),
        ('light_knowledge_loc_admin_runtime','light_knowledge_admin_api_role'),
        ('light_knowledge_loc_admin_runtime','light_knowledge_snapshot_loader_role')) memberships(runtime,required_role)
    LOOP
        IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname=pair.runtime AND rolcanlogin
            AND NOT rolsuper AND NOT rolcreaterole AND NOT rolcreatedb
            AND NOT rolreplication AND NOT rolbypassrls)
           OR NOT pg_has_role(pair.runtime,pair.required_role,'USAGE')
           OR NOT has_database_privilege(pair.runtime,current_database(),'CONNECT')
           OR NOT has_schema_privilege(pair.runtime,current_schema(),'USAGE') THEN
            RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: missing or unsafe knowledge access for % via %',pair.runtime,pair.required_role;
        END IF;
    END LOOP;
    IF NOT has_table_privilege('light_knowledge_loc_runtime','knowledge_job_t','SELECT')
       OR NOT has_table_privilege('light_knowledge_loc_admin_runtime','knowledge_control_snapshot_t','SELECT')
       OR NOT has_table_privilege('light_knowledge_loc_runtime','knowledge_embedding_profile_runtime_v','SELECT') THEN
        RAISE EXCEPTION 'LOCAL_FRESH_RUNTIME_ACCESS: missing required knowledge reads';
    END IF;
END $$;
ROLLBACK;
\echo LOCAL_FRESH_ONESHOT_READ_ONLY_ACCESS_VERIFIED
