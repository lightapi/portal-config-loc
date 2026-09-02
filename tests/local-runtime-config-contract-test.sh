#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="$repo_root/all-in-lt/docker-compose.yml"
deploy_script="$repo_root/scripts/deploy-local.sh"
bootstrap_script="$repo_root/all-in-lt/postgres-db/operations/bin/bootstrap-operational-databases.sh"
hybrid_command_values="$repo_root/all-in-lt/hybrid-command/config/values.yml"
hybrid_query_values="$repo_root/all-in-lt/hybrid-query/node1/values.yml"
agent_template="$repo_root/all-in-lt/light-agent-rust/config/agent.yml"
agent_values="$repo_root/all-in-lt/light-agent-rust/config/values.yml"
registration_patch="$repo_root/all-in-lt/postgres-db/patches/20260902_01_operational_store_registration.sql"

if grep -q './postgres-db/secrets/operational-database-url' "$compose_file"; then
  echo "local Compose must not mount a host operational database URL secret" >&2
  exit 1
fi
if grep -q 'prepare_operational_database_secret' "$deploy_script"; then
  echo "local deployment must not generate or chown operational database secrets" >&2
  exit 1
fi

grep -q 'OPERATIONAL_DATABASE_URL:' "$compose_file"
grep -q 'GATEWAY_DATABASE_URL:' "$compose_file"
grep -q 'host_dir="/source/operational-hosts/\$${OPERATIONAL_RUNTIME_HOST:-dev.lightapi.net}"' "$compose_file"
grep -q 'GATEWAYEVIDENCE_DATABASEURLFILE: /run/secrets/operational-database-url' "$compose_file"
grep -q 'OPERATIONALSTORE_DATABASEURLFILE: /run/secrets/operational-database-url' "$compose_file"
grep -q 'AGENT_OPERATIONALSTORE_DATABASEURLFILE: /run/secrets/operational-database-url' "$compose_file"
if grep -Eq 'LIGHT_(AGENT_OPERATIONAL|WORKFLOW|GATEWAY_EVIDENCE|A2A)_DATABASE_URL:' "$compose_file"; then
  echo "runtime services must not receive inline operational database URLs" >&2
  exit 1
fi
grep -q 'AGENT_A2APOLICY_AUTHORIZATIONCONTEXTKEYFILE: /tmp/a2a-authorized-context-key' "$compose_file"
grep -q 'AGENT_A2AOUTBOUND_AUTHORIZATIONCONTEXTKEYFILE: /tmp/a2a-authorized-context-key' "$compose_file"
if grep -q 'AGENTPOLICY_AGENTDEFID:' "$compose_file"; then
  echo "Agent definition identity must come from the immutable Agent snapshot" >&2
  exit 1
fi
grep -q '\${agent.runtimePolicy.publicationId:}' "$agent_template"
grep -q '\${agent.portalAssociation.runtimeInstanceId:}' "$agent_template"
grep -q '\${agent.agentPolicy.agentDefId:}' "$agent_template"
if grep -Eq '\$\{(runtimePolicy|portalAssociation|agentPolicy)\.' "$agent_template"; then
  echo "Agent template contains a Config Server value without the agent namespace" >&2
  exit 1
fi
grep -q '\${LIGHT_AGENT_ADVISOR_PORT:-8084}:8084' "$compose_file"
grep -q 'curl -f http://localhost:8084/health' "$compose_file"
grep -q '\${LIGHT_AGENT_TECH_SUPPORT_PORT:-8088}:8082' "$compose_file"
grep -q 'curl -f http://localhost:8082/health' "$compose_file"
grep -q '^prepare_database_urls()' "$bootstrap_script"
grep -q 'required_agent_policy_property_count="33"' "$deploy_script"
grep -q "runtimePolicy.publicationId" "$deploy_script"
grep -q "portalAssociation.runtimeInstanceId" "$deploy_script"
grep -q "agentPolicy.policySnapshot.dataBoundaryDigest" "$deploy_script"
grep -q '3 runnable Agent snapshots' "$deploy_script"
grep -q "operationalStore.contractVersion.*='2'" "$deploy_script"
grep -q "operationalStore.environment.*=s.env_tag" "$deploy_script"
grep -q '^ensure_portal_runtime_database_access()' "$deploy_script"
grep -q 'exec -i -e PGPASSWORD=' "$deploy_script"
grep -q 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA configserver TO portal_loc_runtime' "$deploy_script"
grep -q 'ensure_portal_runtime_database_access || return 1' "$deploy_script"
grep -q 'default_registration_patch=' "$deploy_script"
grep -Fq '"$SCRIPT_DIR/import-event-deltas.sh" || return 1' "$deploy_script"
grep -Fq 'load_env_file_var EVENT_IMPORTER_IMAGE' "$deploy_script"
grep -Fq 'EVENT_IMPORTER_IMAGE="${EVENT_IMPORTER_IMAGE:-}"' "$deploy_script"
grep -Fq 'RELEASE_IMAGE_ENV_FILE="$RELEASE_IMAGE_ENV_FILE"' "$deploy_script"
grep -Fq 'release_image_env_file="${RELEASE_IMAGE_ENV_FILE:-}"' "$repo_root/scripts/import-event-deltas.sh"
grep -Fq '$repo_dir/../.release-state/docker-images.env' "$repo_root/scripts/import-event-deltas.sh"
grep -Fq 'refusing to import deltas with an unversioned fallback' "$repo_root/scripts/import-event-deltas.sh"
grep -Fq 'payload_base64 TEXT NOT NULL' "$repo_root/scripts/import-event-deltas.sh"
if grep -Fq -- '-v "expected_json=$expected_json"' "$repo_root/scripts/import-event-deltas.sh"; then
  echo "event delta verification must stream large JSON instead of passing it through argv" >&2
  exit 1
fi
grep -Fq '"$SCRIPT_DIR/refresh-config-snapshots.sh" || return 1' "$deploy_script"
grep -Fq 'CALL create_snapshot(' "$repo_root/scripts/refresh-config-snapshots.sh"
delta_import_line="$(grep -nF '"$SCRIPT_DIR/import-event-deltas.sh" || return 1' "$deploy_script" | cut -d: -f1)"
snapshot_refresh_line="$(grep -nF '"$SCRIPT_DIR/refresh-config-snapshots.sh" || return 1' "$deploy_script" | cut -d: -f1)"
[[ "$delta_import_line" -lt "$snapshot_refresh_line" ]]
[[ "$(grep -Fc '[[ -n "${IMPORT_EVENTS+x}" ]] || IMPORT_EVENTS=auto' "$deploy_script")" -eq 2 ]]
grep -q 'ADD COLUMN IF NOT EXISTS contract_version bigint' "$registration_patch"
if grep -q '^operationalStore\.' "$agent_values"; then
  echo "Agent bootstrap values contain dead unprefixed operationalStore keys" >&2
  exit 1
fi
grep -q '^db-provider.username: postgres$' "$hybrid_command_values"
grep -q '^db-provider.username: postgres$' "$hybrid_query_values"
if grep -q '^db-provider.username: portal_loc_runtime$' \
    "$hybrid_command_values" "$hybrid_query_values"; then
  echo "hybrid control-plane projectors must not use the retired runtime role" >&2
  exit 1
fi

echo "local runtime Compose configuration contract passed"
