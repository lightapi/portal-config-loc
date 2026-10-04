#!/usr/bin/env bash
# Shared pre-side-effect guard. Call with the same ordered env files as Compose.
portal_packaged_images_load() {
    local helper_dir selection line env_file
    local args=(--effective)
    helper_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    for env_file in "$@"; do
        [[ -z "$env_file" ]] || args+=(--env-file "$env_file")
    done
    selection="$(python3 -B "$helper_dir/portal-image-fragment.py" "${args[@]}")" || return 1
    while IFS= read -r line; do
        export "${line?}"
    done <<< "$selection"
}
