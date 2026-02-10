#!/bin/bash
################################################################################
# unRAID Brawn Deployment Script (192.168.1.222)
# Automated deployment for the unRAID Brawn system
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "================================================"
echo "   unRAID Brawn Deployment (192.168.1.222)"
echo "================================================"
echo ""

# Configuration
INSTALL_DIR="/mnt/user/appdata/open-webui"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../.. && pwd)"

echo -e "${BLUE}[INFO]${NC} Using installation directory: $INSTALL_DIR"
echo -e "${BLUE}[INFO]${NC} Using source directory: $SCRIPT_DIR"
echo ""

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
echo -e "${BLUE}[INFO]${NC} Copying configuration files..."
cp "$SCRIPT_DIR/docker-compose-gpu.yml" "$INSTALL_DIR/docker-compose.yml"
cp "$SCRIPT_DIR/.env.example" "$INSTALL_DIR/.env.example"
mkdir -p "$INSTALL_DIR/configs"/{functions,pipelines}

# Create .env if it doesn't exist
if [ ! -f "$INSTALL_DIR/.env" ]; then
    echo -e "${BLUE}[INFO]${NC} Creating .env file..."
    SECRET_KEY=$(openssl rand -base64 32 2>/dev/null || echo "unraid-secret-key-change-me")
    cat > "$INSTALL_DIR/.env" << EOF
WEBUI_SECRET_KEY=$SECRET_KEY
DEFAULT_MODEL=llama3.2:latest
OLLAMA_KEEP_ALIVE=24h
OLLAMA_MAX_LOADED_MODELS=5
OLLAMA_NUM_GPU=1
RAG_EMBEDDING_MODEL=nomic-embed-text
ENABLE_RAG_WEB_SEARCH=true
EOF
fi

# Check for NVIDIA plugin
echo -e "${BLUE}[INFO]${NC} Checking for NVIDIA support..."
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}[WARNING]${NC} NVIDIA drivers not detected"
    echo -e "${YELLOW}[WARNING]${NC} Please install the NVIDIA Driver plugin from Community Applications"
fi

# Start services
echo -e "${BLUE}[INFO]${NC} Starting services..."
cd "$INSTALL_DIR"

# Check if docker compose is available
if docker compose version &> /dev/null; then
    docker compose pull
    docker compose up -d
elif command -v docker-compose &> /dev/null; then
    docker-compose pull
    docker-compose up -d
else
    echo -e "${YELLOW}[WARNING]${NC} Docker Compose not found"
    echo "Please use Portainer to deploy the stack"
    echo "Stack file location: $INSTALL_DIR/docker-compose.yml"
    exit 0
fi

# Wait for services
echo -e "${BLUE}[INFO]${NC} Waiting for services to be ready..."
sleep 15

# Pull models
echo -e "${BLUE}[INFO]${NC} Pulling AI models..."
docker exec ollama ollama pull llama3.2:latest || true
docker exec ollama ollama pull nomic-embed-text || true

echo ""
echo -e "${GREEN}[SUCCESS]${NC} unRAID Brawn deployment complete!"
echo ""
echo "Access Open WebUI at:"
echo "  • http://192.168.1.222:3000"
echo "  • http://$(hostname):3000"
echo ""
echo "Manage via Portainer at:"
echo "  • http://192.168.1.222:9000"
echo ""
