#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
compose_file="$repo_root/all-in-lt/docker-compose.yml"
deploy_script="$repo_root/scripts/deploy-local.sh"
bootstrap_script="$repo_root/all-in-lt/postgres-db/operations/bin/bootstrap-operational-store.sh"

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
grep -q 'AGENTPOLICY_AGENTDEFID: 019d82bf-ab5e-791a-885c-d08aafa2b614' "$compose_file"
grep -q 'AGENTPOLICY_AGENTDEFID: 019d82be-e151-7ca5-8155-cdb04b2eb350' "$compose_file"
grep -q 'AGENTPOLICY_AGENTDEFID: 019d82bd-dc73-7638-bc58-aaa33cb638c3' "$compose_file"
grep -q 'database_url="${OPERATIONAL_DATABASE_URL:-}"' "$bootstrap_script"

echo "local runtime Compose configuration contract passed"
