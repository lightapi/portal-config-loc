#!/usr/bin/env bash
# Run after operational bundle 2.4.0 is applied and the Workflow stack is stopped.
# This streams credential rows between local databases without writing token data
# to a host file. It does not remove the source schema.
set -euo pipefail

container=${POSTGRES_CONTAINER:-postgres}
source_db=${WORKFLOW_CREDENTIAL_SOURCE_DB:-workflow_credentials}
target_db=${WORKFLOW_OPERATIONAL_TARGET_DB:-operations}

query() {
  docker exec "$container" psql -X -q -v ON_ERROR_STOP=1 -U postgres -d "$1" -Atc "$2"
}

copy_table() {
  local source_table=$1 target_table=$2
  local source_count target_count source_hash target_hash target_row
  source_count=$(query "$source_db" "SELECT count(*) FROM workflow_secret.$source_table")
  target_count=$(query "$target_db" "SELECT count(*) FROM workflow_ops.$target_table")
  if [[ "$target_count" != 0 ]]; then
    echo "Target $target_table already has $target_count rows; inspect before retry" >&2
    return 1
  fi
  docker exec "$container" psql -X -q -v ON_ERROR_STOP=1 -U postgres -d "$source_db" \
    -c "COPY workflow_secret.$source_table TO STDOUT" |
    docker exec -i "$container" psql -X -q -v ON_ERROR_STOP=1 -U postgres -d "$target_db" \
      -c "COPY workflow_ops.$target_table FROM STDIN" >/dev/null
  target_count=$(query "$target_db" "SELECT count(*) FROM workflow_ops.$target_table")
  if [[ "$source_count" != "$target_count" ]]; then
    echo "Count mismatch for $source_table: source=$source_count target=$target_count" >&2
    return 1
  fi
  source_hash=$(query "$source_db" "SELECT md5(coalesce(string_agg(md5(row_to_json(t)::jsonb::text),',' ORDER BY md5(row_to_json(t)::jsonb::text)),'') ) FROM workflow_secret.$source_table t")
  if [[ "$target_table" == workflow_long_credential_t ]]; then
    target_row="(row_to_json(t)::jsonb - 'token_bytes') || jsonb_build_object('ciphertext',t.token_bytes)"
  else
    target_row='row_to_json(t)::jsonb'
  fi
  target_hash=$(query "$target_db" "SELECT md5(coalesce(string_agg(md5(($target_row)::text),',' ORDER BY md5(($target_row)::text)),'') ) FROM workflow_ops.$target_table t")
  if [[ "$source_hash" != "$target_hash" ]]; then
    echo "Content mismatch for $source_table" >&2
    return 1
  fi
  echo "$source_table -> $target_table: $target_count rows, content verified"
}

[[ $(query "$target_db" "SELECT to_regclass('workflow_ops.workflow_long_credential_t') IS NOT NULL") == t ]] || {
  echo 'Apply operational bundle 2.4.0 before migrating credentials' >&2
  exit 1
}

copy_table identity_t workflow_broker_identity_t
copy_table enrollment_t workflow_broker_enrollment_t
copy_table grant_t workflow_broker_grant_t
copy_table run_t workflow_broker_run_t
copy_table renewal_t workflow_broker_renewal_t

if [[ $(query "$source_db" "SELECT to_regclass('workflow_secret.long_binding_t') IS NOT NULL") == t ]]; then
  copy_table long_identity_t workflow_long_identity_t
  copy_table long_binding_t workflow_long_credential_t
fi

echo 'Credential rows copied and counts verified. Keep the source schema until backup and application checks are complete.'
