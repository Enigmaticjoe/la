#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${LOG_FILE:-/tmp/chimera-fedora43-preflight.log}"
REPORT_FILE="${REPORT_FILE:-/tmp/chimera-fedora43-preflight-report.txt}"
FIX_MODE="${FIX_MODE:-false}"

exec > >(tee -a "$LOG_FILE") 2>&1

pass(){ echo "[PASS] $*"; }
warn(){ echo "[WARN] $*"; }
fail(){ echo "[FAIL] $*"; }

run_fix() {
  if [[ "$FIX_MODE" == "true" ]]; then
    "$@"
  else
    warn "Fix available (rerun with FIX_MODE=true): $*"
  fi
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1
}

errors=0
warnings=0

[[ $EUID -eq 0 ]] || { fail "Run as root (sudo)."; exit 1; }

source /etc/os-release
if [[ "${ID:-}" != "fedora" ]]; then
  fail "This preflight targets Fedora; detected ${PRETTY_NAME:-unknown}."
  ((errors++))
fi

if [[ "${VERSION_ID:-0}" -lt 43 ]]; then
  warn "Fedora ${VERSION_ID:-unknown} detected (tested baseline: Fedora 43)."
  ((warnings++))
else
  pass "Fedora ${VERSION_ID} detected."
fi

# Hardware checks
cpu_model=$(lscpu | awk -F: '/Model name/ {print $2; exit}' | xargs)
ram_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
pass "CPU: ${cpu_model}"
if [[ "$ram_gb" -lt 32 ]]; then
  warn "RAM ${ram_gb}GB < 32GB recommended."
  ((warnings++))
else
  pass "RAM: ${ram_gb}GB"
fi

if lspci | grep -Eqi 'Intel.+Arc'; then
  pass "Intel Arc GPU detected."
else
  warn "Intel Arc GPU not detected; check lspci output if expected."
  ((warnings++))
fi

# Docker + compose plugin
if check_cmd docker; then
  pass "Docker present: $(docker --version)"
else
  fail "Docker not installed."
  ((errors++))
fi

if check_cmd docker && docker compose version >/dev/null 2>&1; then
  pass "docker compose plugin present."
else
  warn "docker compose plugin missing."
  ((warnings++))
  run_fix dnf install -y docker-compose-plugin
fi

if systemctl is-enabled docker >/dev/null 2>&1; then
  pass "Docker service enabled."
else
  warn "Docker service not enabled."
  ((warnings++))
  run_fix systemctl enable --now docker
fi

# Required ports check
for p in 3000 11434 8000 9443 6333 6379; do
  if ss -lnt "( sport = :$p )" | tail -n +2 | grep -q .; then
    warn "Port $p already in use."
    ((warnings++))
  else
    pass "Port $p available."
  fi
done

mkdir -p /opt/chimera/cockpit-dashboard /opt/chimera/stacks
pass "Prepared paths under /opt/chimera"

cat > "$REPORT_FILE" <<REPORT
Fedora Chimera Preflight
========================
Date: $(date -Iseconds)
Log: $LOG_FILE
Errors: $errors
Warnings: $warnings
Result: $([[ $errors -eq 0 ]] && echo READY || echo BLOCKED)
REPORT

if [[ $errors -gt 0 ]]; then
  fail "Preflight blocked with $errors error(s)."
  exit 1
fi

pass "Preflight complete with $warnings warning(s)."
