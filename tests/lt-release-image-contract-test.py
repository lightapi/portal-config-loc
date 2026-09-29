#!/usr/bin/env python3
"""Keep the all-in-lt image manifest aligned with the release profile."""

import importlib.util
import os
import re
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
COMPOSE = ROOT / "portal-config-loc/all-in-lt/docker-compose.yml"
CHECKER = ROOT / "portal-config-loc/scripts/check-lt-release-images.py"
RELEASE = ROOT / "devops/workspace/release-docker-images.sh"
ISSUER_TOKENS = ROOT / "portal-config-loc/all-in-lt/light-identity-issuer/issuer-tokens.sh"
TAG = "2.3.5-dev.issue424-contract"

spec = importlib.util.spec_from_file_location("lt_release_images", CHECKER)
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)

result = subprocess.run(
    [str(RELEASE), "--profile", "lt-rust", "--tag", TAG, "--dry-run", "--skip-compose-stop"],
    env={**os.environ, "WORKSPACE_DIR": str(ROOT)},
    capture_output=True,
    text=True,
    check=True,
)
image_lines = re.findall(r"^\[release-docker-images\]\s+([A-Z0-9_]+_IMAGE=[^\s]+)$", result.stdout, re.MULTILINE)
assert image_lines, "release dry run emitted no image manifest"
with tempfile.TemporaryDirectory() as directory:
    env_file = Path(directory) / "docker-images.env"
    env_file.write_text("\n".join(image_lines) + "\n")
    assert checker.validate(COMPOSE, env_file) == []

    fake_bin = Path(directory) / "bin"
    fake_bin.mkdir()
    fake_docker = fake_bin / "docker"
    fake_docker.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$ISSUER_DOCKER_LOG"\n')
    fake_docker.chmod(0o755)
    docker_log = Path(directory) / "docker.log"
    token_env = {
        **os.environ,
        "PATH": f"{fake_bin}:{os.environ['PATH']}",
        "RELEASE_IMAGE_ENV_FILE": str(env_file),
        "ISSUER_DOCKER_LOG": str(docker_log),
    }
    subprocess.run([str(ISSUER_TOKENS), "list"], env=token_env, check=True)
    calls = docker_log.read_text().splitlines()
    assert len(calls) == 3
    assert all(f"compose --env-file {env_file}" in call for call in calls)
    assert " stop light-identity-issuer" in calls[0]
    assert " run --rm --no-deps -T light-identity-issuer" in calls[1]
    assert " up -d --no-deps light-identity-issuer" in calls[2]

    env_file.write_text("\n".join(line for line in image_lines if not line.startswith("LIGHT_IDENTITY_ISSUER_IMAGE=")) + "\n")
    assert "LIGHT_IDENTITY_ISSUER_IMAGE" in " ".join(checker.validate(COMPOSE, env_file))
    docker_log.unlink()
    assert subprocess.run([str(ISSUER_TOKENS), "list"], env=token_env, capture_output=True).returncode != 0
    assert not docker_log.exists(), "token helper stopped issuer before validating release images"

    env_file.write_text("\n".join(line.replace(TAG, "different-tag") if line.startswith("LIGHT_IDENTITY_ISSUER_IMAGE=") else line for line in image_lines) + "\n")
    assert "different tags" in " ".join(checker.validate(COMPOSE, env_file))

print("all-in-lt release image contract passed")
