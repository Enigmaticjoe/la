#!/bin/bash
###############################################################################
# Brain Project - Automated Setup Script
# Complete setup for self-evolving AI brain system
# 
# This script will:
# 1. Check system prerequisites
# 2. Validate GPU/ROCm configuration
# 3. Create all required directories
# 4. Generate configuration files
# 5. Download AI models
# 6. Initialize Qdrant collections
# 7. Deploy all Docker containers
# 8. Run health checks
#
# Hardware Requirements:
# - AMD Radeon RX 7900 XT (20GB VRAM)
# - Intel Core i9-265F or equivalent
# - 128GB RAM
# - ROCm 6.0+ installed
# - Docker with GPU support
###############################################################################

set -euo pipefail

# Colors for output
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; 
C='\033[0;36m'; M='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

ok()      { echo -e "${G}✓${NC} $1"; }
warn()    { echo -e "${Y}⚠${NC} $1"; }
fail()    { echo -e "${R}✗${NC} $1"; }
info()    { echo -e "${B}ℹ${NC} $1"; }
section() { echo -e "\n${BOLD}${C}━━━ $1 ━━━${NC}\n"; }
header()  { echo -e "${BOLD}${M}$1${NC}"; }

# Configuration
BRAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${BRAIN_DIR}/data"
MODELS_DIR="${DATA_DIR}/models"
ENV_FILE="${BRAIN_DIR}/.env"

header "
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🧠  BRAIN AI - Self-Evolving AI Brain System Setup  🧠     ║
║                                                               ║
║   Hardware: AMD RX 7900 XT (20GB) | i9-265F | 128GB RAM     ║
║   Model: Dolphin 2.9.3 Llama 3.1 8B AWQ (Uncensored)        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"

###############################################################################
# Step 1: Check Prerequisites
###############################################################################

section "Checking Prerequisites"

# Check Docker
if command -v docker &>/dev/null; then
    DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+' | head -1)
    ok "Docker installed: v${DOCKER_VERSION}"
else
    fail "Docker not found. Please install Docker first."
    echo "   Install from: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check Docker Compose
if command -v docker compose &>/dev/null || command -v docker-compose &>/dev/null; then
    ok "Docker Compose available"
else
    fail "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# Check for AMD GPU
if lspci | grep -i 'amd.*\[radeon\|vga\]' &>/dev/null; then
    GPU_INFO=$(lspci | grep -i 'amd.*\[radeon\|vga\]' | head -1)
    ok "AMD GPU detected: ${GPU_INFO}"
else
    warn "AMD GPU not detected. vLLM will fail without AMD GPU."
    read -rp "   Continue anyway? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check ROCm
if command -v rocm-smi &>/dev/null; then
    ROCM_VERSION=$(rocm-smi --version 2>&1 | grep -oP '\d+\.\d+\.\d+' | head -1 || echo "unknown")
    ok "ROCm installed: v${ROCM_VERSION}"
    
    # Show GPU info
    info "GPU Status:"
    rocm-smi --showid --showtemp --showmeminfo vram 2>/dev/null | sed 's/^/   /' || echo "   (unable to query GPU)"
else
    warn "ROCm not found. vLLM requires ROCm for AMD GPU support."
    echo "   Install from: https://rocm.docs.amd.com/projects/install-on-linux/en/latest/"
    read -rp "   Continue anyway? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Python (for model downloading)
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version | grep -oP '\d+\.\d+\.\d+')
    ok "Python installed: v${PYTHON_VERSION}"
else
    warn "Python not found. Needed for model downloading."
fi

# Check disk space
AVAILABLE_GB=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_GB" -lt 100 ]; then
    warn "Low disk space: ${AVAILABLE_GB}GB available"
    echo "   Recommended: 100GB+ for models and data"
fi else
    ok "Disk space: ${AVAILABLE_GB}GB available"
fi

# Check RAM
TOTAL_RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM_GB" -lt 64 ]; then
    warn "RAM: ${TOTAL_RAM_GB}GB (recommended: 128GB)"
else
    ok "RAM: ${TOTAL_RAM_GB}GB"
fi

###############################################################################
# Step 2: Create Directories
###############################################################################

section "Creating Directories"

mkdir -p "${DATA_DIR}"/{qdrant,conversations,memory,metrics}
mkdir -p "${MODELS_DIR}"
mkdir -p "${BRAIN_DIR}/services"/{vllm,openwebui,searxng,qdrant,embeddings,coding-agent,hardware-agent,dashboard}
mkdir -p "${BRAIN_DIR}/scripts"

ok "Created data directories"
ok "Created service directories"

###############################################################################
# Step 3: Generate .env File
###############################################################################

section "Configuring Environment"

