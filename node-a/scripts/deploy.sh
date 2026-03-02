#!/usr/bin/env bash
###############################################################################
# node-a/scripts/deploy.sh
# Project Chimera — Node A stack deployment
#
# Usage: bash node-a/scripts/deploy.sh
#        (run from repository root)
###############################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_A_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${NODE_A_DIR}/compose.yml"
ENV_FILE="${NODE_A_DIR}/.env"

# ── Colors ──────────────────────────────────────────────────────────────────
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'; BOLD='\033[1m'
ok()      { echo -e "${G}[✓]${NC} $1"; }
warn()    { echo -e "${Y}[!]${NC} $1"; }
die()     { echo -e "${R}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}${B}═══ $1 ═══${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Node A Stack — Deploy Script                  ║"
echo "║   192.168.1.9 | Project Chimera                 ║"
echo "╚══════════════════════════════════════════════════╝"

# ── Pre-flight checks ────────────────────────────────────────────────────────
section "Pre-flight checks"

command -v docker >/dev/null 2>&1 || die "docker not found"
docker compose version >/dev/null 2>&1 || die "docker compose plugin not found"
ok "docker compose available"

[[ -f "${ENV_FILE}" ]] || die ".env not found — run: cp node-a/.env.example node-a/.env  and fill secrets"
ok ".env present"

# Warn if any CHANGE_ME placeholder remains
if grep -q "CHANGE_ME" "${ENV_FILE}"; then
  warn ".env still contains CHANGE_ME placeholders — fill all secrets before proceeding"
  grep -n "CHANGE_ME" "${ENV_FILE}" | sed 's/^/      /'
  read -rp "Continue anyway? [y/N] " _ans
  [[ "${_ans,,}" == "y" ]] || die "Aborted"
fi

# ── Create persistent data directories ──────────────────────────────────────
section "Creating data directories"

DIRS=(
  /mnt/user/appdata/node-a/vllm-models
  /mnt/user/appdata/node-a/embeddings-cache
  /mnt/user/appdata/node-a/qdrant/storage
  /mnt/user/appdata/node-a/qdrant/snapshots
  /mnt/user/appdata/node-a/redis
  /mnt/user/appdata/node-a/searxng
  /mnt/user/appdata/node-a/litellm
  /mnt/user/appdata/node-a/openwebui
  /mnt/user/appdata/node-a/homepage
)

for d in "${DIRS[@]}"; do
  if [[ ! -d "${d}" ]]; then
    mkdir -p "${d}"
    ok "Created ${d}"
  else
    ok "Exists  ${d}"
  fi
done

# Set ownership for services that respect PUID/PGID (99:100 = nobody:users on Unraid)
chown -R 99:100 \
  /mnt/user/appdata/node-a/openwebui \
  /mnt/user/appdata/node-a/homepage 2>/dev/null || \
  warn "Could not chown openwebui/homepage dirs (may need root)"

# ── Generate SearXNG settings if missing ────────────────────────────────────
section "SearXNG config"

SEARXNG_SETTINGS="/mnt/user/appdata/node-a/searxng/settings.yml"
if [[ ! -f "${SEARXNG_SETTINGS}" ]]; then
  cat > "${SEARXNG_SETTINGS}" <<'SEARXNG_EOF'
use_default_settings: true
server:
  secret_key: "REPLACE_WITH_RANDOM_SECRET"
  limiter: false
  image_proxy: true
ui:
  default_locale: "en"
  default_theme: simple
search:
  safe_search: 0
  autocomplete: ""
  default_lang: "en"
engines:
  - name: google
    disabled: false
  - name: bing
    disabled: false
  - name: duckduckgo
    disabled: false
SEARXNG_EOF
  warn "Generated default SearXNG settings — update secret_key in ${SEARXNG_SETTINGS}"
else
  ok "SearXNG settings already present"
fi

# ── Copy homepage configs ────────────────────────────────────────────────────
section "Homepage config"

for f in services.yaml settings.yaml; do
  src="${NODE_A_DIR}/homepage/${f}"
  dst="/mnt/user/appdata/node-a/homepage/${f}"
  if [[ ! -f "${dst}" ]]; then
    cp "${src}" "${dst}"
    ok "Copied ${f} → ${dst}"
  else
    ok "Homepage ${f} already present (not overwriting)"
  fi
done

# ── Copy LiteLLM config ──────────────────────────────────────────────────────
section "LiteLLM config"

LITELLM_CFG_SRC="${NODE_A_DIR}/litellm/config.yaml"
LITELLM_CFG_DST="/mnt/user/appdata/node-a/litellm/config.yaml"
# compose.yml mounts ./litellm/config.yaml directly, no copy needed
ok "LiteLLM config mounted from ${LITELLM_CFG_SRC}"

# ── Deploy ───────────────────────────────────────────────────────────────────
section "Deploying stack"

docker compose \
  --file "${COMPOSE_FILE}" \
  --env-file "${ENV_FILE}" \
  up -d --remove-orphans

ok "Stack deployed — run node-a/scripts/verify.sh to check health"
echo ""
