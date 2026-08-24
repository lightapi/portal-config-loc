\set ON_ERROR_STOP on

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'portal_loc_runtime') THEN
        CREATE ROLE portal_loc_runtime LOGIN PASSWORD 'secret';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'light_knowledge_loc_runtime') THEN
        CREATE ROLE light_knowledge_loc_runtime LOGIN PASSWORD 'knowledge-local-secret';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'light_knowledge_loc_admin_runtime') THEN
        CREATE ROLE light_knowledge_loc_admin_runtime LOGIN PASSWORD 'knowledge-admin-local-secret';
    END IF;
END
$$;

\connect :configserver_database
REVOKE CONNECT ON DATABASE :configserver_database FROM PUBLIC;
GRANT CONNECT ON DATABASE :configserver_database TO portal_loc_runtime;
GRANT USAGE ON SCHEMA :configserver_schema, public TO portal_loc_runtime;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA :configserver_schema TO portal_loc_runtime;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA :configserver_schema TO portal_loc_runtime;
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA :configserver_schema TO portal_loc_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE :"database_user"
    IN SCHEMA :"configserver_schema"
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO portal_loc_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE :"database_user"
    IN SCHEMA :"configserver_schema"
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO portal_loc_runtime;
ALTER DEFAULT PRIVILEGES FOR ROLE :"database_user"
    IN SCHEMA :"configserver_schema"
    GRANT EXECUTE ON ROUTINES TO portal_loc_runtime;
ALTER ROLE portal_loc_runtime IN DATABASE :configserver_database
    SET search_path = configserver, public;

\connect :knowledge_database
REVOKE CONNECT ON DATABASE :knowledge_database FROM PUBLIC;
GRANT CONNECT ON DATABASE :knowledge_database TO light_knowledge_loc_runtime,
    light_knowledge_loc_admin_runtime;
GRANT light_knowledge_api_role, light_knowledge_worker_role
    TO light_knowledge_loc_runtime;
GRANT light_knowledge_admin_api_role, light_knowledge_snapshot_loader_role
    TO light_knowledge_loc_admin_runtime;
ALTER ROLE light_knowledge_loc_runtime IN DATABASE :knowledge_database
    SET search_path = knowledge, public;
ALTER ROLE light_knowledge_loc_admin_runtime IN DATABASE :knowledge_database
    SET search_path = knowledge, public;
