#!/bin/bash
###############################################################################
# brawn-validate.sh
# Run after deploying all Portainer stacks to verify everything is healthy
#
# Usage: bash brawn-validate.sh
###############################################################################

set -uo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; C='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "  ${G}✓${NC} $1"; }
warn() { echo -e "  ${Y}!${NC} $1"; }
fail() { echo -e "  ${R}✗${NC} $1"; }
section() { echo -e "\n${BOLD}${C}─── $1 ───${NC}"; }

IP="192.168.1.222"
pass=0; total=0

check_http() {
  local port=$1 name=$2 path=${3:-/}
  ((total++))
  code=$(curl -sk -o /dev/null -w "%{http_code}" "http://${IP}:${port}${path}" --max-time 5 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|301|302|303|307|308)$ ]]; then
    ok "$name (:$port) — HTTP $code"
    ((pass++))
  else
    fail "$name (:$port) — HTTP $code"
  fi
}

check_tcp() {
  local port=$1 name=$2
  ((total++))
  if timeout 3 bash -c "echo > /dev/tcp/${IP}/${port}" 2>/dev/null; then
    ok "$name (:$port) — TCP open"
    ((pass++))
  else
    fail "$name (:$port) — not listening"
  fi
}

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   BRAWN Service Validation                      ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')                          ║"
echo "╚══════════════════════════════════════════════════╝"

# ── CORE INFRASTRUCTURE ──
section "Core Infrastructure"
check_http 8008 "Portainer"
check_http 8010 "Homepage" "/api/widgets"
check_http 3010 "Uptime Kuma"
check_http 9999 "Dozzle"
check_http 1880 "Node-RED"
check_tcp  1883 "MQTT Broker"
check_http 61208 "Glances" "/api/4/cpu"
check_http 8888 "SearXNG"
check_http 8191 "FlareSolverr"
check_http 3100 "Browserless"

# ── MEDIA STACK ──
section "Media Stack"
check_http 9090 "Zurg" "/dav/"
check_http 32400 "Plex" "/web"
check_http 8096 "Jellyfin" "/health"
check_http 9696 "Prowlarr" "/ping"
check_http 8989 "Sonarr" "/ping"
check_http 7878 "Radarr" "/ping"
check_http 8686 "Lidarr" "/ping"
check_http 6767 "Bazarr" "/ping"
check_http 5055 "Overseerr" "/api/v1/status"
check_http 8181 "Tautulli" "/status"
check_http 6500 "RDT-Client"
check_http 8090 "qBittorrent"

# Check rclone mount
echo ""
if [ -d "/mnt/user/media/zurg_RD" ] && ls /mnt/user/media/zurg_RD/ &>/dev/null; then
  contents=$(ls /mnt/user/media/zurg_RD/ 2>/dev/null | head -5)
  if [ -n "$contents" ]; then
    ok "Rclone Zurg mount has content"
    ((pass++))
  else
    warn "Rclone Zurg mount exists but empty"
  fi
  ((total++))
else
  fail "Rclone Zurg mount not accessible"
  ((total++))
fi

# ── AI STACK ──
section "AI Stack"
check_http 11434 "Ollama"
check_http 3000  "OpenWebUI"
check_http 8002  "vLLM" "/health"
check_http 8001  "Embeddings" "/health"
check_http 6333  "Qdrant" "/healthz"
check_http 3002  "AnythingLLM" "/api/ping"
check_http 5678  "n8n" "/healthz"
check_tcp  10300 "Whisper STT"
check_tcp  10200 "Piper TTS"

# GPU check
echo ""
if command -v nvidia-smi &>/dev/null; then
  gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader 2>/dev/null | head -1)
  gpu_mem=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null | head -1)
  ok "GPU: ${gpu_util} util, ${gpu_mem} memory"
fi

# Quick inference test
echo ""
vllm_test=$(curl -sk -X POST "http://${IP}:8002/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen2.5-7B-Instruct-AWQ","messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}' \
  --max-time 30 2>/dev/null)
if echo "$vllm_test" | grep -q "content"; then
  ok "vLLM inference test — PASSED"
  ((pass++))
else
  warn "vLLM inference test — no response (may still be loading)"
fi
((total++))

# ── STORAGE ──
section "Storage"
check_http 8443 "Nextcloud"

# ── HOME ASSISTANT ──
section "Home Assistant Integration"
if ping -c 1 -W 2 192.168.1.149 &>/dev/null; then
  ok "Home Assistant reachable (192.168.1.149)"
  ((pass++))
else
  fail "Home Assistant unreachable"
fi
((total++))

# MQTT sensor check
mqtt_test=$(timeout 3 mosquitto_sub -h ${IP} -t 'homeassistant/#' -C 1 2>/dev/null)
if [ -n "$mqtt_test" ]; then
  ok "MQTT discovery messages flowing"
  ((pass++))
else
  warn "No MQTT discovery messages (hass-unraid may need time)"
fi
((total++))

# ── DOCKER OVERVIEW ──
section "Docker Summary"
running=$(docker ps --format '{{.Names}}' | wc -l)
stopped=$(docker ps -a --filter "status=exited" --format '{{.Names}}' | wc -l)
echo "  Running: $running | Stopped: $stopped"
echo ""

if [ "$stopped" -gt 0 ]; then
  warn "Stopped containers:"
  docker ps -a --filter "status=exited" --format "    {{.Names}} ({{.Status}})" | head -10
fi

# ── FINAL SCORE ──
echo ""
echo "╔══════════════════════════════════════════════════╗"
pct=$((pass * 100 / total))
if [ "$pct" -ge 90 ]; then
  color="$G"
elif [ "$pct" -ge 70 ]; then
  color="$Y"
else
  color="$R"
fi
printf "║  Score: ${color}%d/%d (%d%%)${NC}%*s║\n" "$pass" "$total" "$pct" $((35 - ${#pass} - ${#total} - ${#pct})) ""
echo "╚══════════════════════════════════════════════════╝"
echo ""
