#!/bin/bash
###############################################################################
# brawn-setup.sh
# Run on Brawn (192.168.1.9222) to create all directories, set permissions,
# validate prerequisites, and prepare for Portainer stack deployment.
#
# Usage: bash brawn-setup.sh
###############################################################################

set -euo pipefail

# Colors
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; C='\033[0;36m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[✓]${NC} $1"; }
warn() { echo -e "${Y}[!]${NC} $1"; }
fail() { echo -e "${R}[✗]${NC} $1"; }
info() { echo -e "${B}[i]${NC} $1"; }
section() { echo -e "\n${BOLD}${C}═══ $1 ═══${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   BRAWN Stack Setup & Validation Script         ║"
echo "║   192.168.1.9222 | Portainer :8008               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# 1. CREATE ALL DIRECTORIES
# ============================================================================
section "CREATING DIRECTORIES"

DIRS=(
  # Core Infrastructure
  "/mnt/user/appdata/homepage"
  "/mnt/user/appdata/uptime-kuma"
  "/mnt/user/appdata/nodered"
  "/mnt/user/appdata/mosquitto/config"
  "/mnt/user/appdata/mosquitto/data"
  "/mnt/user/appdata/mosquitto/log"
  "/mnt/user/appdata/hass-unraid/data"
  "/mnt/user/appdata/glances"
  "/mnt/user/appdata/cloudflared"
  "/mnt/user/appdata/searxng"
  "/mnt/user/appdata/searxng-redis"
  # Media Stack
  "/mnt/user/appdata/zurg/config"
  "/mnt/user/appdata/zurg/data"
  "/mnt/user/appdata/rclone"
  "/mnt/user/appdata/rdt-client"
  "/mnt/user/appdata/gluetun"
  "/mnt/user/appdata/qbittorrent"
  "/mnt/user/appdata/plex"
  "/mnt/user/appdata/jellyfin"
  "/mnt/user/appdata/prowlarr"
  "/mnt/user/appdata/sonarr"
  "/mnt/user/appdata/radarr"
  "/mnt/user/appdata/lidarr"
  "/mnt/user/appdata/bazarr"
  "/mnt/user/appdata/overseerr"
  "/mnt/user/appdata/tautulli"
  # AI Stack
  "/mnt/user/appdata/ai-models"
  "/mnt/user/appdata/huggingface/models"
  "/mnt/user/appdata/openwebui"
  "/mnt/user/appdata/anythingllm/hotdir"
  "/mnt/user/appdata/n8n"
  "/mnt/user/appdata/whisper"
  "/mnt/user/appdata/piper"
  "/mnt/qdrant/storage"
  "/mnt/qdrant/snapshots"
  # Storage
  "/mnt/user/appdata/nextcloud/html"
  "/mnt/user/appdata/nextcloud/data"
  "/mnt/user/appdata/nextcloud-db"
  "/mnt/user/appdata/nextcloud-redis"
  # Media paths
  "/mnt/user/media/movies"
  "/mnt/user/media/tv"
  "/mnt/user/media/music"
  "/mnt/user/media/zurg_RD"
  "/mnt/user/downloads"
  # Backup
  "/mnt/user/appdata/BACKUP_CONFIGS/brawn-stacks"
)

created=0
exists=0
for dir in "${DIRS[@]}"; do
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    ((created++))
  else
    ((exists++))
  fi
done
ok "Directories: ${created} created, ${exists} already existed"

# ============================================================================
# 2. SET PERMISSIONS
# ============================================================================
section "SETTING PERMISSIONS"

# Standard Unraid PUID/PGID ownership
chown -R 99:100 /mnt/user/appdata/ 2>/dev/null || warn "Could not chown all of appdata"
chown -R 99:100 /mnt/user/media/ 2>/dev/null || warn "Could not chown media"
chown -R 99:100 /mnt/user/downloads/ 2>/dev/null || warn "Could not chown downloads"
chown -R 99:100 /mnt/qdrant/ 2>/dev/null || warn "Could not chown qdrant"
chmod -R 775 /mnt/user/appdata/ 2>/dev/null || true
chmod -R 775 /mnt/user/media/ 2>/dev/null || true
chmod -R 775 /mnt/qdrant/ 2>/dev/null || true
ok "Permissions set (PUID=99, PGID=100)"

# ============================================================================
# 3. CREATE DEFAULT CONFIG FILES (IF MISSING)
# ============================================================================
section "CONFIG FILES"

# Mosquitto config
if [ ! -f "/mnt/user/appdata/mosquitto/config/mosquitto.conf" ]; then
  cat > /mnt/user/appdata/mosquitto/config/mosquitto.conf << 'MQTTCONF'
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_dest stdout
log_type all
allow_anonymous true
listener 1883
protocol mqtt
listener 9001
protocol websockets
MQTTCONF
  ok "Created mosquitto.conf (anonymous access - secure after setup)"
else
  ok "mosquitto.conf exists"
fi

# Hass-unraid config
if [ ! -f "/mnt/user/appdata/hass-unraid/data/config.yaml" ]; then
  cat > /mnt/user/appdata/hass-unraid/data/config.yaml << 'HASSCONF'
unraid:
  - name: Brawn
    host: 192.168.1.9222
    port: 443
    ssl: true
    ssl_verify: false
    username: root
    password: CHANGE_ME
    api_key: CHANGE_ME
    scan_interval: 30

mqtt:
  host: 192.168.1.9222
  port: 1883
  username: mqtt_user
  password: CHANGE_ME
HASSCONF
  warn "Created hass-unraid config.yaml — EDIT passwords and API key!"
else
  ok "hass-unraid config.yaml exists"
fi

# Rclone config for Zurg
if [ ! -f "/mnt/user/appdata/rclone/rclone.conf" ]; then
  cat > /mnt/user/appdata/rclone/rclone.conf << 'RCLONECONF'
[zurg]
type = webdav
url = http://zurg:9999/dav
vendor = other
RCLONECONF
  ok "Created rclone.conf (zurg WebDAV)"
else
  ok "rclone.conf exists"
fi

# Zurg config template
if [ ! -f "/mnt/user/appdata/zurg/config/config.yml" ]; then
  cat > /mnt/user/appdata/zurg/config/config.yml << 'ZURGCONF'
# Zurg Config - Edit token with your Real-Debrid API key
token: CHANGE_ME_TO_YOUR_RD_API_KEY
host: "0.0.0.0"
port: 9999
concurrent_workers: 32
check_for_changes_every_secs: 15
info_cache_time_secs: 60
retain_folder_name_extension: false
retain_rd_torrent_name: true
auto_delete_rar_torrents: true
on_library_update: |
  echo "Library updated"

directories:
  movies:
    group: media
    group_order: 10
    filters:
      - regex: /\.mkv$|\.mp4$|\.avi$/i
      - regex: /\b(19|20)\d{2}\b/
      - not_regex: /\b(S\d{2}|E\d{2}|season|episode)\b/i
  shows:
    group: media
    group_order: 20
    filters:
      - regex: /\b(S\d{2}|season)\b/i
  anime:
    group: media
    group_order: 30
    filters:
      - regex: /\b(anime|sub|dub|dual.audio)\b/i
ZURGCONF
  warn "Created zurg config.yml — EDIT token with your Real-Debrid API key!"
else
  ok "zurg config.yml exists"
fi

# ============================================================================
# 4. VALIDATE PREREQUISITES
# ============================================================================
section "PREREQUISITES"

# Unraid version
if [ -f /etc/unraid-version ]; then
  version=$(cat /etc/unraid-version | grep -oP '[\d.]+' | head -1)
  ok "Unraid version: $version"
else
  warn "Could not detect Unraid version"
fi

# Docker
if docker info &>/dev/null; then
  running=$(docker ps -q | wc -l)
  total=$(docker ps -aq | wc -l)
  ok "Docker running ($running active / $total total containers)"
else
  fail "Docker is NOT running!"
fi

# NVIDIA GPU
if command -v nvidia-smi &>/dev/null; then
  gpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1)
  gpu_mem=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader 2>/dev/null | head -1)
  ok "GPU detected: $gpu_name ($gpu_mem)"
