#!/usr/bin/env bash
# Per-boot startup for the private-isu Cloud Agent environment.
# Starts the Docker daemon (with nested-VM networking fixes) and brings up the
# webapp stack (nginx + app + MySQL + memcached). Safe to run repeatedly.
#
# On the first boot the MySQL container imports the ~1.2GB dataset dump, so the
# initial startup takes a couple of minutes; later boots reuse the volume.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# shellcheck source=/dev/null
source "$REPO_ROOT/.cursor/docker-runtime.sh"

# The dataset dump / image fixtures are git-ignored; make sure they exist before
# MySQL tries to import them (idempotent: only downloads what is missing).
if [ ! -f webapp/sql/dump.sql.bz2 ] || [ ! -d benchmarker/userdata/img ]; then
  echo "==> fetching dataset/image fixtures (make init)"
  make init
fi

start_dockerd

( cd webapp && sudo docker compose up -d )

wait_for_app

echo "==> start.sh complete; app available at http://localhost/"
