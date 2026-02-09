#!/bin/bash
################################################################################
# Brain PC Deployment Script (192.168.1.9)
# Automated deployment for the Brain PC system
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "================================================"
echo "   Brain PC Deployment (192.168.1.9)"
echo "================================================"
echo ""

# Configuration
INSTALL_DIR="${HOME}/open-webui"
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
    SECRET_KEY=$(openssl rand -base64 32)
    cat > "$INSTALL_DIR/.env" << EOF
WEBUI_SECRET_KEY=$SECRET_KEY
DEFAULT_MODEL=llama3.2:latest
OLLAMA_KEEP_ALIVE=24h
OLLAMA_MAX_LOADED_MODELS=3
OLLAMA_NUM_GPU=1
RAG_EMBEDDING_MODEL=nomic-embed-text
ENABLE_RAG_WEB_SEARCH=true
EOF
fi

# Start services
echo -e "${BLUE}[INFO]${NC} Starting services..."
cd "$INSTALL_DIR"
docker compose pull
docker compose up -d

# Wait for services
echo -e "${BLUE}[INFO]${NC} Waiting for services to be ready..."
sleep 10

# Pull models
echo -e "${BLUE}[INFO]${NC} Pulling AI models..."
docker exec ollama ollama pull llama3.2:latest || true
docker exec ollama ollama pull nomic-embed-text || true

echo ""
echo -e "${GREEN}[SUCCESS]${NC} Brain PC deployment complete!"
echo ""
echo "Access Open WebUI at:"
echo "  • http://localhost:3000"
echo "  • http://192.168.1.9:3000"
echo ""