else
  warn "nvidia-smi not found — GPU passthrough may not work"
fi

# Portainer
if docker ps --format '{{.Names}}' | grep -q portainer; then
  port=$(docker port portainer 2>/dev/null | grep 9000 | head -1 || echo "unknown")
  ok "Portainer is running (port: $port)"
else
  warn "Portainer not detected as running container"
fi

# ============================================================================
# 5. PORT SCAN
# ============================================================================
section "PORT AVAILABILITY"

declare -A PORTS=(
  [1880]="Node-RED"
  [1883]="MQTT"
  [3000]="OpenWebUI"
  [3002]="AnythingLLM"
  [3010]="Uptime Kuma"
  [3100]="Browserless"
  [5055]="Overseerr"
  [5678]="n8n"
  [6333]="Qdrant"
  [6500]="RDT-Client"
  [6767]="Bazarr"
  [7878]="Radarr"
  [8001]="TEI Embeddings"
  [8002]="vLLM"
  [8008]="Portainer"
  [8010]="Homepage"
  [8090]="qBittorrent"
  [8096]="Jellyfin"
  [8181]="Tautulli"
  [8443]="Nextcloud"
  [8686]="Lidarr"
  [8888]="SearXNG"
  [8989]="Sonarr"
  [9090]="Zurg"
  [9696]="Prowlarr"
  [9999]="Dozzle"
  [10200]="Piper TTS"
  [10300]="Whisper STT"
  [11434]="(unused)"
  [32400]="Plex"
  [61208]="Glances"
)

