#!/usr/bin/env bash
# ===========================================================================
# Chimera Fedora 44 COSMIC — Portainer-first Deployment Wizard
#
# Usage:
#   sudo ./scripts/fedora44-portainer-wizard.sh [--stop-on-error]
#
# What it does:
#   1. Runs the Fedora 44 COSMIC preflight check
#   2. Creates /opt/chimera/{cockpit-dashboard,stacks}
#   3. Installs the cockpit dashboard web assets
#   4. Stages the Portainer stack file with environment defaults
#   5. Prints guided next steps for Portainer deployment
# ===========================================================================
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK_SRC="$ROOT_DIR/stacks/portainer/fedora44-cockpit-stack.yml"
DASHBOARD_SRC="$ROOT_DIR/dashboard/cockpit"
TARGET_ROOT="/opt/chimera"
STOP_ON_ERROR=false
FAILED_STEPS=()

step() {
  local name="$1"; shift
  echo "==> $name"
  if "$@"; then
    echo "    [ok] $name"
  else
    echo "    [failed] $name"
    FAILED_STEPS+=("$name")
    $STOP_ON_ERROR && exit 1
    return 0
  fi
}

usage() {
  cat <<USAGE
Usage: sudo ./scripts/fedora44-portainer-wizard.sh [--stop-on-error]

Deploys a Portainer-first Fedora 44 COSMIC stack with:
- Open WebUI + Ollama (local AI endpoint wiring)
- Qdrant + Redis memory core
- Cockpit launch dashboard
- Cloudflared tunnel sidecar (disabled until token set)
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --stop-on-error) STOP_ON_ERROR=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg"; usage; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo/root"
  exit 1
fi

step "Run Fedora 44 COSMIC preflight" bash "$ROOT_DIR/scripts/fedora44-preflight.sh"
step "Create target directories" mkdir -p "$TARGET_ROOT"/{cockpit-dashboard,stacks}
step "Install cockpit dashboard assets" bash -c "cp -r '$DASHBOARD_SRC/'* '$TARGET_ROOT/cockpit-dashboard/'"
step "Install Portainer stack bundle" cp "$STACK_SRC" "$TARGET_ROOT/stacks/fedora44-cockpit-stack.yml"

step "Create env file" bash -c "cat > '$TARGET_ROOT/stacks/.env' <<ENV
TZ=America/New_York
WEBUI_NAME=Chimera Cockpit (Fedora 44 COSMIC)
OPENAI_API_BASE_URL=http://host.docker.internal:8000/v1
OPENAI_API_KEY=change-me
CF_TUNNEL_TOKEN=
ENV"

step "Print next actions" bash -c "cat <<NEXT
Next steps:
1) In Portainer: Stacks -> Add stack -> Upload /opt/chimera/stacks/fedora44-cockpit-stack.yml
2) Add env vars from /opt/chimera/stacks/.env
3) Deploy stack, then open http://<host>:3000
4) In Open WebUI, set connection to local inference endpoint.
NEXT"

if (( ${#FAILED_STEPS[@]} > 0 )); then
  echo ""
  echo "Completed with failed steps:"
  printf ' - %s\n' "${FAILED_STEPS[@]}"
  exit 1
fi

echo "Fedora 44 COSMIC deployment prep finished successfully."
