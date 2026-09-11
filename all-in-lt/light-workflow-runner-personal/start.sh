#!/usr/bin/env bash
set -euo pipefail
runner_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$runner_dir/../../scripts/deploy-local.sh" lt "$@"
