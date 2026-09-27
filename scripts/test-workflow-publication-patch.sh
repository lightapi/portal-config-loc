#!/usr/bin/env bash
set -euo pipefail

# Owns its PostgreSQL container and databases; never targets a running stack.
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
patch="$repo_dir/../portal-db/postgres/migrations/patch_20260926_01_workflow_tool_binding_publication.sql"
container="workflow-phase-d-patch-$$"
password="phase-d-test"
checksum="$(sha256sum "$patch" | awk '{print $1}')"
drift_dir="$(mktemp -d "${TMPDIR:-/tmp}/workflow-phase-d-drift.XXXXXX")"
cleanup() {
    docker rm -f "$container" >/dev/null 2>&1 || true
    rm -rf -- "$drift_dir"
}
trap cleanup EXIT
docker run -d --name "$container" -e "POSTGRES_PASSWORD=$password" postgres:17 >/dev/null
for attempt in {1..40}; do
    if docker exec "$container" pg_isready -U postgres -d postgres >/dev/null 2>&1; then break; fi
    sleep 0.25
done
psql_owned() {
    docker exec -i -e "PGPASSWORD=$password" "$container" \
        psql -X -v ON_ERROR_STOP=1 -h localhost -U postgres -d "$1" "${@:2}"
}
shadow_checksum() {
    docker exec -e "PGPASSWORD=$password" "$container" \
        pg_dump -h localhost -U postgres -d "$1" --schema-only --schema=shadow |
        sed '/^\\restrict /d; /^\\unrestrict /d' | sha256sum | awk '{print $1}'
}
psql_owned postgres <<'SQL'
CREATE DATABASE phase_d_public;
CREATE DATABASE phase_d_alternate;
SQL
for mode in public alternate; do
    database="phase_d_$mode"
    if [[ "$mode" == public ]]; then target=public; else target=configserver_phase_d; fi
    psql_owned "$database" -v target="$target" <<'SQL'
CREATE SCHEMA shadow;
SELECT format('CREATE SCHEMA IF NOT EXISTS %I', :'target') \gexec
SELECT format('CREATE TABLE %I.workflow_tool_binding_t (host_id uuid, binding_id uuid, cancellation_policy varchar(24))', :'target') \gexec
SELECT format('CREATE TABLE %I.gateway_tool_binding_t (host_id uuid, binding_id uuid)', :'target') \gexec
SELECT format('CREATE TABLE %I.scheduler_lock_t (lock_id integer PRIMARY KEY, instance_id text, last_heartbeat timestamptz)', :'target') \gexec
CREATE TABLE shadow.workflow_tool_binding_t (host_id uuid, binding_id uuid);
CREATE TABLE shadow.gateway_tool_binding_t (host_id uuid, binding_id uuid);
CREATE TABLE shadow.scheduler_lock_t (lock_id integer PRIMARY KEY, instance_id text, last_heartbeat timestamptz);
SQL
    psql_owned postgres -v database="$database" <<'SQL'
SELECT format('ALTER ROLE postgres IN DATABASE %I SET search_path = shadow, public', :'database') \gexec
SQL
    [[ "$(psql_owned "$database" -tAc 'SHOW search_path' | tr -d ' ')" == 'shadow,public' ]]
    shadow_before="$(shadow_checksum "$database")"
    output="$(CONTAINER_CMD=docker PORTAL_DB_CONTAINER="$container" PORTAL_DB_NAME="$database" \
        PORTAL_DB_PASSWORD="$password" "$repo_dir/scripts/apply-db-patches.sh" "$target" "$patch")"
    [[ "$output" == *"Applying database patch:"* ]]
    psql_owned "$database" -v target="$target" -v checksum="$checksum" <<'SQL'
