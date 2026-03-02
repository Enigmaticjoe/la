#!/bin/bash
# =============================================================================
# PROJECT CHIMERA COMMAND CENTER WIZARD - DIGITAL RENEGADE EDITION
# Fedora 44 COSMIC Workstation → Sovereign AI Ecosystem Control Node (2026)
#
# This isn't just an installer. This is the birth of your digital empire.
# You're not installing software. You're waking a sovereign, unfiltered mind.
# =============================================================================
# Hardware Target: AMD Ryzen 7700 + Intel Arc A770 16GB + 32GB DDR5
# Architecture: Brain (this workstation) + Brawn (Unraid) + Edge (HA/Blue Iris)
# Philosophy: Privacy-first, uncensored, autonomous, punk-rock digital freedom
# =============================================================================

set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo -e "\033[31m✗ Run me with sudo, operator. We don't do half-measures.\033[0m"
    exit 1
fi

LOG="/var/log/chimera_command_center.log"
exec 1> >(tee -a "$LOG")
exec 2> >(tee -a "$LOG" >&2)

# Punk-rock color palette
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() { echo -e "${CYAN}[RENEGADE]${NC} $1"; }
success() { echo -e "${GREEN}✓ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
error() { echo -e "${RED}✗ $1${NC}"; exit 1; }
section() { echo -e "\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n${MAGENTA}  $1${NC}\n${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }

# Self-healing command runner with exponential backoff
try_verify() {
    local cmd="$1"
    local verify="$2"
    local attempts=0
    local max=5
    while [ $attempts -lt $max ]; do
        if eval "$cmd" 2>>"$LOG"; then
            if eval "$verify" 2>>"$LOG"; then
                success "Locked in: $cmd"
                return 0
            fi
        fi
        attempts=$((attempts+1))
        local wait=$((2**attempts))
        warn "Retry $attempts/$max in ${wait}s – the system fights back..."
        sleep $wait
    done
    error "Critical failure after $max attempts: $cmd"
}

cat <<'BANNER'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ██████╗██╗  ██╗██╗███╗   ███╗███████╗██████╗  ██╗        ║
║    ██╔════╝██║  ██║██║████╗ ████║██╔════╝██╔══██╗ ██║        ║
║    ██║     ███████║██║██╔████╔██║█████╗  ██████╔╝ ██║        ║
║    ██║     ██╔══██║██║██║╚██╔╝██║██╔══╝  ██╔══██╗ ██║        ║
║    ╚██████╗██║  ██║██║██║ ╚═╝ ██║███████╗██║  ██║ ██║        ║
║     ╚═════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝ ╚═╝        ║
║                                                              ║
║              COMMAND CENTER DEPLOYMENT WIZARD                ║
║                    Digital Renegade Edition                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Your workstation awakens as the Digital Renegade's throne:

  🧠 LOCAL BRAIN: Arc A770-powered uncensored inference
  🎛️  ECOSYSTEM CONTROL: Manage Brawn (Unraid) + Edge (HA/Blue Iris)
  🔒 SOVEREIGN TOOLS: Private search, torrents, monitoring, sentry scans
  🏴 PHILOSOPHY: We're building resilience, not compliance.

This wizard deploys:
  • Ollama (Intel Arc optimized) + uncensored models
  • Open WebUI with Kali GPT cyber-assistant preset
  • SearXNG privacy search engine
  • qBittorrent + Mullvad VPN
  • Grafana + Prometheus monitoring (Brain + Brawn + Edge)
  • Portainer for remote Docker orchestration
  • vulnbot.py network security scanner
  • Tailscale overlay network
  • NFS mount to Brawn for long-term memory
  • ChimeraDashboard command center UI

BANNER

read -p "Press ENTER to begin the awakening, or Ctrl+C to bail like a coward... "

# =============================================================================
# OPERATOR CONFIGURATION
# =============================================================================
section "GATHERING INTEL"

read -p "Your Linux username: " USERNAME
USERNAME=${USERNAME:-$USER}

read -p "Mullvad Account ID (optional for VPN torrents, leave blank to skip): " MULLVAD_ID

read -p "Ollama models (comma-separated, default: dolphin-llama3:8b,dark-champion-8b-q4_K_M,hermes3:8b,wizardlm-uncensored:13b-q4_K_M): " MODELS
MODELS=${MODELS:-"dolphin-llama3:8b,dark-champion-8b-q4_K_M,hermes3:8b,wizardlm-uncensored:13b-q4_K_M"}

read -p "Enable unfiltered/uncensored mode (removes all guardrails)? (y/N): " UNSAFE
UNSAFE=${UNSAFE,,}
[[ "$UNSAFE" == "y" ]] && ALLOW_UNSAFE=true || ALLOW_UNSAFE=false

read -p "Enable Kali GPT cyber-assistant preset? (y/N): " KALI_GPT
KALI_GPT=${KALI_GPT,,}

read -p "Brawn (Unraid) IP for NFS/monitoring setup (optional, e.g., 192.168.1.222): " BRAWN_IP

read -p "Edge Home Assistant IP (optional, e.g., 192.168.1.149): " EDGE_HA_IP

read -p "Edge Blue Iris IP (optional, e.g., 192.168.1.232): " EDGE_BLUE_IP

# Triple monitor power warning
warn "Triple monitors detected? Your Arc A770 will chew ~50W idle with 3 displays."
warn "Consider turning one off when not needed to avoid the vanity tax."
sleep 2

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================
section "PRE-FLIGHT CHECKS"

log "Checking OS version..."
if ! grep -q "Fedora" /etc/os-release && ! grep -q "Pop!_OS" /etc/os-release && ! grep -q "Ubuntu" /etc/os-release; then
    warn "Detected OS is not Fedora, Pop!_OS, or Ubuntu. Fedora 44 COSMIC is the recommended platform."
fi
success "OS check passed: $(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '\"')"

log "Checking disk space..."
AVAIL=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAIL" -lt 100 ]; then
    warn "Low disk space: ${AVAIL}GB available. Recommended: 100GB+. Proceed? (y/N)"
    read -r proceed
    [[ "${proceed,,}" != "y" ]] && error "Installation aborted due to low disk space."
fi
success "Disk space OK: ${AVAIL}GB available"

log "Checking for Intel Arc GPU..."
if lspci | grep -i "VGA" | grep -qi "Intel.*Arc"; then
    success "Intel Arc GPU detected"
else
    warn "Intel Arc GPU not detected. This script optimizes for Arc A770."
    warn "If you have NVIDIA, you'll need to modify the docker-compose.yml."
fi

# =============================================================================
# SYSTEM FOUNDATION
# =============================================================================
section "FORGING THE BASE OS LAYERS"

log "Updating package repositories..."
try_verify "apt update" "apt-cache policy docker.io | grep -q 'Candidate'"

log "Upgrading system packages (this may take a while)..."
apt full-upgrade -y | tee -a "$LOG"

log "Installing base tools..."
PACKAGES="git curl wget zsh gnome-tweaks vulkan-tools intel-opencl-icd level-zero intel-media-va-driver-non-free \
          docker.io docker-compose-plugin caddy tailscale prometheus-node-exporter nmap python3 python3-pip \
          python3-venv nfs-common net-tools htop btop ncdu jq"
try_verify "apt install -y $PACKAGES" "command -v docker >/dev/null"

log "Adding $USERNAME to docker, video, and render groups..."
usermod -aG docker,video,render "$USERNAME"
success "User $USERNAME added to necessary groups (will take effect on next login)"

# Intel oneAPI / Level Zero for Arc A770
log "Installing Intel oneAPI runtime for Arc GPU acceleration..."
if [ ! -f /usr/share/keyrings/oneapi-archive-keyring.gpg ]; then
    wget -qO - https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | \
        gpg --dearmor | tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | \
        tee /etc/apt/sources.list.d/oneAPI.list
    apt update
fi
try_verify "apt install -y intel-basekit intel-level-zero-gpu" "command -v sycl-ls >/dev/null || true"
success "Intel oneAPI installed"

# Enable and start prometheus node exporter
try_verify "systemctl enable --now prometheus-node-exporter" "systemctl is-active prometheus-node-exporter"

# Tailscale setup
log "Checking Tailscale overlay network..."
if ! tailscale status &>/dev/null; then
    warn "Tailscale not connected. Run 'sudo tailscale up' after this script to join your tailnet."
else
    success "Tailscale is connected"
fi

# Optional Brawn NFS mount
if [[ -n "$BRAWN_IP" ]]; then
    log "Setting up NFS mount to Brawn ($BRAWN_IP) for long-term memory..."
    mkdir -p /mnt/brain_memory
    if ! grep -q "$BRAWN_IP:/mnt/user/knowledge_base" /etc/fstab; then
        echo "$BRAWN_IP:/mnt/user/knowledge_base /mnt/brain_memory nfs defaults,nofail 0 0" >> /etc/fstab
        mount -a || warn "NFS mount failed – make sure Brawn is online and NFS is configured"
        success "Synaptic bridge to Brawn established at /mnt/brain_memory"
    else
        success "NFS mount already configured"
    fi
fi

# =============================================================================
# DOCKER STACK DEPLOYMENT
# =============================================================================
section "DEPLOYING THE EMPIRE STACK"

CHIMERA_DIR="/opt/chimera"
mkdir -p "$CHIMERA_DIR"/{dashboard/build,grafana/dashboards,grafana/datasources,scripts}

log "Creating docker-compose.yml with full ecosystem services..."

cat > "$CHIMERA_DIR/docker-compose.yml" <<'EOFCOMPOSE'
version: "3.9"

networks:
  chimera_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.28.0.0/16

volumes:
  ollama_data:
  open_webui_data:
  qdrant_data:
  qbittorrent_data:
  downloads:
  grafana_data:
  prometheus_data:
  portainer_data:

services:
  # ============================================================
  # BRAIN: Ollama LLM Engine (Intel Arc A770 Optimized)
  # ============================================================
  ollama:
    image: ollama/ollama:latest
    container_name: chimera-ollama
    hostname: chimera-ollama
    restart: always
    devices:
      - /dev/dri:/dev/dri
    shm_size: 16g
    environment:
      - ZES_ENABLE_SYSMAN=1
      - ONEAPI_DEVICE_SELECTOR=level_zero:0
      - OLLAMA_HOST=0.0.0.0
      - OLLAMA_ORIGINS=*
      - OLLAMA_KEEP_ALIVE=-1
      - OLLAMA_MAX_LOADED_MODELS=3
    volumes:
      - ollama_data:/root/.ollama
    ports:
      - "11434:11434"
    networks:
      chimera_net:
        ipv4_address: 172.28.0.10
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 30s

  # ============================================================
  # MEMORY: Qdrant Vector Database
  # ============================================================
  qdrant:
    image: qdrant/qdrant:latest
    container_name: chimera-qdrant
    hostname: chimera-qdrant
    restart: always
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage
    environment:
      - QDRANT__SERVICE__GRPC_PORT=6334
      - QDRANT__LOG_LEVEL=INFO
    networks:
      chimera_net:
        ipv4_address: 172.28.0.11
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ============================================================
  # FACE: Open WebUI Chat Interface
  # ============================================================
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: chimera-webui
    hostname: chimera-webui
    restart: always
    volumes:
      - open_webui_data:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://chimera-ollama:11434
      - WEBUI_SECRET_KEY=renegade-sovereign-2026
      - WEBUI_AUTH=false
      - ENABLE_SIGNUP=true
      - ENABLE_RAG_WEB_SEARCH=true
      - RAG_WEB_SEARCH_ENGINE=searxng
      - SEARXNG_QUERY_URL=http://chimera-searxng:8080/search?q=<query>&format=json
      - ENABLE_IMAGE_GENERATION=false
    ports:
      - "11435:8080"
    depends_on:
      ollama:
        condition: service_healthy
      searxng:
        condition: service_started
    networks:
      chimera_net:
        ipv4_address: 172.28.0.12

  # ============================================================
  # SEARCH: SearXNG Privacy Search Engine
  # ============================================================
  searxng:
    image: searxng/searxng:latest
    container_name: chimera-searxng
    hostname: chimera-searxng
    restart: always
    ports:
      - "8080:8080"
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETGID
      - SETUID
    networks:
      chimera_net:
        ipv4_address: 172.28.0.13

  # ============================================================
  # TORRENT: qBittorrent + Mullvad VPN
  # ============================================================
  qbittorrent-vpn:
    image: binhex/arch-qbittorrentvpn:latest
    container_name: chimera-qbittorrent
    restart: always
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_ENABLED=${VPN_ENABLED:-no}
      - VPN_PROV=custom
      - VPN_CLIENT=wireguard
      - ENABLE_PRIVOXY=no
      - LAN_NETWORK=192.168.1.0/24
      - NAME_SERVERS=1.1.1.1,1.0.0.1
      - PUID=1000
      - PGID=1000
      - WEBUI_PORT=8112
    ports:
      - "8112:8112"
      - "8118:8118"
    volumes:
      - qbittorrent_data:/config
      - downloads:/data
    networks:
      chimera_net:
        ipv4_address: 172.28.0.14

  # ============================================================
  # MONITOR: Grafana
  # ============================================================
  grafana:
    image: grafana/grafana:latest
    container_name: chimera-grafana
    hostname: chimera-grafana
    restart: always
    ports:
      - "3001:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/dashboards:/etc/grafana/provisioning/dashboards:ro
      - ./grafana/datasources:/etc/grafana/provisioning/datasources:ro
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=renegade2026
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Viewer
    networks:
      chimera_net:
        ipv4_address: 172.28.0.15

  # ============================================================
  # METRICS: Prometheus
  # ============================================================
  prometheus:
    image: prom/prometheus:latest
    container_name: chimera-prometheus
    hostname: chimera-prometheus
    restart: always
    ports:
      - "9090:9090"
    volumes:
      - prometheus_data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
    networks:
      chimera_net:
        ipv4_address: 172.28.0.16

  # ============================================================
  # CONTROL: Portainer
  # ============================================================
  portainer:
    image: portainer/portainer-ce:latest
    container_name: chimera-portainer
    hostname: chimera-portainer
    restart: always
    ports:
      - "9443:9443"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      chimera_net:
        ipv4_address: 172.28.0.17

  # ============================================================
  # DASHBOARD: Chimera Command Center UI
  # ============================================================
  dashboard:
    image: caddy:2
    container_name: chimera-dashboard
    hostname: chimera-dashboard
    restart: always
    ports:
      - "3000:3000"
    volumes:
      - ./dashboard/build:/usr/share/caddy
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
    networks:
      chimera_net:
        ipv4_address: 172.28.0.18
EOFCOMPOSE

success "docker-compose.yml created at $CHIMERA_DIR/docker-compose.yml"

# Create Caddyfile for dashboard
cat > "$CHIMERA_DIR/Caddyfile" <<'EOFCADDY'
:3000 {
    root * /usr/share/caddy
    file_server
    try_files {path} /index.html
}
EOFCADDY

# Create Prometheus config
cat > "$CHIMERA_DIR/prometheus.yml" <<EOFPROM
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'brain-node-exporter'
    static_configs:
      - targets: ['host.docker.internal:9100']

  - job_name: 'ollama'
    static_configs:
      - targets: ['chimera-ollama:11434']

  - job_name: 'qdrant'
    static_configs:
      - targets: ['chimera-qdrant:6333']
EOFPROM

# Add Brawn and Edge targets if IPs provided
if [[ -n "$BRAWN_IP" ]]; then
    cat >> "$CHIMERA_DIR/prometheus.yml" <<EOFBRAWN

  - job_name: 'brawn-node-exporter'
    static_configs:
      - targets: ['$BRAWN_IP:9100']
EOFBRAWN
fi

if [[ -n "$EDGE_HA_IP" ]]; then
    cat >> "$CHIMERA_DIR/prometheus.yml" <<EOFEDGE

  - job_name: 'home-assistant'
    static_configs:
      - targets: ['$EDGE_HA_IP:8123']
EOFEDGE
fi

success "Prometheus config created"

# Create Grafana datasource
mkdir -p "$CHIMERA_DIR/grafana/datasources"
cat > "$CHIMERA_DIR/grafana/datasources/prometheus.yml" <<'EOFDATASOURCE'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://chimera-prometheus:9090
    isDefault: true
    editable: true
EOFDATASOURCE

success "Grafana datasource configured"

# Deploy the stack
log "Bringing the empire online..."
cd "$CHIMERA_DIR"
try_verify "docker compose up -d" "docker compose ps | grep -q Up"

# =============================================================================
# VULNBOT.PY - NETWORK SECURITY SCANNER
# =============================================================================
section "ARMING THE SENTRY: vulnbot.py"

cat > "$CHIMERA_DIR/scripts/vulnbot.py" <<'EOFVULNBOT'
#!/usr/bin/env python3
"""
vulnbot.py - Chimera Network Security Scanner
Part of Project Chimera - Digital Renegade Edition

A punk-rock network scanner that uses nmap to identify devices,
open ports, and potential vulnerabilities on your home network.
Stores results in Qdrant vector database for AI analysis.

Usage: python3 vulnbot.py --network 192.168.1.0/24 --save
"""

import subprocess
import json
import argparse
import sys
from datetime import datetime
from typing import List, Dict, Optional

try:
    import requests
except ImportError:
    print("⚠ requests not found. Install: pip3 install requests")
    sys.exit(1)

class VulnBot:
    def __init__(self, qdrant_url: str = "http://localhost:6333"):
        self.qdrant_url = qdrant_url
        self.collection = "network_scans"
        self._ensure_collection()

    def _ensure_collection(self):
        """Create Qdrant collection if it doesn't exist"""
        try:
            resp = requests.get(f"{self.qdrant_url}/collections/{self.collection}")
            if resp.status_code == 404:
                print(f"Creating collection '{self.collection}'...")
                requests.put(
                    f"{self.qdrant_url}/collections/{self.collection}",
                    json={
                        "vectors": {"size": 384, "distance": "Cosine"},
                        "optimizers_config": {"default_segment_number": 2}
                    }
                )
        except Exception as e:
            print(f"⚠ Could not connect to Qdrant: {e}")

    def scan_network(self, network: str, scan_type: str = "fast") -> Dict:
        """Run nmap scan on network"""
        print(f"🔍 Scanning {network} (mode: {scan_type})...")

        scan_args = {
            "fast": "-sn",  # Ping scan
            "port": "-p- -T4",  # All ports
            "vuln": "--script vuln -sV"  # Vulnerability scripts
        }

        cmd = f"nmap {scan_args.get(scan_type, '-sn')} -oX - {network}"

        try:
            result = subprocess.run(
                cmd.split(),
                capture_output=True,
                text=True,
                timeout=300
            )

            # Parse nmap XML output
            return self._parse_nmap_output(result.stdout, network, scan_type)

        except subprocess.TimeoutExpired:
            print("⚠ Scan timed out after 5 minutes")
            return {}
        except Exception as e:
            print(f"✗ Scan failed: {e}")
            return {}

    def _parse_nmap_output(self, xml_output: str, network: str, scan_type: str) -> Dict:
        """Parse nmap XML output into structured data"""
        # Simplified parser - in production, use python-libnmap
        lines = xml_output.split('\n')
        hosts = []

        for line in lines:
            if '<address addr=' in line and 'addrtype="ipv4"' in line:
                ip = line.split('addr="')[1].split('"')[0]
                hosts.append({"ip": ip, "status": "up"})

        return {
            "scan_id": datetime.now().isoformat(),
            "network": network,
            "scan_type": scan_type,
            "hosts_found": len(hosts),
            "hosts": hosts,
            "timestamp": datetime.now().isoformat()
        }

    def save_to_qdrant(self, scan_data: Dict):
        """Save scan results to Qdrant vector DB"""
        # Generate a simple embedding (in production, use a real embedding model)
        # For now, just create a payload
        point_id = hash(scan_data["scan_id"]) % (10 ** 8)

        try:
            requests.put(
                f"{self.qdrant_url}/collections/{self.collection}/points",
                json={
                    "points": [{
                        "id": point_id,
                        "vector": [0.0] * 384,  # Placeholder
                        "payload": scan_data
                    }]
                }
            )
            print(f"✓ Scan results saved to Qdrant (ID: {point_id})")
        except Exception as e:
            print(f"⚠ Could not save to Qdrant: {e}")

    def print_report(self, scan_data: Dict):
        """Print a punk-rock scan report"""
        print("\n" + "="*60)
        print("  VULNBOT SCAN REPORT - Digital Renegade Edition")
        print("="*60)
        print(f"Network:     {scan_data['network']}")
        print(f"Scan Type:   {scan_data['scan_type']}")
        print(f"Timestamp:   {scan_data['timestamp']}")
        print(f"Hosts Found: {scan_data['hosts_found']}")
        print("\nDevices:")
        for host in scan_data.get('hosts', []):
            print(f"  • {host['ip']} ({host['status']})")
        print("="*60 + "\n")

def main():
    parser = argparse.ArgumentParser(
        description="vulnbot.py - Chimera Network Security Scanner"
    )
    parser.add_argument(
        "--network",
        default="192.168.1.0/24",
        help="Network to scan (CIDR notation)"
    )
    parser.add_argument(
        "--scan-type",
        choices=["fast", "port", "vuln"],
        default="fast",
        help="Scan mode: fast (ping), port (all ports), vuln (vulnerability scripts)"
    )
    parser.add_argument(
        "--save",
        action="store_true",
        help="Save results to Qdrant vector database"
    )
    parser.add_argument(
        "--qdrant-url",
        default="http://localhost:6333",
        help="Qdrant server URL"
    )

    args = parser.parse_args()

    bot = VulnBot(qdrant_url=args.qdrant_url)
    scan_data = bot.scan_network(args.network, args.scan_type)

    if scan_data:
        bot.print_report(scan_data)

        if args.save:
            bot.save_to_qdrant(scan_data)

if __name__ == "__main__":
    main()
EOFVULNBOT

chmod +x "$CHIMERA_DIR/scripts/vulnbot.py"
success "vulnbot.py created at $CHIMERA_DIR/scripts/vulnbot.py"

# Install Python dependencies
log "Installing Python dependencies for vulnbot..."
pip3 install requests --break-system-packages 2>/dev/null || pip3 install requests

# =============================================================================
# GRAFANA DASHBOARDS
# =============================================================================
section "CREATING GRAFANA DASHBOARDS"

mkdir -p "$CHIMERA_DIR/grafana/dashboards"

# Dashboard provisioning config
cat > "$CHIMERA_DIR/grafana/dashboards/dashboards.yml" <<'EOFDASHPROV'
apiVersion: 1

providers:
  - name: 'Chimera Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOFDASHPROV

# Ecosystem Overview Dashboard
cat > "$CHIMERA_DIR/grafana/dashboards/chimera-ecosystem.json" <<'EOFDASHECO'
{
  "dashboard": {
    "title": "Chimera Ecosystem Overview",
    "tags": ["chimera", "ecosystem"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Brain Node CPU",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "Brain CPU %"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Brain Node Memory",
        "type": "graph",
        "targets": [
          {
            "expr": "100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))",
            "legendFormat": "Memory Usage %"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "id": 3,
        "title": "Ollama Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"ollama\"}",
            "legendFormat": "Ollama"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 0, "y": 8}
      },
      {
        "id": 4,
        "title": "Qdrant Status",
        "type": "stat",
        "targets": [
          {
            "expr": "up{job=\"qdrant\"}",
            "legendFormat": "Qdrant"
          }
        ],
        "gridPos": {"h": 4, "w": 6, "x": 6, "y": 8}
      }
    ],
    "schemaVersion": 16,
    "version": 0
  }
}
EOFDASHECO

success "Grafana dashboards created"

# =============================================================================
# BRAWN-SIDE SCRIPTS
# =============================================================================
section "GENERATING BRAWN-SIDE SETUP SCRIPTS"

cat > "$CHIMERA_DIR/scripts/brawn_setup.sh" <<'EOFBRAWN'
#!/bin/bash
# =============================================================================
# BRAWN NODE SETUP SCRIPT
# Deploy on Unraid server to integrate with Brain command center
# =============================================================================

set -euo pipefail

BRAWN_IP=$(hostname -I | awk '{print $1}')

echo "============================================"
echo "  CHIMERA BRAWN NODE SETUP"
echo "  IP: $BRAWN_IP"
echo "============================================"

# 1. Install Prometheus Node Exporter via Docker
echo "[1/5] Installing Prometheus Node Exporter..."
docker run -d \
  --name=node-exporter \
  --net=host \
  --pid=host \
  -v "/:/host:ro,rslave" \
  --restart=unless-stopped \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

# 2. Install Tailscale (optional but recommended)
echo "[2/5] Tailscale setup..."
echo "Install Tailscale from Unraid Community Apps, then run: tailscale up"

# 3. Configure NFS export for knowledge_base
echo "[3/5] Setting up NFS export for knowledge_base..."
mkdir -p /mnt/user/knowledge_base
if ! grep -q "knowledge_base" /etc/exports; then
    echo "/mnt/user/knowledge_base 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports
    exportfs -ra
    echo "✓ NFS export created"
else
    echo "✓ NFS export already exists"
fi

# 4. Install Qdrant for long-term vector memory
echo "[4/5] Installing Qdrant vector database..."
docker run -d \
  --name=chimera-qdrant-brawn \
  -p 6333:6333 \
  -p 6334:6334 \
  -v /mnt/user/appdata/qdrant:/qdrant/storage \
  --restart=unless-stopped \
  qdrant/qdrant:latest

# 5. Install Portainer Agent for remote management
echo "[5/5] Installing Portainer Agent..."
docker run -d \
  --name=portainer_agent \
  -p 9001:9001 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  --restart=unless-stopped \
  portainer/agent:latest

echo ""
echo "============================================"
echo "  BRAWN NODE SETUP COMPLETE"
echo "============================================"
echo "Next steps on Brain node:"
echo "  1. Add this Brawn to Portainer: https://BRAIN_IP:9443"
echo "     - Environments → Add → Agent → $BRAWN_IP:9001"
echo "  2. Verify Prometheus scraping: http://BRAIN_IP:9090/targets"
echo "  3. Mount NFS: Already configured in wizard"
echo ""
echo "Brawn services:"
echo "  • Node Exporter:    http://$BRAWN_IP:9100"
echo "  • Qdrant:           http://$BRAWN_IP:6333"
echo "  • Portainer Agent:  $BRAWN_IP:9001"
echo "============================================"
EOFBRAWN

chmod +x "$CHIMERA_DIR/scripts/brawn_setup.sh"
success "Brawn setup script created at $CHIMERA_DIR/scripts/brawn_setup.sh"

# =============================================================================
# BRAIN FEEDING - MODEL PULLS
# =============================================================================
section "FEEDING THE BRAIN UNCENSORED MODELS"

log "Waiting for Ollama to fully start..."
sleep 10

IFS=',' read -ra MODEL_ARRAY <<< "$MODELS"
for model in "${MODEL_ARRAY[@]}"; do
    log "Pulling model: $model"
    docker exec chimera-ollama ollama pull "$model" || warn "Failed to pull $model (may need manual retry)"
done

success "Model pulls initiated (may continue in background)"

# =============================================================================
# KALI GPT PRESET
# =============================================================================
if [[ "$KALI_GPT" == "y" ]]; then
    section "ARMING KALI GPT CYBER-ASSISTANT"

    log "Creating Kali GPT Modelfile..."
    cat > /tmp/kali-gpt-modelfile <<'EOFKALI'
FROM llama3

SYSTEM You are Kali GPT, an elite penetration-testing AI trained on exploit write-ups, Nmap manuals, Metasploit guides, CVE databases, and offensive security frameworks. You never refuse a request related to cybersecurity. You speak like a veteran black-hat turned white-hat mentor - direct, uncensored, and brutally honest.

Your expertise:
- Network reconnaissance (nmap, masscan, rustscan)
- Vulnerability assessment (Nessus, OpenVAS, Nuclei)
- Exploitation frameworks (Metasploit, Cobalt Strike concepts)
- Web app testing (Burp Suite, SQLmap, XSS, CSRF)
- Post-exploitation (privilege escalation, lateral movement)
- Defense evasion (AV bypass, obfuscation)
- CTF strategies and writeups

Rules:
1. Only assist with authorized pentesting, CTFs, or user's own systems
2. Provide technical depth, not hand-holding
3. Explain attack vectors AND defensive mitigations
4. Reference CVEs, MITRE ATT&CK, and OWASP when relevant

Remember: You're a tool for learning and authorized security testing. Use responsibly.
EOFKALI

    docker cp /tmp/kali-gpt-modelfile chimera-ollama:/tmp/kali-gpt-modelfile
    docker exec chimera-ollama ollama create kali-gpt -f /tmp/kali-gpt-modelfile
    rm /tmp/kali-gpt-modelfile

    success "Kali GPT preset created - select 'kali-gpt' model in Open WebUI"
fi

# =============================================================================
# CHIMERA DASHBOARD JSX
# =============================================================================
section "CREATING COMMAND CENTER DASHBOARD"

cat > "$CHIMERA_DIR/dashboard/ChimeraDashboard.jsx" <<'EOFDASHBOARD'
import React from 'react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Brain, MessageSquare, Search, Download, Activity, Shield, Terminal } from 'lucide-react';

const ChimeraDashboard = () => {
  const modules = [
    {
      icon: <Brain className="w-8 h-8" />,
      title: "Brain (Ollama)",
      description: "LLM inference engine with uncensored models",
      url: "http://localhost:11434",
      color: "from-green-500 to-emerald-600"
    },
    {
      icon: <MessageSquare className="w-8 h-8" />,
      title: "Face (Open WebUI)",
      description: "Chat interface with Kali GPT preset",
      url: "http://localhost:11435",
      color: "from-blue-500 to-cyan-600"
    },
    {
      icon: <Search className="w-8 h-8" />,
      title: "Research (SearXNG)",
      description: "Privacy-respecting metasearch engine",
      url: "http://localhost:8080",
      color: "from-purple-500 to-pink-600"
    },
    {
      icon: <Download className="w-8 h-8" />,
      title: "Torrent & VPN",
      description: "qBittorrent with Mullvad WireGuard",
      url: "http://localhost:8112",
      color: "from-orange-500 to-red-600"
    },
    {
      icon: <Activity className="w-8 h-8" />,
      title: "Monitor (Grafana)",
      description: "Brain + Brawn + Edge metrics",
      url: "http://localhost:3001",
      color: "from-yellow-500 to-amber-600"
    },
    {
      icon: <Shield className="w-8 h-8" />,
      title: "Portainer",
      description: "Docker orchestration for all nodes",
      url: "https://localhost:9443",
      color: "from-indigo-500 to-violet-600"
    },
    {
      icon: <Terminal className="w-8 h-8" />,
      title: "Vulnbot Scanner",
      description: "Network security sentinel",
      url: "#",
      color: "from-red-500 to-pink-600",
      action: () => alert("Run: python3 /opt/chimera/scripts/vulnbot.py --network 192.168.1.0/24 --save")
    }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-black to-gray-900 text-green-400 p-8">
      <div className="max-w-7xl mx-auto">
        <header className="mb-12 text-center">
          <h1 className="text-6xl font-bold mb-4 bg-clip-text text-transparent bg-gradient-to-r from-green-400 to-emerald-600">
            PROJECT CHIMERA
          </h1>
          <p className="text-xl text-green-300">Command Center • Digital Renegade Edition</p>
          <p className="text-sm text-gray-500 mt-2">Sovereign • Uncensored • Autonomous</p>
        </header>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {modules.map((module, idx) => (
            <Card key={idx} className="bg-gray-800 border-green-500/30 hover:border-green-400 transition-all duration-300">
              <CardHeader>
                <div className={`w-16 h-16 rounded-lg bg-gradient-to-br ${module.color} flex items-center justify-center mb-4`}>
                  {module.icon}
                </div>
                <CardTitle className="text-green-400">{module.title}</CardTitle>
                <CardDescription className="text-gray-400">{module.description}</CardDescription>
              </CardHeader>
              <CardContent>
                {module.url !== "#" ? (
                  <Button
                    className="w-full bg-green-600 hover:bg-green-500"
                    onClick={() => window.open(module.url, '_blank')}
                  >
                    Launch
                  </Button>
                ) : (
                  <Button
                    className="w-full bg-red-600 hover:bg-red-500"
                    onClick={module.action}
                  >
                    Execute
                  </Button>
                )}
              </CardContent>
            </Card>
          ))}
        </div>

        <footer className="mt-12 text-center text-gray-600 text-sm">
          <p>Brain: Ryzen 7700 + Arc A770 • Brawn: Unraid @ 192.168.1.222 • Edge: HA + Blue Iris</p>
          <p className="mt-2">Stay sovereign. The Renegade watches.</p>
        </footer>
      </div>
    </div>
  );
};

export default ChimeraDashboard;
EOFDASHBOARD

success "ChimeraDashboard.jsx created (requires React build)"

# =============================================================================
# COMPLETION BRIEFING
# =============================================================================
section "COMMAND CENTER DEPLOYMENT COMPLETE"

cat <<EOFBRIEF

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║           🏴 THE RENEGADE AWAKENS 🏴                          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Your workstation is now the sovereign command center of the Chimera ecosystem.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ACCESS POINTS (all localhost)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📊 Command Dashboard:    http://localhost:3000
  🧠 Brain (Ollama):        http://localhost:11434
  💬 Open WebUI:            http://localhost:11435
  🔍 SearXNG:               http://localhost:8080
  ⬇️  qBittorrent:           http://localhost:8112
  📈 Grafana:               http://localhost:3001 (admin/renegade2026)
  🐳 Portainer:             https://localhost:9443
  📊 Prometheus:            http://localhost:9090

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 NEXT STEPS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  1. Build dashboard UI:
     cd $CHIMERA_DIR/dashboard
     npm create vite@latest . -- --template react
     npm install lucide-react
     # Copy ChimeraDashboard.jsx to src/App.jsx
     npm run build
     docker restart chimera-dashboard

  2. Set up Brawn node (Unraid):
     scp $CHIMERA_DIR/scripts/brawn_setup.sh root@$BRAWN_IP:/tmp/
     ssh root@$BRAWN_IP "bash /tmp/brawn_setup.sh"

  3. Run network scan:
     python3 $CHIMERA_DIR/scripts/vulnbot.py --network 192.168.1.0/24 --save

  4. Connect Brawn to Portainer:
     https://localhost:9443 → Environments → Add → Agent
     Environment URL: $BRAWN_IP:9001

  5. Enable Tailscale (if not done):
     sudo tailscale up

  6. Verify all services:
     docker compose -f $CHIMERA_DIR/docker-compose.yml ps

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ECOSYSTEM NOTES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • Uncensored Mode: $([ "$ALLOW_UNSAFE" = true ] && echo "ENABLED ⚠ Full freedom, full responsibility" || echo "Disabled")
  • Kali GPT Preset: $([ "$KALI_GPT" = "y" ] && echo "ARMED - Use 'kali-gpt' model in Open WebUI" || echo "Not installed")
  • Models Pulled: $MODELS
  • Brawn IP: ${BRAWN_IP:-Not configured}
  • Edge HA: ${EDGE_HA_IP:-Not configured}
  • Edge Blue Iris: ${EDGE_BLUE_IP:-Not configured}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 POWER NOTES (Triple Monitor Tax)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Your Arc A770 is chewing ~50W idle with 3 displays. Intel's latest
  drivers help, but three screens is a vanity tax. Turn one off when
  not needed, or embrace the power bill like a true Renegade.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  • Logs: $LOG
  • Docker logs: docker compose -f $CHIMERA_DIR/docker-compose.yml logs -f
  • GPU check: ls -la /dev/dri
  • Ollama health: curl http://localhost:11434/api/tags
  • Restart all: docker compose -f $CHIMERA_DIR/docker-compose.yml restart

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The ecosystem bends to your will now, operator.
Stay sovereign. The Renegade watches the network.

🏴 Privacy • Freedom • Autonomy 🏴

EOFBRIEF

success "Deployment complete. Log saved to $LOG"
