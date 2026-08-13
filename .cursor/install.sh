#!/usr/bin/env bash
# Idempotent, one-time repository setup for the private-isu Cloud Agent environment.
# Installs the Docker runtime (configured for this nested VM), downloads the
# canonical dataset/image fixtures, prebuilds the benchmarker, and prebuilds/pulls
# the Docker Compose images so agent boots are fast.
#
# NOTE: This deliberately does NOT start MySQL or create its data volume. A
# populated MySQL/InnoDB volume does not survive the environment snapshot/restore
# (InnoDB fails with "Operating system error number 22"), so the dataset is
# imported fresh per boot by start.sh instead.
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

echo "==> [4/5] Starting the Docker daemon for image build/pull"
# shellcheck source=/dev/null
source "$REPO_ROOT/.cursor/docker-runtime.sh"
start_dockerd

echo "==> [5/5] Building the app image and pulling base images"
# Bake the built app image and the pulled base images into the snapshot so
# per-boot startup is fast. Do not start containers or create the MySQL volume.
( cd webapp && sudo docker compose build )
( cd webapp && sudo docker compose pull mysql memcached nginx )

echo "==> install.sh complete"
