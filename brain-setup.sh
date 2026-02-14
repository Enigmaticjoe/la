#!/bin/bash
###############################################################################
# brain-setup.sh
# NODE B (Brain) - Pop!_OS | Ultra 9 285K | RX 7900 XT 20GB | 128GB DDR5
#
# Usage: bash brain-setup.sh
#
# What this does:
#   1. Cleans up lingering Docker artifacts from prior installs
#   2. Validates GPU / ROCm / Docker prerequisites
#   3. Creates all service directories
#   4. Generates default configs (SearXNG)
#   5. Checks ports and network
###############################################################################

set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[ok]${NC} $1"; }
warn() { echo -e "${Y}[!!]${NC} $1"; }
fail() { echo -e "${R}[xx]${NC} $1"; }
info() { echo -e "${B}[ii]${NC} $1"; }
section() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

echo ""
echo "####################################################"
echo "#  BRAIN (NODE B) Setup                            #"
echo "#  Pop!_OS | Ultra 9 285K | RX 7900 XT 20GB       #"
echo "#  128GB DDR5 | Full RAG Stack                     #"
echo "####################################################"
echo ""

MY_IP=$(hostname -I | awk '{print $1}')
BRAIN_HOME="/home/brains"

# == CLEANUP (Prior Installs) ================================================
section "CLEANUP"

if ! command -v docker &>/dev/null; then
  warn "Docker not installed, skipping cleanup"
else
  # Stop and remove non-Portainer containers
  running=$(docker ps -q --filter "name!=portainer" 2>/dev/null || true)
  if [ -n "$running" ]; then
    info "Running containers (excluding Portainer):"
    docker ps --filter "name!=portainer" --format "  {{.Names}} ({{.Image}})" 2>/dev/null
    echo ""
    read -rp "  Stop and remove these containers? [y/N] " ans
    if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
      docker stop $running 2>/dev/null && docker rm $running 2>/dev/null
      ok "Running containers removed"
    else
      info "Skipped"
    fi
  else
    ok "No stale running containers"
  fi

  # Remove stopped containers (excluding Portainer)
  stopped=$(docker ps -aq --filter "status=exited" 2>/dev/null || true)
  if [ -n "$stopped" ]; then
    info "Stopped containers found:"
    docker ps -a --filter "status=exited" --format "  {{.Names}} ({{.Image}})" 2>/dev/null
    echo ""
    read -rp "  Remove stopped containers? [y/N] " ans
    if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
      docker rm $stopped 2>/dev/null
      ok "Stopped containers removed"
    else
      info "Skipped"
    fi
  else
    ok "No stopped containers"
  fi

  # Dangling images and build cache
  dangling=$(docker images -q --filter "dangling=true" 2>/dev/null || true)
  if [ -n "$dangling" ]; then
    info "Dangling images found: $(echo "$dangling" | wc -l) image(s)"
    read -rp "  Remove dangling images? [y/N] " ans
    if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
      docker image prune -f 2>/dev/null
      ok "Dangling images removed"
    else
      info "Skipped"
    fi
  else
    ok "No dangling images"
  fi

  # Unused volumes
  unused_vols=$(docker volume ls -q --filter "dangling=true" 2>/dev/null || true)
  if [ -n "$unused_vols" ]; then
    info "Unused Docker volumes:"
    echo "$unused_vols" | while read v; do echo "  $v"; done
    echo ""
    read -rp "  Remove unused volumes? [y/N] " ans
    if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
      docker volume prune -f 2>/dev/null
      ok "Unused volumes removed"
    else
      info "Skipped"
    fi
  else
    ok "No unused volumes"
  fi

  # Unused networks (skip defaults)
  unused_nets=$(docker network ls --filter "type=custom" -q 2>/dev/null || true)
  if [ -n "$unused_nets" ]; then
    info "Custom Docker networks:"
    docker network ls --filter "type=custom" --format "  {{.Name}}" 2>/dev/null
    echo ""
    read -rp "  Remove unused custom networks? [y/N] " ans
    if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
      docker network prune -f 2>/dev/null
      ok "Unused networks removed"
    else
      info "Skipped"
    fi
  else
    ok "No custom networks to clean"
  fi

  # Show disk usage summary
  echo ""
  info "Docker disk usage:"
  docker system df 2>/dev/null | while read line; do echo "  $line"; done
  echo ""
  read -rp "  Run full docker system prune (reclaim all unused space)? [y/N] " ans
  if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    docker system prune -af 2>/dev/null
    ok "Docker system pruned"
  else
    info "Skipped"
  fi
