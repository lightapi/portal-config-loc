#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="$repo_root/all-in-lt/docker-compose.yml"
deploy_script="$repo_root/scripts/deploy-local.sh"
bootstrap_script="$repo_root/all-in-lt/postgres-db/operations/bin/bootstrap-operational-databases.sh"
workflow_projection_script="$repo_root/all-in-lt/postgres-db/operations/bin/publish-workflow-projections.sh"
workflow_actions_prepare="$repo_root/all-in-lt/workflow-actions/prepare.py"
hybrid_command_values="$repo_root/all-in-lt/hybrid-command/config/values.yml"
hybrid_query_values="$repo_root/all-in-lt/hybrid-query/node1/values.yml"
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
if grep -Eq 'GATEWAYEVIDENCE_|GATEWAY_EVIDENCE_|gatewayEvidence\.|gateway-evidence\.' "$compose_file"; then
  echo "gateway evidence configuration must come from Portal instance properties" >&2
  exit 1
fi
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
for agent in account advisor tech-support codex-personal; do
  config_dir="$repo_root/all-in-lt/light-agent-$agent-rust/config"
  [[ -f "$config_dir/startup.yml" && -f "$config_dir/ca.pem" ]]
  [[ -f "$config_dir/cert.pem" && -f "$config_dir/key.pem" ]]
  expected_yaml_count=1
  [[ "$agent" == *-personal ]] && expected_yaml_count=2
  [[ "$(find "$config_dir" -maxdepth 1 -name '*.yml' | wc -l)" -eq "$expected_yaml_count" ]]
  grep -q "com.networknt.agent.$agent-1.0.0" "$config_dir/startup.yml"
  grep -q 'https://config-server:8435' "$config_dir/startup.yml"
  grep -q "./light-agent-$agent-rust/config:/config:ro,Z" "$compose_file"
done
claude_personal_config="$repo_root/all-in-lt/light-agent-claude-personal-rust/config"
[[ -f "$claude_personal_config/startup.yml" && -f "$claude_personal_config/ca.pem" ]]
[[ -f "$claude_personal_config/workflow-origin.yml" ]]
grep -q 'com.networknt.agent.claude-personal-1.0.0' "$claude_personal_config/startup.yml"
grep -q 'https://config-server:8435' "$claude_personal_config/startup.yml"
grep -q './light-agent-claude-personal-rust/config:/config:ro,Z' "$compose_file"
grep -q '\${LIGHT_AGENT_ADVISOR_PORT:-8084}:8084' "$compose_file"
grep -q 'curl -f http://localhost:8084/health' "$compose_file"
grep -q '\${LIGHT_AGENT_TECH_SUPPORT_PORT:-8088}:8082' "$compose_file"
grep -q 'curl -f http://localhost:8082/health' "$compose_file"
grep -q '^prepare_database_urls()' "$bootstrap_script"
grep -q 'OPERATIONAL_BUNDLE_VERSION: 2.1.0' "$compose_file"
[[ -x "$workflow_projection_script" ]]
grep -q '^  workflow-projection-sync:' "$compose_file"
grep -q '0005_workflow_catalog_projection' "$workflow_projection_script"
grep -q '0006_workflow_endpoint_resolution' "$workflow_projection_script"
grep -q 'workflow_projection_source.tool_t' "$workflow_projection_script"
grep -q "operation.value->'authentication'->>'type'='none'" "$workflow_projection_script"
grep -q "av.protocol IN ('http','https')" "$workflow_projection_script"
grep -q 'resolution_document' "$workflow_projection_script"
grep -q 'SELECT DISTINCT ON (b.host_id,b.binding_id,t.capability_ref)' "$workflow_projection_script"
grep -q 'AND b.active AND g.active AND t.active AND e.active AND av.active AND a.active' "$workflow_projection_script"
grep -q 'target operational database identity is unavailable or ambiguous' "$workflow_projection_script"
grep -q 'workflow-projection-sync:' "$compose_file"
grep -q 'condition: service_healthy' "$compose_file"
grep -q 'WORKFLOW_PROJECTION_MINIMUM_BINDINGS: "0"' "$compose_file"
grep -q 'WORKFLOW_PROJECTION_MINIMUM_ENDPOINTS: "0"' "$compose_file"
grep -q 'WORKFLOW_PROJECTION_REFRESH_SECONDS: "30"' "$compose_file"
grep -q 'LLM_REASONING_SEAL_KEY: "${LLM_REASONING_SEAL_KEY:-MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY}"' "$compose_file"
grep -q 'required_agent_policy_property_count="33"' "$deploy_script"
grep -q "runtimePolicy.publicationId" "$deploy_script"
grep -q "portalAssociation.runtimeInstanceId" "$deploy_script"
grep -q "agentPolicy.policySnapshot.dataBoundaryDigest" "$deploy_script"
grep -q '3 runnable Agent snapshots' "$deploy_script"
grep -Fq '[[ -n "${WORKFLOW_ACTIONS_DIR:-}" ]]' "$deploy_script"
grep -Fq 'light-agent-codex-personal-workflow' "$deploy_script"
grep -Fq 'light-agent-claude-personal-workflow' "$deploy_script"
grep -Fq "if name in ('codex','claude'): scopes.append('execution.invoke')" "$workflow_actions_prepare"
grep -Fq "runtime_uid='999'; runtime_gid='999'" "$workflow_actions_prepare"
grep -Fq "chmod 644 /target/workflow/action-authorization.json" "$workflow_actions_prepare"
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
grep -Fq '(cs.snapshot_id IS NOT NULL OR v_service_filter IS NOT NULL)' "$repo_root/scripts/refresh-config-snapshots.sh"
grep -Fq 'com.networknt.agent.codex-personal-workflow-1.0.0' "$deploy_script"
grep -Fq 'com.networknt.agent.claude-personal-workflow-1.0.0' "$deploy_script"
grep -Fq 'DEV_CONFIG_SNAPSHOT_SERVICE_ID="$workflow_agent_service_id"' "$deploy_script"
delta_import_line="$(grep -nF '"$SCRIPT_DIR/import-event-deltas.sh" || return 1' "$deploy_script" | cut -d: -f1)"
snapshot_refresh_line="$(grep -nF '"$SCRIPT_DIR/refresh-config-snapshots.sh" || return 1' "$deploy_script" | sed -n '1s/:.*//p')"
[[ "$delta_import_line" -lt "$snapshot_refresh_line" ]]
[[ "$(grep -Fc '[[ -n "${IMPORT_EVENTS+x}" ]] || IMPORT_EVENTS=auto' "$deploy_script")" -eq 2 ]]
grep -q 'ADD COLUMN IF NOT EXISTS contract_version bigint' "$registration_patch"
grep -q '^db-provider.username: postgres$' "$hybrid_command_values"
grep -q '^db-provider.username: postgres$' "$hybrid_query_values"
if grep -q '^db-provider.username: portal_loc_runtime$' \
    "$hybrid_command_values" "$hybrid_query_values"; then
  echo "hybrid control-plane projectors must not use the retired runtime role" >&2
  exit 1
fi

echo "local runtime Compose configuration contract passed"
