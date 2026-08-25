#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'USAGE'
Usage: apply-db-patches.sh SCHEMA PATCH.sql [PATCH.sql ...]

Apply explicitly selected portal-db patches to the running local configserver
database. SCHEMA is normally "configserver" for all-in-lt or "public" for the
legacy all-in-one/all-in-pg layouts.

Patch paths may be absolute, relative to the current directory, or relative to
the portal-config-loc repository root. Applied patch names and SHA-256 checksums
are recorded in portal_schema_patch_t. An applied patch must never be edited.
USAGE
    exit 2
}

[[ $# -ge 2 ]] || usage

schema_name="$1"
shift

if [[ ! "$schema_name" =~ ^[a-z][a-z0-9_]{0,62}$ ]]; then
    echo "apply-db-patches: invalid schema name '$schema_name'" >&2
    exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$script_dir/.." && pwd)"
renderer="$repo_dir/all-in-lt/postgres-db/lib/render-schema.sh"
container_cmd="${CONTAINER_CMD:-docker}"
database_name="${PORTAL_DB_NAME:-configserver}"
database_user="${PORTAL_DB_USER:-postgres}"
database_password="${PORTAL_DB_PASSWORD:-secret}"
container_name="${PORTAL_DB_CONTAINER:-postgres}"
patches=()
temporary_files=()

cleanup() {
    if ((${#temporary_files[@]} > 0)); then
        rm -f -- "${temporary_files[@]}"
    fi
}
trap cleanup EXIT

psql_exec() {
    "$container_cmd" exec -i -e PGPASSWORD="$database_password" "$container_name" \
        psql -v ON_ERROR_STOP=1 -h localhost -U "$database_user" -d "$database_name" "$@"
}

for requested_patch in "$@"; do
    patch="$requested_patch"
    if [[ ! -f "$patch" && -f "$repo_dir/$patch" ]]; then
        patch="$repo_dir/$patch"
    fi
    if [[ ! -f "$patch" ]]; then
        echo "apply-db-patches: patch does not exist: $requested_patch" >&2
        exit 2
    fi
    patch="$(cd -- "$(dirname -- "$patch")" && pwd)/$(basename -- "$patch")"
    patches+=("$patch")
done

mapfile -t patches < <(
    for patch in "${patches[@]}"; do
        printf '%s\t%s\n' "$(basename -- "$patch")" "$patch"
    done | sort -k1,1 | cut -f2-
)

tracking_table="${schema_name}.portal_schema_patch_t"
psql_exec <<SQL
CREATE SCHEMA IF NOT EXISTS $schema_name;
CREATE TABLE IF NOT EXISTS $tracking_table (
    patch_id VARCHAR(128) PRIMARY KEY,
    checksum VARCHAR(128) NOT NULL,
    applied_ts TIMESTAMPTZ NOT NULL DEFAULT now()
);
SQL

declare -A seen_patch_ids=()
for patch in "${patches[@]}"; do
    patch_filename="$(basename -- "$patch")"
    patch_id="${patch_filename%.sql}"
    if [[ "$patch_filename" != *.sql || ! "$patch_id" =~ ^[A-Za-z0-9._-]+$ ]]; then
        echo "apply-db-patches: unsupported patch filename: $patch_filename" >&2
        exit 2
    fi
    if [[ -n "${seen_patch_ids[$patch_id]:-}" ]]; then
        echo "apply-db-patches: duplicate patch id: $patch_id" >&2
        exit 2
    fi
    seen_patch_ids[$patch_id]=1

    checksum="$(sha256sum "$patch" | awk '{print $1}')"
    existing_checksum="$(psql_exec -tAc \
        "SELECT checksum FROM $tracking_table WHERE patch_id = '$patch_id';" | tr -d '[:space:]')"

    if [[ -n "$existing_checksum" ]]; then
        if [[ "$existing_checksum" != "$checksum" ]]; then
            echo "apply-db-patches: checksum drift for $patch_id: database=$existing_checksum file=$checksum" >&2
            exit 1
        fi
        echo "Database patch already applied: $patch_id"
        continue
    fi

    rendered_body="$(mktemp "${TMPDIR:-/tmp}/portal-config-loc-patch-body.XXXXXX.sql")"
    transaction_sql="$(mktemp "${TMPDIR:-/tmp}/portal-config-loc-patch-transaction.XXXXXX.sql")"
    temporary_files+=("$rendered_body" "$transaction_sql")

    if [[ "$schema_name" == "public" ]]; then
        {
            printf 'SET search_path = public;\n'
            sed -e '/^BEGIN;$/d' -e '/^COMMIT;$/d' "$patch"
        } >"$rendered_body"
    else
        if [[ ! -x "$renderer" ]]; then
            echo "apply-db-patches: schema renderer is not executable: $renderer" >&2
            exit 1
        fi
        PORTAL_DB_CONFIGSERVER_SOURCE="$patch" \
            PORTAL_DB_STRIP_TOP_LEVEL_TRANSACTIONS=true \
            "$renderer" configserver "$schema_name" "$rendered_body"
    fi

    {
        printf 'BEGIN;\n'
        cat "$rendered_body"
        printf '\n'
        printf "INSERT INTO %s (patch_id, checksum) VALUES ('%s', '%s');\n" \
            "$tracking_table" "$patch_id" "$checksum"
        printf 'COMMIT;\n'
    } >"$transaction_sql"

    echo "Applying database patch: $patch_id"
    psql_exec <"$transaction_sql"
done

echo "All requested database patches are applied."
