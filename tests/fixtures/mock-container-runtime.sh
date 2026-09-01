#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--version" ]]; then
    if [[ "${MOCK_RUNTIME_KIND:-docker}" == "podman" ]]; then
        echo "podman version 5.0.0"
    else
        echo "Docker version 27.0.0"
    fi
    exit 0
fi

printf '%s\n' "$@" > "${CAPTURE_FILE:?CAPTURE_FILE is required}"
