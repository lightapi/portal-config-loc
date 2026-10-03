#!/usr/bin/env python3
"""Reject an incomplete or mixed-tag all-in-lt image release before deployment."""

import re
import importlib.util
import sys
from pathlib import Path


OPTIONAL_PERSONAL_IMAGES = {
    "LIGHT_AGENT_CODEX_PERSONAL_IMAGE",
    "LIGHT_AGENT_CLAUDE_PERSONAL_IMAGE",
}
# Portal digests are validated separately from the non-Portal same-tag lane.
PORTAL_PACKAGED_IMAGES = {"PORTAL_HYBRID_COMMAND_IMAGE", "PORTAL_HYBRID_QUERY_IMAGE"}
IMAGE_VARIABLE = re.compile(r"^\s*image:\s*\$\{([A-Z0-9_]+_IMAGE)(?::[-?][^}]*)?\}", re.MULTILINE)


def required_images(compose_file: Path) -> set[str]:
    return set(IMAGE_VARIABLE.findall(compose_file.read_text())) - OPTIONAL_PERSONAL_IMAGES - PORTAL_PACKAGED_IMAGES


def release_images(env_file: Path) -> dict[str, str]:
    images = {}
    for line in env_file.read_text().splitlines():
        if not line or line.lstrip().startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        if key.endswith("_IMAGE"):
            images[key] = value
    return images


def validate(compose_file: Path, env_file: Path) -> list[str]:
    if not env_file.is_file():
        return [f"release image file is missing: {env_file}"]
    required = required_images(compose_file)
    images = release_images(env_file)
    missing = sorted(required - images.keys())
    errors = [f"missing release images: {', '.join(missing)}"] if missing else []
    tags = set()
    for key in sorted(required & images.keys()):
        value = images[key]
        if not re.fullmatch(r"[^\s@:]+(?:/[^\s@:]+)*:[^\s:@/]+", value):
            errors.append(f"{key} has no immutable image tag")
        else:
            tags.add(value.rsplit(":", 1)[1])
    if len(tags) > 1:
        errors.append("release images use different tags")
    if PORTAL_PACKAGED_IMAGES & set(IMAGE_VARIABLE.findall(compose_file.read_text())):
        spec = importlib.util.spec_from_file_location('portal_images', Path(__file__).with_name('portal-image-fragment.py'))
        portal_images = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(portal_images)
        try:
            portal_images.effective_images([env_file])
        except (ValueError, OSError):
            errors.append('Portal images require a valid effective digest pair or Portal-only fragment')
    return errors


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: check-lt-release-images.py COMPOSE_FILE RELEASE_IMAGE_ENV", file=sys.stderr)
        return 2
    errors = validate(Path(sys.argv[1]), Path(sys.argv[2]))
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
