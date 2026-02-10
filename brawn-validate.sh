#!/bin/bash
###############################################################################
# brawn-validate.sh (vLLM Only — No Ollama)
# Usage: bash brawn-validate.sh [BRAIN_IP]
###############################################################################

set -uo pipefail

BRAIN_IP="${1:-}"
BRAWN_IP="192.168.1.222"
HA_IP="192.168.1.149"

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "  ${G}✓${NC} $1"; }
warn() { echo -e "  ${Y}!${NC} $1"; }
fail() { echo -e "  ${R}✗${NC} $1"; }
section() { echo -e "\n${BOLD}${C}─── $1 ───${NC}"; }

pass=0; total=0

check_http() {
  local ip=$1 port=$2 name=$3 path=${4:-/}
  ((total++))
  code=$(curl -sk -o /dev/null -w "%{http_code}" "http://${ip}:${port}${path}" --max-time 5 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|301|302|303|307|308)$ ]]; then
    ok "$name (${ip}:${port}) — $code"; ((pass++))
  else
    fail "$name (${ip}:${port}) — $code"
  fi
}

check_tcp() {
  local ip=$1 port=$2 name=$3
  ((total++))
  if timeout 3 bash -c "echo > /dev/tcp/${ip}/${port}" 2>/dev/null; then
    ok "$name (${ip}:${port})"; ((pass++))
  else
    fail "$name (${ip}:${port})"
  fi
}

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   CHIMERA Validation — $(date '+%Y-%m-%d %H:%M')            ║"
echo "║   Brawn: $BRAWN_IP | vLLM Only              ║"
[ -n "$BRAIN_IP" ] && \
echo "║   Brain: $BRAIN_IP                         ║"
echo "╚══════════════════════════════════════════════════╝"

# ── CORE ──
section "Core Infrastructure"
check_http $BRAWN_IP 8008  "Portainer"
check_http $BRAWN_IP 8010  "Homepage"
check_http $BRAWN_IP 3010  "Uptime Kuma"
check_http $BRAWN_IP 9999  "Dozzle"
check_http $BRAWN_IP 1880  "Node-RED"
check_tcp  $BRAWN_IP 1883  "MQTT"
check_http $BRAWN_IP 61208 "Glances" "/api/4/cpu"
check_http $BRAWN_IP 8888  "SearXNG"
check_http $BRAWN_IP 8191  "FlareSolverr"
check_http $BRAWN_IP 3100  "Browserless"

# ── MEDIA ──
section "Media Stack"
check_http $BRAWN_IP 9090  "Zurg" "/dav/"
check_http $BRAWN_IP 32400 "Plex" "/web"
check_http $BRAWN_IP 8096  "Jellyfin" "/health"
check_http $BRAWN_IP 9696  "Prowlarr" "/ping"
check_http $BRAWN_IP 8989  "Sonarr" "/ping"
check_http $BRAWN_IP 7878  "Radarr" "/ping"
check_http $BRAWN_IP 8686  "Lidarr" "/ping"
check_http $BRAWN_IP 6767  "Bazarr" "/ping"
check_http $BRAWN_IP 5055  "Overseerr" "/api/v1/status"
check_http $BRAWN_IP 8181  "Tautulli" "/status"
check_http $BRAWN_IP 6500  "RDT-Client"
check_http $BRAWN_IP 8090  "qBittorrent"

# ── AI ──
section "AI Stack (vLLM Only)"
check_http $BRAWN_IP 8002  "vLLM Brawn" "/health"
check_http $BRAWN_IP 8001  "Embeddings" "/health"
check_http $BRAWN_IP 6333  "Qdrant" "/healthz"
check_http $BRAWN_IP 3000  "OpenWebUI"
check_http $BRAWN_IP 3002  "AnythingLLM" "/api/ping"
check_http $BRAWN_IP 5678  "n8n" "/healthz"
check_tcp  $BRAWN_IP 10300 "Whisper"
check_tcp  $BRAWN_IP 10200 "Piper"

# GPU
if command -v nvidia-smi &>/dev/null; then
  echo ""
  mem=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1)
  ok "RTX 4070: $mem"
fi

# Inference tests
echo ""
((total++))
resp=$(curl -sk -X POST "http://${BRAWN_IP}:8002/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen2.5-7B-Instruct-AWQ","messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}' \
  --max-time 30 2>/dev/null)
if echo "$resp" | grep -q "content"; then
  ok "Brawn vLLM inference — PASSED"; ((pass++))
else
  fail "Brawn vLLM inference — no response"
fi

((total++))
eresp=$(curl -s "http://${BRAWN_IP}:8001/embed" \
  -H "Content-Type: application/json" \
  -d '{"inputs":"test"}' --max-time 10 2>/dev/null)
if echo "$eresp" | grep -q "\["; then
  ok "Embeddings — PASSED"; ((pass++))
else
  fail "Embeddings — no vector"
fi

# ── STORAGE ──
section "Storage"
check_http $BRAWN_IP 8443  "Nextcloud"

# ── BRAIN ──
if [ -n "$BRAIN_IP" ]; then
  section "Brain (NODE B) — $BRAIN_IP"

  ((total++))
  if ping -c 1 -W 2 "$BRAIN_IP" &>/dev/null; then
    ok "Brain reachable"; ((pass++))
  else
    fail "Brain unreachable"
  fi

  check_http $BRAIN_IP 8000  "Brain vLLM" "/health"
  check_http $BRAIN_IP 3000  "Brain OpenWebUI"

  echo ""
  ((total++))
  bresp=$(curl -sk -X POST "http://${BRAIN_IP}:8000/v1/models" --max-time 5 2>/dev/null)
  if echo "$bresp" | grep -q "id"; then
    model=$(echo "$bresp" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    ok "Brain vLLM model: $model"; ((pass++))
  else
    warn "Brain vLLM — no model info"
  fi

  latency=$(ping -c 3 -W 2 "$BRAIN_IP" 2>/dev/null | tail -1 | awk -F'/' '{print $5}')
  [ -n "$latency" ] && ok "Latency: ${latency}ms"
fi

# ── HA ──
section "Home Assistant"
((total++))
ping -c 1 -W 2 $HA_IP &>/dev/null && { ok "HA reachable ($HA_IP)"; ((pass++)); } || fail "HA unreachable"

# ── DOCKER ──
section "Docker"
running=$(docker ps -q 2>/dev/null | wc -l)
unhealthy=$(docker ps --filter "health=unhealthy" -q 2>/dev/null | wc -l)
echo "  Running: $running | Unhealthy: $unhealthy"
[ "$unhealthy" -gt 0 ] && docker ps --filter "health=unhealthy" --format "  ${R}✗${NC} {{.Names}}" 2>/dev/null

# ── SCORE ──
echo ""
pct=$((pass * 100 / total))
[ "$pct" -ge 90 ] && c="$G" || { [ "$pct" -ge 70 ] && c="$Y" || c="$R"; }
echo "╔══════════════════════════════════════════════════╗"
printf "║  Score: ${c}%d/%d (%d%%)${NC}%*s║\n" "$pass" "$total" "$pct" $((35 - ${#pass} - ${#total} - ${#pct})) ""
echo "╚══════════════════════════════════════════════════╝"
[ -z "$BRAIN_IP" ] && echo "" && echo "  Tip: bash brawn-validate.sh BRAIN_IP"
echo ""