fi

# == SYSTEM ===================================================================
section "SYSTEM"
ok "IP: $MY_IP"
ok "Host: $(hostname)"
ok "Kernel: $(uname -r)"
ok "RAM: $(free -g | awk '/Mem:/ {print $2}')GB total, $(free -g | awk '/Mem:/ {print $7}')GB available"

# == GPU / ROCm ===============================================================
section "GPU / ROCm"

if command -v rocm-smi &>/dev/null; then
  ok "rocm-smi found"
  rocm-smi --showproductname 2>/dev/null | grep -i "card\|name" | head -2 | while read line; do info "  $line"; done
  rocm-smi --showmeminfo vram 2>/dev/null | grep -i "total\|used" | head -2 | while read line; do info "  $line"; done
  if command -v rocminfo &>/dev/null; then
    rocminfo | grep -q "gfx1100" && ok "rocminfo reports gfx1100 (RX 7900 XT class)" || warn "rocminfo missing gfx1100 -- check ROCm install"
  else
    warn "rocminfo not installed"
  fi
else
  if lspci | grep -qi "amd.*navi\|amd.*radeon"; then
    warn "AMD GPU detected but rocm-smi not installed"
    echo "  Install ROCm: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/"
  else
    fail "No AMD GPU detected"
  fi
fi

[ -e /dev/kfd ] && ok "/dev/kfd exists" || fail "/dev/kfd missing -- ROCm kernel driver not loaded"
[ -d /dev/dri ] && ok "/dev/dri exists" || fail "/dev/dri missing"
ls /dev/dri/render* &>/dev/null && ok "Render nodes available" || warn "No render nodes in /dev/dri"
[ -d /opt/rocm ] && ok "/opt/rocm present" || warn "/opt/rocm missing -- ROCm runtime not installed"

if [ -z "${HSA_OVERRIDE_GFX_VERSION:-}" ]; then
  warn "HSA_OVERRIDE_GFX_VERSION not set (expected 11.0.0 for gfx1100)"
else
  ok "HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION}"
fi

if [ -z "${ROCM_PATH:-}" ]; then
  warn "ROCM_PATH not set (expected /opt/rocm)"
else
  ok "ROCM_PATH=${ROCM_PATH}"
fi

if [ -z "${HSA_OVERRIDE_GFX_VERSION:-}" ] || [ -z "${ROCM_PATH:-}" ]; then
  info "Suggested /etc/environment entries:"
  info "  HSA_OVERRIDE_GFX_VERSION=11.0.0"
  info "  ROCM_PATH=/opt/rocm"
  info "  HIP_VISIBLE_DEVICES=0"
fi

# == DOCKER ===================================================================
section "DOCKER"

if command -v docker &>/dev/null; then
  ok "Docker: $(docker --version | cut -d' ' -f3)"
  docker info &>/dev/null && ok "Daemon running" || fail "Daemon not running"
  docker compose version &>/dev/null && ok "Compose: $(docker compose version --short)" || warn "Compose plugin missing"
else
  fail "Docker not installed -- run: curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker \$USER"
fi

# == DIRECTORIES ==============================================================
section "DIRECTORIES"

dirs=(
  "$BRAIN_HOME/ai-models"
  "$BRAIN_HOME/openwebui"
  "$BRAIN_HOME/qdrant/storage"
  "$BRAIN_HOME/qdrant/snapshots"
  "$BRAIN_HOME/embeddings-cache"
  "$BRAIN_HOME/searxng"
)

for dir in "${dirs[@]}"; do
  if [ -d "$dir" ]; then
    ok "Exists: $dir"
  else
    mkdir -p "$dir" && ok "Created: $dir" || fail "Could not create: $dir"
  fi
done

# == SEARXNG CONFIG ===========================================================
section "SEARXNG CONFIG"

SEARXNG_SETTINGS="$BRAIN_HOME/searxng/settings.yml"
if [ -f "$SEARXNG_SETTINGS" ]; then
  ok "SearXNG settings.yml already exists"
  info "  Delete $SEARXNG_SETTINGS to regenerate"
