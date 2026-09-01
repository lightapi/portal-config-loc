#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${CAPTURE_FILE:?CAPTURE_FILE is required}"
if [[ " $* " == *" ps -q operational-store-provisioner "* ]]; then
    printf 'test-container-id\n'
fi
