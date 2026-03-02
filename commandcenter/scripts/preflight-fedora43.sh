#!/usr/bin/env bash
set -euo pipefail

required_cmds=(docker curl jq lspci awk)
ports=(3000 3001 8080 9090 9443 11434 6333)

echo "== Chimera Fedora 44 COSMIC Preflight =="

echo "[1/5] OS check"
if ! grep -q "Fedora Linux 44" /etc/os-release 2>/dev/null; then
  echo "WARN: This script is tuned for Fedora 44 COSMIC." >&2
fi

echo "[2/5] Required commands"
for c in "${required_cmds[@]}"; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "  OK  $c"
  else
    echo "  MISS $c"
  fi
done

echo "[3/5] Docker health"
if systemctl is-active --quiet docker; then
  echo "  OK docker service active"
else
  echo "  WARN docker service is not active"
fi

echo "[4/5] Port conflicts"
for p in "${ports[@]}"; do
  if ss -lnt "( sport = :$p )" | tail -n +2 | grep -q .; then
    echo "  IN_USE :$p"
  else
    echo "  FREE   :$p"
  fi
done

echo "[5/5] GPU and memory snapshot"
lspci | grep -Ei 'VGA|3D|Display' || true
free -h

echo "Preflight complete. Resolve any MISS/IN_USE before deploying the Portainer stack on Fedora 44 COSMIC."
