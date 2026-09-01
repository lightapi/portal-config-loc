#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$TEST_DIR/.." && pwd)"
TEST_TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMP_DIR"' EXIT

bundle_dir="$TEST_TMP_DIR/bundles"
key_dir="$TEST_TMP_DIR/keys"
mkdir -p "$bundle_dir" "$key_dir"
touch "$bundle_dir/events.zip" "$key_dir/release.pem"

export DEPLOY_LOCAL_SOURCE_ONLY=true
# shellcheck source=../scripts/deploy-local.sh
source "$REPO_DIR/scripts/deploy-local.sh" help

assert_arg() {
    local expected="$1"
    grep -Fqx -- "$expected" "$CAPTURE_FILE" || {
        echo "missing runtime argument: $expected" >&2
        sed 's/^/  /' "$CAPTURE_FILE" >&2
        exit 1
    }
}

assert_common_args() {
    assert_arg "--bundle"
    assert_arg "/events/events.zip"
    assert_arg "--bundle-key-dir"
    assert_arg "/bundle-keys"
    assert_arg "--compose-import"
    if grep -Fqx -- "--filename" "$CAPTURE_FILE"; then
        echo "container invocation must not use the legacy --filename input" >&2
        exit 1
    fi
}

run_case() {
    local runtime_kind="$1"
    local msystem_value="$2"
    local expected_mode="$3"
    local expected_bundle_source="$bundle_dir"
    local expected_key_source="$key_dir"

    export CAPTURE_FILE="$TEST_TMP_DIR/${runtime_kind}-${msystem_value:-linux}.args"
    export MOCK_RUNTIME_KIND="$runtime_kind"
    export CONTAINER_RUNTIME_CMD="$TEST_DIR/fixtures/mock-container-runtime.sh"
    export EVENT_IMPORT_NETWORK="qualification-network"
    if [[ -n "$msystem_value" ]]; then
        export MSYSTEM="$msystem_value"
        export PATH="$TEST_DIR/fixtures:$PATH"
        if [[ "$runtime_kind" == "docker" ]]; then
            expected_bundle_source="C:$bundle_dir"
            expected_key_source="C:$key_dir"
        fi
    else
        unset MSYSTEM || true
    fi

    run_container_event_importer "$bundle_dir/events.zip" "event-importer:test" "$key_dir" --compose-import

    assert_arg "$expected_bundle_source:/events:$expected_mode"
    assert_arg "$expected_key_source:/bundle-keys:$expected_mode"
    assert_common_args
}

run_case docker "" "ro,z"
run_case podman "" "ro,z"
run_case docker "MINGW64" "ro"
run_case podman "MINGW64" "ro"

echo "deploy-local signed-bundle container argument tests passed"
