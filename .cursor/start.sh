#!/usr/bin/env bash
# Per-boot startup for the private-isu Cloud Agent environment.
# Starts the Docker daemon (with nested-VM networking fixes) and brings up the
# webapp stack (nginx + app + MySQL + memcached). Safe to run repeatedly.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck source=/dev/null
source "$REPO_ROOT/.cursor/docker-runtime.sh"

start_dockerd

# `up -d` reuses the prebuilt image and imported MySQL volume from the snapshot
# when present, and builds/imports on demand otherwise. Either way it converges.
( cd webapp && sudo docker compose up -d )

wait_for_app

echo "==> start.sh complete; app available at http://localhost/"
