#!/usr/bin/env bash
set -euo pipefail
runner_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace_dir="$(cd -- "$runner_dir/../../.." && pwd)"
cd "$runner_dir/.."
[[ -f "$runner_dir/.runtime/admission.json" && -f "$runner_dir/.runtime/credentials.compose.yml" ]] || {
  echo "Run configure-local.py first: runner admission and credentials are required." >&2
  exit 1
}
image_env="${RELEASE_IMAGE_ENV_FILE:-${RELEASE_STATE_DIR:-$workspace_dir/.release-state}/docker-images.env}"
[[ -f "$image_env" ]] || { echo "Release image env file is required: $image_env" >&2; exit 1; }
compose=(docker compose --env-file "$image_env")
portal_env="${LIGHT_PORTAL_ENV_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/lightapi/light-portal.env}"
if [[ -f "$portal_env" ]]; then compose+=(--env-file "$portal_env"); fi
compose+=(-f docker-compose.yml -f "$runner_dir/compose.yml" -f "$runner_dir/.runtime/credentials.compose.yml")
bash "$runner_dir/../../scripts/verify-agent-image.sh" docker "${compose[@]}"
"${compose[@]}" up -d --no-deps --force-recreate controller
"${compose[@]}" up -d --no-deps light-agent light-agent-advisor light-agent-tech-support
systemctl --user restart light-workflow-runner-personal.service
