#!/usr/bin/env bash
set -euo pipefail

# Retain the old entry point for callers; Compose now uses packaged images.
case "${1:-}" in
  ""|-f|--force|-h|--help) ;;
  *) printf 'Usage: %s [-f|--force]\n' "$0" >&2; exit 2 ;;
esac
if (( $# > 1 )); then
  printf 'Usage: %s [-f|--force]\n' "$0" >&2
  exit 2
fi
cat <<'MESSAGE'
Host service-JAR copying is retired for all Portal Compose layouts.
Build both packaged images from light-portal with ./build.sh <tag>, then select
PORTAL_HYBRID_COMMAND_IMAGE and PORTAL_HYBRID_QUERY_IMAGE in your environment file.
No files were copied or projects rebuilt.
MESSAGE
