#!/usr/bin/env bash
# ===========================================================================
# Chimera Fedora 44 COSMIC — Preflight Check
# Validates the host before deploying the Portainer-first AI stack.
#
# Usage:
#   sudo bash scripts/fedora44-preflight.sh
#   FIX_MODE=true sudo bash scripts/fedora44-preflight.sh  # auto-fix warnings
# ===========================================================================
set -euo pipefail

LOG_FILE="${LOG_FILE:-/tmp/chimera-fedora44-preflight.log}"
REPORT_FILE="${REPORT_FILE:-/tmp/chimera-fedora44-preflight-report.txt}"
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

# ---------------------------------------------------------------------------
# OS check — require Fedora 44
# ---------------------------------------------------------------------------
source /etc/os-release
if [[ "${ID:-}" != "fedora" ]]; then
  fail "This preflight targets Fedora 44; detected ${PRETTY_NAME:-unknown}."
  ((errors++))
fi

if [[ "${VERSION_ID:-0}" -lt 44 ]]; then
  warn "Fedora ${VERSION_ID:-unknown} detected (tested baseline: Fedora 44)."
  ((warnings++))
else
  pass "Fedora ${VERSION_ID} detected."
fi

# ---------------------------------------------------------------------------
# COSMIC desktop environment check
# ---------------------------------------------------------------------------
if check_cmd cosmic-session || rpm -q cosmic-desktop-environment >/dev/null 2>&1; then
  pass "COSMIC desktop environment present."
else
  warn "COSMIC desktop not detected. Install with: sudo dnf install @cosmic-desktop-environment"
  ((warnings++))
fi

# ---------------------------------------------------------------------------
# Kernel version — Fedora 44 ships with Linux 7.x
# ---------------------------------------------------------------------------
kernel_major=$(uname -r | cut -d. -f1)
if [[ "$kernel_major" -ge 7 ]]; then
  pass "Kernel $(uname -r) — Linux 7.x or newer detected."
else
  warn "Kernel $(uname -r) detected. Fedora 44 targets Linux 7.x for AMD Zen 6 / Intel Nova Lake support."
  ((warnings++))
fi

# ---------------------------------------------------------------------------
# Hardware checks
# ---------------------------------------------------------------------------
cpu_model=$(lscpu | awk -F: '/Model name/ {print $2; exit}' | xargs)
ram_gb=$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo)
pass "CPU: ${cpu_model}"

if [[ "$ram_gb" -lt 32 ]]; then
  warn "RAM ${ram_gb}GB < 32GB recommended for full AI stack."
  ((warnings++))
else
  pass "RAM: ${ram_gb}GB"
fi

# GPU detection — prefer AMD ROCm, also support Intel Arc
if lspci | grep -Eqi 'AMD.*Radeon|Radeon.*RX'; then
  pass "AMD Radeon GPU detected (ROCm-capable)."
elif lspci | grep -Eqi 'Intel.+Arc'; then
  pass "Intel Arc GPU detected."
else
  warn "No AMD Radeon or Intel Arc GPU detected; check lspci output if expected."
  ((warnings++))
fi

# ROCm presence check (AMD)
if check_cmd rocminfo || [[ -d /opt/rocm ]]; then
  pass "ROCm installation detected."
else
  warn "ROCm not found. For AMD GPU inference install: sudo dnf install rocm-opencl rocm-dev"
  ((warnings++))
fi

# ---------------------------------------------------------------------------
# Docker + Compose plugin
# ---------------------------------------------------------------------------
if check_cmd docker; then
  pass "Docker present: $(docker --version)"
else
  fail "Docker not installed."
  ((errors++))
  run_fix dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
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

# ---------------------------------------------------------------------------
# Required ports
# ---------------------------------------------------------------------------
for p in 3000 11434 8000 9443 6333 6379; do
  if ss -lnt "( sport = :$p )" | tail -n +2 | grep -q .; then
    warn "Port $p already in use."
    ((warnings++))
  else
    pass "Port $p available."
  fi
done

# ---------------------------------------------------------------------------
# Prepare base directories
# ---------------------------------------------------------------------------
mkdir -p /opt/chimera/cockpit-dashboard /opt/chimera/stacks
pass "Prepared paths under /opt/chimera"

# ---------------------------------------------------------------------------
# Write summary report
# ---------------------------------------------------------------------------
cat > "$REPORT_FILE" <<REPORT
Chimera Fedora 44 COSMIC Preflight
===================================
Date: $(date -Iseconds)
OS:   ${PRETTY_NAME:-unknown}
Kernel: $(uname -r)
Log:  $LOG_FILE
Errors:   $errors
Warnings: $warnings
Result:   $([[ $errors -eq 0 ]] && echo READY || echo BLOCKED)
REPORT

if [[ $errors -gt 0 ]]; then
  fail "Preflight blocked with $errors error(s). See $REPORT_FILE"
  exit 1
fi

pass "Preflight complete — $warnings warning(s). System ready for Fedora 44 COSMIC deployment."
