#!/usr/bin/env bash
# Shared helpers for running Docker inside this nested Cloud Agent VM.
# Sourced by install.sh and start.sh.

# Start the Docker daemon (no systemd in this VM) and apply the networking
# fixes required for container-to-container traffic on the bridge network.
start_dockerd() {
  # Bridged frames must NOT traverse iptables/nftables here; otherwise
  # container-to-container packets (e.g. app -> mysql) are silently dropped.
  sudo sysctl -w \
    net.bridge.bridge-nf-call-iptables=0 \
    net.bridge.bridge-nf-call-ip6tables=0 \
    net.bridge.bridge-nf-call-arptables=0 >/dev/null 2>&1 || true

  if sudo docker info >/dev/null 2>&1; then
    echo "    dockerd already running"
  else
    echo "    launching dockerd"
    sudo bash -c 'nohup dockerd >/var/log/dockerd.log 2>&1 &'
    for _ in $(seq 1 30); do
      if sudo docker info >/dev/null 2>&1; then break; fi
      sleep 1
    done
    if ! sudo docker info >/dev/null 2>&1; then
      echo "    ERROR: dockerd failed to start; see /var/log/dockerd.log" >&2
      sudo tail -n 20 /var/log/dockerd.log >&2 || true
      return 1
    fi
  fi

  # Re-apply the sysctl after the bridge module is loaded by dockerd.
  sudo sysctl -w \
    net.bridge.bridge-nf-call-iptables=0 \
    net.bridge.bridge-nf-call-ip6tables=0 \
    net.bridge.bridge-nf-call-arptables=0 >/dev/null 2>&1 || true
}

# Block until MySQL has finished importing and nginx serves the homepage (200).
# The first boot imports the ~1.2GB dump, so allow several minutes.
wait_for_app() {
  local compose_dir="${REPO_ROOT:-/workspace}/webapp"

  echo "    waiting for MySQL to accept connections (first boot imports the dataset)"
  for _ in $(seq 1 60); do
    if ( cd "$compose_dir" && sudo docker compose exec -T mysql \
          mysqladmin ping -uroot -proot >/dev/null 2>&1 ); then
      echo "    MySQL is ready"
      break
    fi
    sleep 5
  done

  echo "    waiting for the application to answer on http://localhost/"
  for _ in $(seq 1 60); do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://localhost/ || true)"
    if [ "$code" = "200" ]; then
      echo "    application is up (HTTP 200)"
      return 0
    fi
    sleep 5
  done

  echo "    ERROR: application did not become ready" >&2
  ( cd "$compose_dir" && sudo docker compose logs --tail 40 ) >&2 || true
  return 1
}
