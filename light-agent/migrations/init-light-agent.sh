#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d configserver \
    -f /migrations/patch_20260819_01_light_agent_policy_snapshot_pointer.sql

if [ "${LIGHT_AGENT_SEED_LOCAL_POLICY:-false}" = "true" ]; then
    : "${LIGHT_AGENT_HOST_ID:?LIGHT_AGENT_HOST_ID is required for local policy seeding}"
    : "${LIGHT_AGENT_AGENT_DEF_ID:?LIGHT_AGENT_AGENT_DEF_ID is required for local policy seeding}"
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d configserver \
        -v host_id="$LIGHT_AGENT_HOST_ID" \
        -v agent_def_id="$LIGHT_AGENT_AGENT_DEF_ID" \
        -f /migrations/seed-local-policy.sql
fi
