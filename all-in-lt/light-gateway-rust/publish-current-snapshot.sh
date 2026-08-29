#!/usr/bin/env bash
set -euo pipefail

gateway_instance_id="${PORTAL_GATEWAY_CONFIG_INSTANCE_ID:-26ecfd54-5239-5d87-a82a-e335b2a2da22}"
snapshot_user_id="${PORTAL_GATEWAY_SNAPSHOT_USER_ID:-01964b05-5532-7c79-8cde-191dcbd421b8}"
snapshot_description="${PORTAL_GATEWAY_SNAPSHOT_DESCRIPTION:-Portal gateway local configuration refresh}"
snapshot_dry_run="${PORTAL_GATEWAY_SNAPSHOT_DRY_RUN:-false}"

docker exec -i postgres psql -U postgres -d configserver -v ON_ERROR_STOP=1 \
  -v instance_id="${gateway_instance_id}" \
  -v user_id="${snapshot_user_id}" \
  -v description="${snapshot_description}" \
  -v dry_run="${snapshot_dry_run}" <<'SQL'
BEGIN;
SELECT set_config('portal_gateway.instance_id', :'instance_id', false);
SELECT set_config('portal_gateway.user_id', :'user_id', false);
SELECT set_config('portal_gateway.description', :'description', false);
DO $$
DECLARE
    target_instance uuid := current_setting('portal_gateway.instance_id')::uuid;
    actor uuid := current_setting('portal_gateway.user_id')::uuid;
    next_snapshot uuid := gen_random_uuid();
    target_host uuid;
    previous_snapshot uuid;
BEGIN
    SELECT host_id INTO STRICT target_host
    FROM instance_t
    WHERE instance_id = target_instance
      AND active = true
      AND service_id = 'com.networknt.portal.gateway-1.0.0'
      AND env_tag = 'loc';

    SELECT snapshot_id INTO previous_snapshot
    FROM config_snapshot_t
    WHERE host_id = target_host
      AND instance_id = target_instance
      AND current = true;

    CALL create_snapshot(
        target_host,
        target_instance,
        'USER_SAVE',
        current_setting('portal_gateway.description'),
        actor,
        NULL::uuid,
        next_snapshot
    );

    UPDATE config_snapshot_t
       SET current = false
     WHERE host_id = target_host
       AND instance_id = target_instance
       AND snapshot_id <> next_snapshot;

    UPDATE config_snapshot_t
       SET current = true
     WHERE snapshot_id = next_snapshot;

    RAISE NOTICE 'Promoted portal gateway snapshot % for instance %; previous snapshot %',
        next_snapshot, target_instance, COALESCE(previous_snapshot::text, 'none');
END $$;
\if :dry_run
ROLLBACK;
\else
COMMIT;
\endif
SQL
