\set ON_ERROR_STOP on

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'portal_runtime') THEN
        CREATE ROLE portal_runtime LOGIN PASSWORD 'secret';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'light_knowledge_runtime') THEN
        CREATE ROLE light_knowledge_runtime LOGIN PASSWORD 'knowledge-local-secret';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'light_knowledge_admin_runtime') THEN
        CREATE ROLE light_knowledge_admin_runtime LOGIN PASSWORD 'knowledge-admin-local-secret';
    END IF;
END
$$;

REVOKE CONNECT ON DATABASE configserver FROM PUBLIC;
GRANT CONNECT ON DATABASE configserver TO portal_runtime;
\connect configserver
GRANT USAGE ON SCHEMA public TO portal_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO portal_runtime;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO portal_runtime;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO portal_runtime;

REVOKE CONNECT ON DATABASE knowledge FROM PUBLIC;
GRANT CONNECT ON DATABASE knowledge TO light_knowledge_runtime,
    light_knowledge_admin_runtime;
GRANT light_knowledge_api_role, light_knowledge_worker_role
    TO light_knowledge_runtime;
GRANT light_knowledge_admin_api_role, light_knowledge_snapshot_loader_role
    TO light_knowledge_admin_runtime;
