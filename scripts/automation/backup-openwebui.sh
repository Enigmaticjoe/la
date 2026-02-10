#!/bin/bash
################################################################################
# Backup Script for Open WebUI
# Creates backups of data, configurations, and models
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${INSTALL_DIR:-${HOME}/open-webui}"
BACKUP_DIR="${BACKUP_DIR:-${INSTALL_DIR}/backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="openwebui_backup_${TIMESTAMP}"

echo "================================================"
echo "   Open WebUI Backup Script"
echo "================================================"
echo ""

echo -e "${BLUE}[INFO]${NC} Installation directory: $INSTALL_DIR"
echo -e "${BLUE}[INFO]${NC} Backup directory: $BACKUP_DIR"
echo -e "${BLUE}[INFO]${NC} Backup name: $BACKUP_NAME"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup configurations
echo -e "${BLUE}[INFO]${NC} Backing up configurations..."
if [ -d "$INSTALL_DIR/configs" ]; then
    cp -r "$INSTALL_DIR/configs" "$BACKUP_DIR/$BACKUP_NAME/"
fi
if [ -f "$INSTALL_DIR/.env" ]; then
    cp "$INSTALL_DIR/.env" "$BACKUP_DIR/$BACKUP_NAME/"
fi
if [ -f "$INSTALL_DIR/docker-compose.yml" ]; then
    cp "$INSTALL_DIR/docker-compose.yml" "$BACKUP_DIR/$BACKUP_NAME/"
fi

# Backup Docker volumes
echo -e "${BLUE}[INFO]${NC} Backing up Docker volumes..."
cd "$INSTALL_DIR"

if docker compose ps -q open-webui >/dev/null 2>&1 || docker-compose ps -q open-webui >/dev/null 2>&1; then
    # Export Open WebUI data
    docker run --rm \
        -v open-webui-data:/data \
        -v "$BACKUP_DIR/$BACKUP_NAME":/backup \
        alpine tar czf /backup/open-webui-data.tar.gz -C /data .
    
    # Export Ollama models
    docker run --rm \
        -v ollama-data:/data \
        -v "$BACKUP_DIR/$BACKUP_NAME":/backup \
        alpine tar czf /backup/ollama-data.tar.gz -C /data .
    
    # Export ChromaDB data
    docker run --rm \
        -v chromadb-data:/data \
        -v "$BACKUP_DIR/$BACKUP_NAME":/backup \
        alpine tar czf /backup/chromadb-data.tar.gz -C /data .
fi

# Create backup archive
echo -e "${BLUE}[INFO]${NC} Creating backup archive..."
cd "$BACKUP_DIR"
tar czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)

echo ""
echo -e "${GREEN}[SUCCESS]${NC} Backup complete!"
echo ""
echo "Backup location: $BACKUP_DIR/${BACKUP_NAME}.tar.gz"
echo "Backup size: $BACKUP_SIZE"
echo ""

# Clean old backups (keep last 7)
echo -e "${BLUE}[INFO]${NC} Cleaning old backups (keeping last 7)..."
cd "$BACKUP_DIR"
ls -t openwebui_backup_*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true

echo -e "${GREEN}[SUCCESS]${NC} Backup process complete!"
