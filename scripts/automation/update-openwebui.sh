#!/bin/bash
################################################################################
# Update Script for Open WebUI
# Updates Docker images and pulls latest models
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${INSTALL_DIR:-${HOME}/open-webui}"

echo "================================================"
echo "   Open WebUI Update Script"
echo "================================================"
echo ""

echo -e "${BLUE}[INFO]${NC} Installation directory: $INSTALL_DIR"
echo ""

# Change to installation directory
cd "$INSTALL_DIR"

# Create backup before update
echo -e "${BLUE}[INFO]${NC} Creating backup before update..."
BACKUP_DIR="$INSTALL_DIR/backups"
mkdir -p "$BACKUP_DIR"

if [ -f "../scripts/automation/backup-openwebui.sh" ]; then
    bash ../scripts/automation/backup-openwebui.sh
else
    echo -e "${YELLOW}[WARNING]${NC} Backup script not found, skipping backup"
fi

echo ""

# Pull latest images
echo -e "${BLUE}[INFO]${NC} Pulling latest Docker images..."
if docker compose version >/dev/null 2>&1; then
    docker compose pull
else
    docker-compose pull
fi

echo ""

# Restart services
echo -e "${BLUE}[INFO]${NC} Restarting services with new images..."
if docker compose version >/dev/null 2>&1; then
    docker compose up -d
else
    docker-compose up -d
fi

echo ""

# Wait for services
echo -e "${BLUE}[INFO]${NC} Waiting for services to be ready..."
sleep 10

# Check if services are running
if curl -sf http://localhost:3000 >/dev/null 2>&1; then
    echo -e "${GREEN}[SUCCESS]${NC} Open WebUI is running"
else
    echo -e "${YELLOW}[WARNING]${NC} Open WebUI may not be ready yet"
fi

echo ""

# Update models
echo -e "${BLUE}[INFO]${NC} Updating Ollama models..."
MODELS=$(docker exec ollama ollama list | tail -n +2 | awk '{print $1}' | grep -v '^$' || true)

if [ -n "$MODELS" ]; then
    while IFS= read -r model; do
        echo -e "${BLUE}[INFO]${NC} Updating model: $model"
        docker exec ollama ollama pull "$model" || echo -e "${YELLOW}[WARNING]${NC} Failed to update $model"
    done <<< "$MODELS"
else
    echo -e "${YELLOW}[WARNING]${NC} No models found to update"
fi

echo ""

# Clean up old images
echo -e "${BLUE}[INFO]${NC} Cleaning up old Docker images..."
docker image prune -f

echo ""
echo -e "${GREEN}[SUCCESS]${NC} Update complete!"
echo ""
echo "Next steps:"
echo "  1. Test Open WebUI at http://localhost:3000"
echo "  2. Check logs if needed: docker logs open-webui"
echo ""
