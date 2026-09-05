#!/usr/bin/env bash
set -euo pipefail
runner_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$runner_dir/.."
docker compose -f docker-compose.yml -f "$runner_dir/.runtime/compose.yml" \
  up -d --no-deps --force-recreate controller
docker compose -f docker-compose.yml -f "$runner_dir/.runtime/compose.yml" \
  up -d --no-deps light-agent light-agent-advisor light-agent-tech-support
systemctl --user restart light-workflow-runner-personal.service
