#!/bin/bash
###############################################################################
# brain-setup.sh (vLLM Only)
# NODE B (Brain) - Pop!_OS | Ultra 9 285K | RX 7900 XT 20GB | 128GB DDR5
# Usage: bash brain-setup.sh
###############################################################################

set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[✓]${NC} $1"; }
warn() { echo -e "${Y}[!]${NC} $1"; }
fail() { echo -e "${R}[✗]${NC} $1"; }
info() { echo -e "${B}[i]${NC} $1"; }
section() { echo -e "\n${BOLD}═══ $1 ═══${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   BRAIN (NODE B) Setup — vLLM Only              ║"
echo "║   Pop!_OS | RX 7900 XT 20GB | 128GB DDR5       ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

MY_IP=$(hostname -I | awk '{print $1}')

# ── SYSTEM ──
section "SYSTEM"
ok "IP: $MY_IP"
ok "Host: $(hostname)"
ok "Kernel: $(uname -r)"
ok "RAM: $(free -g | awk '/Mem:/ {print $2}')GB total, $(free -g | awk '/Mem:/ {print $7}')GB available"

# ── GPU / ROCm ──
section "GPU / ROCm"

if command -v rocm-smi &>/dev/null; then
  ok "rocm-smi found"
  rocm-smi --showproductname 2>/dev/null | grep -i "card\|name" | head -2 | while read line; do info "  $line"; done
  rocm-smi --showmeminfo vram 2>/dev/null | grep -i "total\|used" | head -2 | while read line; do info "  $line"; done
else
  if lspci | grep -qi "amd.*navi\|amd.*radeon"; then
    warn "AMD GPU detected but rocm-smi not installed"
    echo "  Install ROCm: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/"
  else
    fail "No AMD GPU detected"
  fi
fi

[ -e /dev/kfd ] && ok "/dev/kfd exists" || fail "/dev/kfd missing — ROCm kernel driver not loaded"
[ -d /dev/dri ] && ok "/dev/dri exists" || fail "/dev/dri missing"
ls /dev/dri/render* &>/dev/null && ok "Render nodes available" || warn "No render nodes in /dev/dri"

# ── DOCKER ──
section "DOCKER"

if command -v docker &>/dev/null; then
  ok "Docker: $(docker --version | cut -d' ' -f3)"
  docker info &>/dev/null && ok "Daemon running" || fail "Daemon not running"
  docker compose version &>/dev/null && ok "Compose: $(docker compose version --short)" || warn "Compose plugin missing"
else
  fail "Docker not installed — run: curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker \$USER"
fi

# ── DIRECTORIES ──
section "DIRECTORIES"

BRAIN_HOME="${HOME}"
for dir in "$BRAIN_HOME/ai-models" "$BRAIN_HOME/models" "$BRAIN_HOME/openwebui"; do
  [ -d "$dir" ] && ok "Exists: $dir" || { mkdir -p "$dir" && ok "Created: $dir"; }
done

# ── PORTS ──
section "PORTS"
for port in 8000 8001 3000; do
  if ss -tlnp | grep -q ":${port} "; then
    warn "Port $port in use: $(ss -tlnp | grep ":${port} " | awk '{print $NF}' | head -1)"
  else
    ok "Port $port available"
  fi
done

# ── NETWORK ──
section "NETWORK"
ping -c 1 -W 2 192.168.1.222 &>/dev/null && ok "Brawn (192.168.1.222) reachable" || warn "Brawn unreachable"
ping -c 1 -W 2 192.168.1.149 &>/dev/null && ok "Home Assistant (192.168.1.149) reachable" || warn "HA unreachable"

# ── NEXT STEPS ──
section "NEXT STEPS"

echo ""
echo "  1. Download a model:"
echo "     mkdir -p $BRAIN_HOME/models/cognitivecomputations"
echo "     huggingface-cli download cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \\"
echo "       --local-dir $BRAIN_HOME/models/cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ"
echo ""
echo "  2. Deploy:"
echo "     docker compose -f brain-stack.yml up -d"
echo ""
echo "  3. Verify:"
echo "     curl http://localhost:8000/v1/models"
echo ""
echo "  4. Update Brawn's 03-ai-stack.yml:"
echo "     Replace BRAIN_IP with: $MY_IP"
echo ""
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  BRAIN IP: $MY_IP"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
