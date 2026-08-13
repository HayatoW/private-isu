#!/usr/bin/env bash
# Idempotent, one-time repository setup for the private-isu Cloud Agent environment.
# Installs the Docker runtime (configured for this nested VM), downloads the
# canonical dataset/image fixtures, prebuilds the benchmarker, and warms the
# Docker Compose stack (app image + imported MySQL data) so later boots are fast.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> [1/5] Installing Docker and nested-container dependencies"
if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get update -qq
  # fuse-overlayfs is required because the default overlayfs graph driver
  # cannot mount inside this nested container VM.
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    docker.io docker-compose-v2 fuse-overlayfs
fi

# Use the fuse-overlayfs storage driver and the classic (non-containerd) graph
# driver, which is the combination that mounts correctly in the nested VM.
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'JSON'
{
  "storage-driver": "fuse-overlayfs",
  "features": { "containerd-snapshotter": false }
}
JSON

echo "==> [2/5] Downloading dataset and image fixtures (make init)"
# Idempotent: the Makefile only downloads files that are missing.
make init

echo "==> [3/5] Building the benchmarker"
( cd benchmarker && make )

echo "==> [4/5] Starting the Docker daemon for image build + data import"
# shellcheck source=/dev/null
source "$REPO_ROOT/.cursor/docker-runtime.sh"
start_dockerd

echo "==> [5/5] Building the app image and importing the MySQL dataset"
# Bringing the stack up here bakes the built app image and the ~1.2GB imported
# MySQL volume into the environment snapshot so agent boots skip the slow import.
( cd webapp && sudo docker compose up -d )
wait_for_app
# Leave the stack stopped in the baseline; start.sh brings it back up per boot.
( cd webapp && sudo docker compose stop )

echo "==> install.sh complete"
