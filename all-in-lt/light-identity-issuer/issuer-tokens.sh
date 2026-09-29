#!/usr/bin/env bash
# Inspect and re-arm the issuer's spent bootstrap tokens.
#
#   ./issuer-tokens.sh list             which tokens have been spent, and when
#   ./issuer-tokens.sh reset <jti>      let a spent token enroll once more
#
# The issuer accepts each bootstrap token once and records that durably, so
# restarting it does NOT re-arm a token. Use this instead, for example after
# deleting ~/.light/dev to enroll the Light CLI again. The token's jti is a claim
# inside the token: for the dev light-cli token it is Tide00yxSVilY9LXNKdRqg.
#
# The issuer is stopped while the record is read or changed (the record is locked
# by the running service) and started again afterwards.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
service=light-identity-issuer
binary=/app/light-identity-issuer-service
release_image_env_file="${RELEASE_IMAGE_ENV_FILE:-../../.release-state/docker-images.env}"
python3 ../scripts/check-lt-release-images.py docker-compose.yml "$release_image_env_file"
compose=(docker compose --env-file "$release_image_env_file")

case "${1:-}" in
  list)  command=(list-spent) ;;
  reset) : "${2:?usage: $0 reset <jti>}"; command=(reset-token "$2") ;;
  *)     echo "usage: $0 list | reset <jti>" >&2; exit 2 ;;
esac

"${compose[@]}" stop "$service" >/dev/null
status=0
"${compose[@]}" run --rm --no-deps -T "$service" "$binary" "${command[@]}" || status=$?
"${compose[@]}" up -d --no-deps "$service" >/dev/null
exit "$status"
