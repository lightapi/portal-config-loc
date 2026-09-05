#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="$(cd -- "$script_dir/../../.." && pwd)"
light_fabric_dir="${LIGHT_FABRIC_DIR:-$workspace_root/light-fabric}"
codex_launcher="${LIGHT_CODEX_EXECUTABLE:-$(command -v codex || true)}"
if [[ -z "$codex_launcher" ]]; then
  echo "Codex CLI is required" >&2
  exit 1
fi
codex_root="$(cd -- "$(dirname -- "$(readlink -f "$codex_launcher")")/.." && pwd)"
codex_native="${LIGHT_CODEX_NATIVE_EXECUTABLE:-$(find "$codex_root" -path '*/vendor/*/bin/codex' -type f -perm /111 -print -quit)}"
if [[ -z "$codex_native" ]]; then
  echo "qualified native Codex executable was not found behind $codex_launcher" >&2
  exit 1
fi

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}" \
LIGHT_CODEX_SMOKE_PROFILE=personal-subscription \
LIGHT_CODEX_SMOKE_EXECUTABLE="$codex_native" \
LIGHT_CODEX_SMOKE_AUDIT_DATABASE_URL="${LIGHT_CODEX_SMOKE_AUDIT_DATABASE_URL:-postgres://postgres:secret@127.0.0.1:5432/llm_audit}" \
  "$light_fabric_dir/scripts/run-codex-app-server-smoke.sh"
