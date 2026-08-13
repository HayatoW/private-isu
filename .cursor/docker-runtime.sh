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

# Block until nginx serves the application homepage (HTTP 200).
wait_for_app() {
  echo "    waiting for the application to answer on http://localhost/"
  for i in $(seq 1 60); do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 http://localhost/ || true)"
    if [ "$code" = "200" ]; then
      echo "    application is up (HTTP 200 after ~${i}0s max)"
      return 0
    fi
    sleep 10
  done
  echo "    ERROR: application did not become ready" >&2
  ( cd "${REPO_ROOT:-/workspace}/webapp" && sudo docker compose logs --tail 30 ) >&2 || true
  return 1
}
