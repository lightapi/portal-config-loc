#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="$repo_root/all-in-lt/docker-compose.yml"
deploy_script="$repo_root/scripts/deploy-local.sh"
bootstrap_script="$repo_root/all-in-lt/postgres-db/operations/bin/bootstrap-operational-store.sh"
hybrid_command_values="$repo_root/all-in-lt/hybrid-command/config/values.yml"
hybrid_query_values="$repo_root/all-in-lt/hybrid-query/node1/values.yml"
agent_template="$repo_root/all-in-lt/light-agent-rust/config/agent.yml"
agent_values="$repo_root/all-in-lt/light-agent-rust/config/values.yml"

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
grep -q 'GATEWAYEVIDENCE_DATABASEURLFILE: /tmp/gateway-database-url' "$compose_file"
grep -q 'OPERATIONALSTORE_DATABASEURLFILE: /tmp/operational-database-url' "$compose_file"
grep -q 'AGENT_OPERATIONALSTORE_DATABASEURLFILE: /tmp/operational-database-url' "$compose_file"
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
grep -q 'database_url="${OPERATIONAL_DATABASE_URL:-}"' "$bootstrap_script"
grep -q 'required_agent_policy_property_count="33"' "$deploy_script"
grep -q "runtimePolicy.publicationId" "$deploy_script"
grep -q "portalAssociation.runtimeInstanceId" "$deploy_script"
grep -q "agentPolicy.policySnapshot.dataBoundaryDigest" "$deploy_script"
grep -q '3 runnable Agent snapshots' "$deploy_script"
grep -q '^ensure_portal_runtime_database_access()' "$deploy_script"
grep -q 'exec -i -e PGPASSWORD=' "$deploy_script"
grep -q 'GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA configserver TO portal_loc_runtime' "$deploy_script"
grep -q 'ensure_portal_runtime_database_access || return 1' "$deploy_script"
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