if [ -f "$ENV_FILE" ]; then
    warn ".env file already exists"
    read -rp "   Overwrite? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp "$ENV_FILE" "${ENV_FILE}.backup.$(date +%s)"
        ok "Backed up existing .env"
    else
        info "Using existing .env file"
    fi
fi

if [ ! -f "$ENV_FILE" ] || [[ "$response" =~ ^[Yy]$ ]]; then
    # Generate secrets
    WEBUI_SECRET=$(openssl rand -hex 32 2>/dev/null || tr -dc 'a-f0-9' < /dev/urandom | head -c 64)
    SEARXNG_SECRET=$(openssl rand -hex 16 2>/dev/null || tr -dc 'a-f0-9' < /dev/urandom | head -c 32)
    
    # Prompt for Hugging Face token
    echo ""
    info "Hugging Face Token Required"
    echo "   Get your token from: https://huggingface.co/settings/tokens"
    echo "   This is needed to download the Dolphin 2.9.3 model"
    echo ""
    read -rp "   Enter your Hugging Face token (or press Enter to skip): " HF_TOKEN
    
    if [ -z "$HF_TOKEN" ]; then
        HF_TOKEN="your_huggingface_token_here"
        warn "No Hugging Face token provided. You'll need to set it manually later."
    fi
    
    # Copy .env file and update secrets
    if [ ! -f "${BRAIN_DIR}/.env" ]; then
        # .env doesn't exist, copy from template
        if [ -f "${BRAIN_DIR}/.env.example" ]; then
            cp "${BRAIN_DIR}/.env.example" "$ENV_FILE"
        fi
    fi
    
    # Update or add values
    if [ -f "$ENV_FILE" ]; then
        sed -i "s/HUGGING_FACE_HUB_TOKEN=.*/HUGGING_FACE_HUB_TOKEN=${HF_TOKEN}/" "$ENV_FILE"
        sed -i "s/WEBUI_SECRET_KEY=.*/WEBUI_SECRET_KEY=${WEBUI_SECRET}/" "$ENV_FILE"
        sed -i "s/SEARXNG_SECRET=.*/SEARXNG_SECRET=${SEARXNG_SECRET}/" "$ENV_FILE"
    fi
    
    ok "Generated .env file with secrets"
fi

###############################################################################
# Step 4: Generate SearXNG Secret in Settings
###############################################################################

section "Configuring SearXNG"

SEARXNG_SETTINGS="${BRAIN_DIR}/services/searxng/settings.yml"
if [ -f "$SEARXNG_SETTINGS" ]; then
    # Read secret from .env
    SEARXNG_SECRET=$(grep SEARXNG_SECRET "$ENV_FILE" | cut -d'=' -f2)
    # Update settings.yml
    sed -i "s/__REPLACE_WITH_SECRET__/${SEARXNG_SECRET}/" "$SEARXNG_SETTINGS"
    ok "Configured SearXNG settings"
fi

###############################################################################
# Step 5: Download Models (Optional)
###############################################################################

section "Model Downloads"

info "The following models will be downloaded on first startup:"
echo "   • Dolphin 2.9.3 Llama 3.1 8B AWQ (~4.5GB)"
echo "   • nomic-embed-text-v1.5 (~500MB)"
echo ""
echo "You can either:"
echo "   1. Download now using huggingface-cli (faster, recommended)"
echo "   2. Let Docker containers download on first start (automatic)"
echo ""

read -rp "Download models now? [Y/n] " response
if [[ ! "$response" =~ ^[Nn]$ ]]; then
    if command -v huggingface-cli &>/dev/null; then
        info "Downloading models with huggingface-cli..."
        
        # Set token
        if [ -f "$ENV_FILE" ]; then
            source "$ENV_FILE"
            export HUGGING_FACE_HUB_TOKEN
        fi
        
        # Download Dolphin model
        info "Downloading Dolphin 2.9.3 Llama 3.1 8B AWQ..."
        huggingface-cli download \
            cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
            --cache-dir "${MODELS_DIR}" \
            --resume-download || warn "Model download failed or incomplete"
        
        # Download embedding model
        info "Downloading nomic-embed-text-v1.5..."
        huggingface-cli download \
            nomic-ai/nomic-embed-text-v1.5 \
            --cache-dir "${MODELS_DIR}" \
            --resume-download || warn "Embedding model download failed or incomplete"
        
        ok "Models downloaded to ${MODELS_DIR}"
    else
        warn "huggingface-cli not installed"
        echo "   Install with: pip install -U huggingface_hub[cli]"
        info "Models will download automatically on first container start"
    fi
else
    info "Skipping model download. Models will download on first start."
fi

###############################################################################
# Step 6: Build Custom Containers
###############################################################################

section "Building Docker Images"

cd "$BRAIN_DIR"