else
  SECRET_KEY=$(openssl rand -hex 32 2>/dev/null || head -c 64 /dev/urandom | od -An -tx1 | tr -d ' \n')
  cat > "$SEARXNG_SETTINGS" <<EOCFG
# SearXNG settings - generated by brain-setup.sh
use_default_settings: true

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: false
  method: "GET"

search:
  safe_search: 0
  autocomplete: "duckduckgo"
  default_lang: "en"
  formats:
    - html
    - json
EOCFG
  ok "Created SearXNG settings.yml (JSON API enabled)"
fi

# Also create limiter.toml to prevent SearXNG from complaining
LIMITER_TOML="$BRAIN_HOME/searxng/limiter.toml"
if [ ! -f "$LIMITER_TOML" ]; then
  cat > "$LIMITER_TOML" <<EOCFG
# Limiter disabled -- single-user setup
[botdetection.ip_limit]
link_token = false
EOCFG
  ok "Created limiter.toml (rate limiting disabled)"
fi

# == PORTS ====================================================================
section "PORTS"
for entry in "8000:vLLM" "6333:Qdrant HTTP" "6334:Qdrant gRPC" "8001:TEI Embeddings" "8888:SearXNG" "3000:OpenWebUI"; do
  port="${entry%%:*}"
  name="${entry##*:}"
  if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
    warn "Port $port ($name) in use: $(ss -tlnp | grep ":${port} " | awk '{print $NF}' | head -1)"
  else
    ok "Port $port ($name) available"
  fi
done

# == NETWORK ==================================================================
section "NETWORK"
ping -c 1 -W 2 192.168.1.222 &>/dev/null && ok "Brawn (192.168.1.222) reachable" || warn "Brawn unreachable"
ping -c 1 -W 2 192.168.1.149 &>/dev/null && ok "Home Assistant (192.168.1.149) reachable" || warn "HA unreachable"

# == FIREWALL =================================================================
section "FIREWALL"
if command -v ufw &>/dev/null; then
  UFW_STATUS=$(sudo ufw status 2>/dev/null | head -1 || echo "unknown")
  info "UFW status: $UFW_STATUS"
  if echo "$UFW_STATUS" | grep -qi "active"; then
    info "Required ports for brain-stack:"
    for port in 8000 6333 6334 8001 8888 3000; do
      if sudo ufw status 2>/dev/null | grep -q "$port"; then
        ok "  Port $port allowed"
      else
        warn "  Port $port not in UFW rules"
      fi
    done
    echo ""
    info "To allow all brain-stack ports:"
    info "  sudo ufw allow 8000/tcp  # vLLM"
    info "  sudo ufw allow 6333/tcp  # Qdrant HTTP"
    info "  sudo ufw allow 6334/tcp  # Qdrant gRPC"
    info "  sudo ufw allow 8001/tcp  # Embeddings"
    info "  sudo ufw allow 8888/tcp  # SearXNG"
    info "  sudo ufw allow 3000/tcp  # OpenWebUI"
  fi
else
  ok "UFW not installed (no firewall rules to check)"
fi

# == NEXT STEPS ===============================================================
section "NEXT STEPS"

echo ""
echo "  1. Download a model (if not cached):"
echo "     huggingface-cli download cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ --local-dir /home/brains/ai-models/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ"
echo ""
echo "  2. Deploy the full stack:"
echo "     docker compose -f brain-stack.yml up -d"
echo ""
echo "  3. Wait ~3-5 min for model loads, then verify:"
echo "     curl http://localhost:8000/v1/models       # vLLM (4 min)"
echo "     curl http://localhost:6333/healthz          # Qdrant (20 sec)"
echo "     curl http://localhost:8001/health           # Embeddings (2-3 min)"
echo "     curl http://localhost:8888/healthz          # SearXNG (15 sec)"
echo "     curl http://localhost:3000                  # OpenWebUI (1 min)"
echo ""
echo "  4. Update Brawn's 03-ai-stack.yml OpenWebUI to point here:"
echo "     Replace BRAIN_IP with: $MY_IP"
echo ""
echo "  =================================================="
echo "  BRAIN IP:  $MY_IP"
echo "  SERVICES:  vLLM | Qdrant | Embeddings | SearXNG | OpenWebUI"
echo "  =================================================="
echo ""
