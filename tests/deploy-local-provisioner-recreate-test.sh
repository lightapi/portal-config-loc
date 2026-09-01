#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_DIR/.." && pwd)"
TEST_TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

export DEPLOY_LOCAL_SOURCE_ONLY=true
# shellcheck source=../scripts/deploy-local.sh
source "$REPO_DIR/scripts/deploy-local.sh" lt help

BASE_DIR="$TEST_TMP_DIR"
DOCKER_COMPOSE_DIR="$BASE_DIR/portal-config-loc/all-in-lt"
DOCKER_COMPOSE_FILES=(-f "$DOCKER_COMPOSE_DIR/docker-compose.yml")
RELEASE_STATE_DIR="$BASE_DIR/.release-state"
CAPTURE_FILE="$TEST_TMP_DIR/compose.args"
export CAPTURE_FILE

mkdir -p "$DOCKER_COMPOSE_DIR/postgres-db/operations/bin" "$RELEASE_STATE_DIR"
touch "$DOCKER_COMPOSE_DIR/docker-compose.yml"
touch "$DOCKER_COMPOSE_DIR/postgres-db/operations/bin/operational-store-provisioner.sh"
chmod +x "$DOCKER_COMPOSE_DIR/postgres-db/operations/bin/operational-store-provisioner.sh"
printf 'test-token\n' > "$RELEASE_STATE_DIR/operational-store-provisioner-token"

DOCKER_COMPOSE_CMD=("$TEST_DIR/fixtures/mock-compose-provisioner.sh")
CONTAINER_RUNTIME_CMD="$TEST_DIR/fixtures/mock-runtime-inspect.sh"
prepare_operational_provisioner_runtime() {
    operational_provisioner_paths
}
sleep() {
    :
}

start_operational_store_provisioner

grep -F -- "up -d --build --force-recreate operational-store-provisioner" "$CAPTURE_FILE" >/dev/null || {
    echo "provisioner start must force recreation to avoid stale Compose networks" >&2
    cat "$CAPTURE_FILE" >&2
    exit 1
}

echo "deploy-local provisioner recreation test passed"