SELECT set_config('phase_d.target', :'target', false);
DO $verify$
DECLARE schema_name text := current_setting('phase_d.target');
BEGIN
    IF (SELECT count(*) FROM pg_constraint c JOIN pg_class t ON t.oid=c.conrelid
        JOIN pg_namespace n ON n.oid=t.relnamespace
        WHERE n.nspname=schema_name AND c.conname LIKE 'workflow_tool_binding_t_%_check') < 8 THEN
        RAISE EXCEPTION 'publication constraints missing in %', schema_name;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
        JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname=schema_name AND c.relname='workflow_operation_t'
          AND t.tgname='workflow_operation_guard_trg' AND NOT t.tgisinternal) THEN
        RAISE EXCEPTION 'operation guard missing in %', schema_name;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='shadow'
        AND table_name='workflow_tool_binding_t' AND column_name='publication_status')
       OR EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace
           WHERE n.nspname='shadow' AND c.conname LIKE 'workflow_tool_binding_t_%_check')
       OR to_regclass('shadow.workflow_operation_t') IS NOT NULL
       OR to_regclass('shadow.portal_schema_patch_t') IS NOT NULL THEN
        RAISE EXCEPTION 'shadow schema changed';
    END IF;
END $verify$;
SELECT format('INSERT INTO %I.workflow_operation_t (host_id,operation_id,tool_name,subject_id,request,request_digest,requested_by,expires_ts) VALUES (gen_random_uuid(),gen_random_uuid(),''test'',gen_random_uuid(),''{}''::jsonb,''sha256:'' || repeat(''a'',64),''tester'',now())', :'target') \gexec
DO $guard$
DECLARE schema_name text := current_setting('phase_d.target');
        guard_expiry boolean;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname=schema_name AND c.relname='workflow_operation_t') THEN
        RAISE EXCEPTION 'operation table absent';
    END IF;
    EXECUTE format('SELECT bool_and(expires_ts = create_ts + interval ''29 days'') FROM %I.workflow_operation_t', schema_name)
        INTO STRICT guard_expiry;
    IF guard_expiry IS DISTINCT FROM TRUE THEN RAISE EXCEPTION 'guard did not set 29-day expiry'; END IF;
    BEGIN
        EXECUTE format('UPDATE %I.workflow_operation_t SET requested_by = ''another''', schema_name);
        RAISE EXCEPTION 'operation guard accepted immutable change';
    EXCEPTION WHEN check_violation THEN
        NULL;
    END;
END $guard$;
SELECT format('SELECT checksum FROM %I.portal_schema_patch_t WHERE patch_id=''patch_20260926_01_workflow_tool_binding_publication''', :'target') \gexec
SQL
    ledger_before="$(psql_owned "$database" -tAc "SELECT checksum || ':' || applied_ts FROM $target.portal_schema_patch_t")"
    [[ "$ledger_before" == "$checksum:"* ]]
    output="$(CONTAINER_CMD=docker PORTAL_DB_CONTAINER="$container" PORTAL_DB_NAME="$database" \
        PORTAL_DB_PASSWORD="$password" "$repo_dir/scripts/apply-db-patches.sh" "$target" "$patch")"
    [[ "$output" == *"already applied:"* ]]
    ledger_after="$(psql_owned "$database" -tAc "SELECT checksum || ':' || applied_ts FROM $target.portal_schema_patch_t")"
    [[ "$ledger_before" == "$ledger_after" ]]
    [[ "$(psql_owned "$database" -tAc "SELECT count(*) FROM $target.portal_schema_patch_t")" == 1 ]]
    [[ "$(shadow_checksum "$database")" == "$shadow_before" ]]
    drift_patch="$drift_dir/$(basename -- "$patch")"
    cp "$patch" "$drift_patch"
    printf '\n-- deliberate checksum drift for regression\n' >> "$drift_patch"
    if CONTAINER_CMD=docker PORTAL_DB_CONTAINER="$container" PORTAL_DB_NAME="$database" \
        PORTAL_DB_PASSWORD="$password" "$repo_dir/scripts/apply-db-patches.sh" "$target" "$drift_patch" \
        >"$drift_dir/drift.log" 2>&1; then
        echo "checksum drift was accepted in $mode path" >&2; exit 1
    fi
    grep -q 'checksum drift' "$drift_dir/drift.log"
    [[ "$(psql_owned "$database" -tAc "SELECT checksum || ':' || applied_ts FROM $target.portal_schema_patch_t")" == "$ledger_before" ]]
    [[ "$(shadow_checksum "$database")" == "$shadow_before" ]]
    echo "$mode path: constraints, guard, shadow isolation, checksum and reapply passed"
done