conflicts=0
for port in $(echo "${!PORTS[@]}" | tr ' ' '\n' | sort -n); do
  service="${PORTS[$port]}"
  if ss -tlnp | grep -q ":${port} "; then
    proc=$(ss -tlnp | grep ":${port} " | awk '{print $NF}' | cut -d'"' -f2 | head -1)
    warn "Port $port ($service) — IN USE by $proc"
    ((conflicts++))
  fi
done

if [ "$conflicts" -eq 0 ]; then
  ok "All ports available"
else
  info "$conflicts ports already in use (may be existing containers — that's OK)"
fi

# ============================================================================
# 6. NETWORK CHECK
# ============================================================================
section "NETWORK"

# Check Home Assistant
if ping -c 1 -W 2 192.168.1.9149 &>/dev/null; then
  ok "Home Assistant (192.168.1.9149) reachable"
else
  warn "Cannot reach Home Assistant at 192.168.1.9149"
fi

# Check GraphQL API
response=$(curl -sk -o /dev/null -w "%{http_code}" \
  -X POST https://localhost:4443/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ info { os { hostname } } }"}' 2>/dev/null || echo "000")
if [ "$response" = "200" ] || [ "$response" = "401" ]; then
  ok "Unraid GraphQL API reachable (HTTP $response)"
else
  warn "GraphQL API returned HTTP $response"
fi

# Check existing Docker networks
echo ""
info "Existing Docker networks:"
docker network ls --format "  {{.Name}} ({{.Driver}})" | grep -v "^  bridge\|^  host\|^  none"

# ============================================================================
# 7. SUMMARY
# ============================================================================
section "DEPLOYMENT ORDER"

echo ""
echo "  1. Copy brawn-stacks.env → /mnt/user/appdata/brawn-stacks.env"
echo "     Edit ALL placeholder values (API keys, passwords)"
echo ""
echo "  2. Edit config files:"
echo "     /mnt/user/appdata/hass-unraid/data/config.yaml"
echo "     /mnt/user/appdata/zurg/config/config.yml"
echo ""
echo "  3. Deploy stacks in Portainer (192.168.1.9222:8008):"
echo "     Stack 1: 01-core-infrastructure.yml"
echo "     Stack 2: 02-media-stack.yml (needs .env vars)"
echo "     Stack 3: 03-ai-stack.yml"
echo "     Stack 4: 04-storage-stack.yml (needs .env vars)"
echo ""
echo "  4. Install HACS integration in Home Assistant:"
echo "     - domalab/ha-unraid (GraphQL native)"
echo "     - MQTT integration (broker: 192.168.1.9222:1883)"
echo ""
echo "  5. Validate with: bash brawn-validate.sh"
echo ""

section "PORT MAP (QUICK REFERENCE)"
echo ""
printf "  %-6s %-20s  %-6s %-20s\n" "PORT" "SERVICE" "PORT" "SERVICE"
printf "  %-6s %-20s  %-6s %-20s\n" "────" "───────" "────" "───────"
printf "  %-6s %-20s  %-6s %-20s\n" "1880" "Node-RED" "8888" "SearXNG"
printf "  %-6s %-20s  %-6s %-20s\n" "1883" "MQTT" "8989" "Sonarr"
printf "  %-6s %-20s  %-6s %-20s\n" "3000" "OpenWebUI" "9090" "Zurg"
printf "  %-6s %-20s  %-6s %-20s\n" "3002" "AnythingLLM" "9696" "Prowlarr"
printf "  %-6s %-20s  %-6s %-20s\n" "3010" "Uptime Kuma" "9999" "Dozzle"
printf "  %-6s %-20s  %-6s %-20s\n" "3100" "Browserless" "10200" "Piper TTS"
printf "  %-6s %-20s  %-6s %-20s\n" "5055" "Overseerr" "10300" "Whisper STT"
printf "  %-6s %-20s  %-6s %-20s\n" "5678" "n8n" "" ""
printf "  %-6s %-20s  %-6s %-20s\n" "6333" "Qdrant" "32400" "Plex (host)"
printf "  %-6s %-20s  %-6s %-20s\n" "6500" "RDT-Client" "61208" "Glances"
printf "  %-6s %-20s  %-6s %-20s\n" "6767" "Bazarr" "8008" "Portainer"
printf "  %-6s %-20s  %-6s %-20s\n" "7878" "Radarr" "8010" "Homepage"
printf "  %-6s %-20s  %-6s %-20s\n" "8001" "Embeddings" "8090" "qBittorrent"
printf "  %-6s %-20s  %-6s %-20s\n" "8002" "vLLM" "8096" "Jellyfin"
printf "  %-6s %-20s  %-6s %-20s\n" "8181" "Tautulli" "8443" "Nextcloud"
printf "  %-6s %-20s  %-6s %-20s\n" "8191" "FlareSolverr" "8686" "Lidarr"
echo ""
ok "Setup complete! Ready for Portainer deployment."