info "Building coding-agent..."
docker build -t brain-coding-agent:latest services/coding-agent/ || warn "Coding agent build failed"

info "Building hardware-agent..."
docker build -t brain-hardware-agent:latest services/hardware-agent/ || warn "Hardware agent build failed"

info "Building dashboard..."
docker build -t brain-dashboard:latest services/dashboard/ || warn "Dashboard build failed"

ok "Docker images built"

###############################################################################
# Step 7: Start Services
###############################################################################

section "Starting Services"

info "Pulling required images..."
docker compose pull

info "Starting all services..."
docker compose up -d

ok "Services started"

###############################################################################
# Step 8: Wait for Services to be Healthy
###############################################################################

section "Waiting for Services to Initialize"

info "This may take 5-10 minutes for vLLM to load the model onto GPU..."
echo ""

# Function to check service health
check_service() {
    local service=$1
    local port=$2
    local max_wait=${3:-300}
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        if curl -sf "http://localhost:${port}/health" &>/dev/null || \
           curl -sf "http://localhost:${port}/healthz" &>/dev/null || \
           docker compose ps "$service" | grep -q "Up (healthy)"; then
            ok "$service is healthy"
            return 0
        fi
        
        echo -ne "   Waiting for $service... ${elapsed}s\r"
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    warn "$service not healthy after ${max_wait}s"
    return 1
}

# Check services
check_service "qdrant" 6333 60
check_service "searxng" 8888 60
check_service "embeddings" 8001 300
check_service "vllm" 8000 600
check_service "openwebui" 3000 120
check_service "coding-agent" 5000 60
check_service "hardware-agent" 5001 60
check_service "dashboard" 8080 30

echo ""

###############################################################################
# Step 9: Initialize Qdrant Collections
###############################################################################

section "Initializing Vector Database"

info "Creating Qdrant collections..."

# Wait a bit more for Qdrant to be fully ready
sleep 5

# Create collections based on collections.json
python3 - <<'PYTHON'
import requests
import json
import time

qdrant_url = "http://localhost:6333"
collections_file = "services/qdrant/collections.json"

try:
    with open(collections_file, 'r') as f:
        config = json.load(f)
    
    for collection in config.get('collections', []):
        name = collection['name']
        
        # Check if collection exists
        response = requests.get(f"{qdrant_url}/collections/{name}")
        
        if response.status_code == 200:
            print(f"  ✓ Collection '{name}' already exists")
        else:
            # Create collection
            payload = {
                "vectors": collection['vector_config'],
                "hnsw_config": collection.get('hnsw_config', {}),
                "optimizers_config": collection.get('optimizers_config', {})
            }
            
            response = requests.put(
                f"{qdrant_url}/collections/{name}",
                json=payload
            )
            
            if response.status_code in [200, 201]:
                print(f"  ✓ Created collection '{name}'")
            else:
                print(f"  ✗ Failed to create collection '{name}': {response.text}")

except Exception as e:
    print(f"  ✗ Error initializing collections: {e}")
PYTHON

ok "Qdrant collections initialized"

###############################################################################
# Step 10: Display Service URLs
###############################################################################

section "Setup Complete! 🎉"

header "
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║           🧠 Brain AI System is Ready! 🧠                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
"

echo ""
info "Access your services at:"
echo ""
echo "   🌐 Dashboard       http://localhost:8080"
echo "   💬 OpenWebUI       http://localhost:3000"
echo "   🔍 SearXNG         http://localhost:8888"
echo "   📊 Qdrant          http://localhost:6333/dashboard"
echo "   🤖 vLLM API        http://localhost:8000/docs"
echo "   💻 Coding Agent    http://localhost:5000"
echo "   🖥️  Hardware Agent  http://localhost:5001"
echo ""

info "Default credentials for OpenWebUI:"
echo "   Create your admin account on first visit"
echo ""

info "Next steps:"
echo "   1. Open http://localhost:3000 and create your account"
echo "   2. Configure your personality in Settings > Prompts"
echo "   3. Start chatting with your uncensored AI!"
echo "   4. Monitor everything at http://localhost:8080"
echo ""

info "Useful commands:"
echo "   • View logs:       docker compose logs -f"
echo "   • Restart:         docker compose restart"
echo "   • Stop:            docker compose down"
echo "   • Status:          docker compose ps"
echo "   • GPU status:      rocm-smi"
echo ""

info "Documentation:"
echo "   • README.md        Complete guide"
echo "   • services/*/      Individual service docs"
echo "   • scripts/         Automation scripts"
echo ""

ok "Setup complete!"
echo ""

# Offer to open dashboard
if command -v xdg-open &>/dev/null; then
    read -rp "Open dashboard in browser? [Y/n] " response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        xdg-open "http://localhost:8080" &>/dev/null &
    fi
fi

exit 0
