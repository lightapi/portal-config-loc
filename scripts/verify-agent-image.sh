#!/usr/bin/env bash
# Usage: bash verify-agent-image.sh docker docker compose [compose options...]
set -euo pipefail
runtime="$1"
shift
images=$("$@" config --format json | python3 -c '
import json, sys
services = json.load(sys.stdin)["services"]
print("\n".join(sorted({services[name]["image"] for name in
    ["light-agent", "light-agent-advisor", "light-agent-tech-support"]})))
')
while IFS= read -r image; do
    [[ -n "$image" ]] || { echo "Missing agent image selection" >&2; exit 1; }
    if ! "$runtime" image inspect "$image" >/dev/null 2>&1; then
        "$runtime" pull "$image"
    fi
    capability=$("$runtime" image inspect --format '{{ index .Config.Labels "io.lightapi.agent.session-lifecycle" }}' "$image" 2>/dev/null || true)
    if [[ "$capability" != "1" ]]; then
        echo "Agent image $image lacks session-lifecycle capability 1. Build/publish the corrected light-agent image and select it in RELEASE_IMAGE_ENV_FILE before deploying. Existing services were not stopped." >&2
        exit 1
    fi
    echo "Verified agent session-lifecycle capability: $image"
done <<< "$images"
