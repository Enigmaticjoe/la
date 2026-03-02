#!/usr/bin/env bash
###############################################################################
# node-a/scripts/verify.sh
# Project Chimera — Node A stack health checks
#
# Usage: bash node-a/scripts/verify.sh
#        (run from anywhere; checks services on 192.168.1.9)
###############################################################################

set -euo pipefail

NODE_A="192.168.1.9"

# ── Colors ───────────────────────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; C='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
ok()      { echo -e "  ${G}✓${NC} $1"; ((pass++)); }
fail()    { echo -e "  ${R}✗${NC} $1"; }
section() { echo -e "\n${BOLD}${C}─── $1 ───${NC}"; }

pass=0
total=0

# ── Helpers ──────────────────────────────────────────────────────────────────
check_http() {
  local ip="$1" port="$2" name="$3" path="${4:-/}"
  ((total++))
  local code
  code=$(curl -sk -o /dev/null -w "%{http_code}" \
    "http://${ip}:${port}${path}" --max-time 5 2>/dev/null || echo "000")
  if [[ "$code" =~ ^(200|204|301|302|307|308)$ ]]; then
    ok "${name} (${ip}:${port}) — HTTP ${code}"
  else
    fail "${name} (${ip}:${port}) — HTTP ${code}"
  fi
}

check_tcp() {
  local ip="$1" port="$2" name="$3"
  ((total++))
  if timeout 3 bash -c "echo > /dev/tcp/${ip}/${port}" 2>/dev/null; then
    ok "${name} TCP (${ip}:${port})"
  else
    fail "${name} TCP (${ip}:${port})"
  fi
}

# ── Banner ───────────────────────────────────────────────────────────────────
echo ""
printf "╔══════════════════════════════════════════════════╗\n"
printf "║  Node A Health Verify — %-27s║\n" "$(date '+%Y-%m-%d %H:%M')"
printf "║  192.168.1.9 | Project Chimera                  ║\n"
printf "╚══════════════════════════════════════════════════╝\n"

# ── Reachability ─────────────────────────────────────────────────────────────
section "Network"
((total++))
if ping -c 1 -W 2 "${NODE_A}" &>/dev/null; then
  ok "Node A (${NODE_A}) reachable"
else
  fail "Node A (${NODE_A}) unreachable — aborting"
  echo ""
  exit 1
fi

# ── Core services ────────────────────────────────────────────────────────────
section "AI Inference"
check_http "${NODE_A}" 8000 "vLLM"             "/health"
check_http "${NODE_A}" 8001 "TEI Embeddings"   "/health"
check_http "${NODE_A}" 4000 "LiteLLM"          "/health"

section "Chat & RAG"
check_http "${NODE_A}" 3000 "Open WebUI"       "/health"
check_http "${NODE_A}" 8888 "SearXNG"          "/"

section "Storage & Cache"
check_http "${NODE_A}" 6333 "Qdrant"           "/healthz"
check_tcp  "${NODE_A}" 6379 "Redis"

section "Dashboard"
check_http "${NODE_A}" 3010 "Homepage"

# ── Inference smoke tests ─────────────────────────────────────────────────────
section "Inference smoke tests"

# vLLM model list
((total++))
models_resp=$(curl -sk \
  --max-time 10 \
  "http://${NODE_A}:8000/v1/models" 2>/dev/null || echo "")
if echo "${models_resp}" | grep -q '"id"'; then
  model=$(echo "${models_resp}" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
  ok "vLLM model loaded: ${model}"
else
  fail "vLLM — no model info returned"
fi

# TEI embedding
((total++))
embed_resp=$(curl -s \
  --max-time 10 \
  -H "Content-Type: application/json" \
  -d '{"inputs":"health check"}' \
  "http://${NODE_A}:8001/embed" 2>/dev/null || echo "")
if echo "${embed_resp}" | grep -q '\['; then
  ok "TEI embeddings — vector returned"
else
  fail "TEI embeddings — no vector"
fi

# ── Docker container status ───────────────────────────────────────────────────
section "Docker containers"
if command -v docker &>/dev/null; then
  running=$(docker ps --filter "name=node-a-" -q 2>/dev/null | wc -l)
  unhealthy=$(docker ps --filter "name=node-a-" --filter "health=unhealthy" -q 2>/dev/null | wc -l)
  echo "  Running: ${running} | Unhealthy: ${unhealthy}"
  if [[ "${unhealthy}" -gt 0 ]]; then
    docker ps --filter "name=node-a-" --filter "health=unhealthy" \
      --format "  ${R}✗${NC} {{.Names}}" 2>/dev/null
  fi
else
  echo "  (docker not available on this host)"
fi

# ── Score ─────────────────────────────────────────────────────────────────────
echo ""
pct=$(( pass * 100 / total ))
if   [[ "${pct}" -ge 90 ]]; then c="${G}"
elif [[ "${pct}" -ge 70 ]]; then c="${Y}"
else                              c="${R}"
fi
echo "╔══════════════════════════════════════════════════╗"
printf "║  Score: ${c}%d/%d (%d%%)${NC}%*s║\n" \
  "${pass}" "${total}" "${pct}" $(( 35 - ${#pass} - ${#total} - ${#pct} )) ""
echo "╚══════════════════════════════════════════════════╝"
echo ""
