#!/bin/bash
################################################################################
# Health Check Script for Open WebUI
# Monitors the health of all services
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
INSTALL_DIR="${INSTALL_DIR:-${HOME}/open-webui}"

echo "================================================"
echo "   Open WebUI Health Check"
echo "================================================"
echo ""

EXIT_CODE=0

# Check if Docker is running
check_docker() {
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Docker daemon is running"
        return 0
    else
        echo -e "${RED}✗${NC} Docker daemon is NOT running"
        return 1
    fi
}

# Check container status
check_container() {
    local CONTAINER_NAME=$1
    local STATUS
    
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null)
        if [ "$STATUS" == "running" ]; then
            echo -e "${GREEN}✓${NC} Container $CONTAINER_NAME is running"
            return 0
        else
            echo -e "${RED}✗${NC} Container $CONTAINER_NAME status: $STATUS"
            return 1
        fi
    else
        echo -e "${RED}✗${NC} Container $CONTAINER_NAME is NOT running"
        return 1
    fi
}

# Check service health
check_service_health() {
    local SERVICE_NAME=$1
    local URL=$2
    
    if curl -sf "$URL" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Service $SERVICE_NAME is healthy"
        return 0
    else
        echo -e "${RED}✗${NC} Service $SERVICE_NAME is NOT responding"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    local INSTALL_DIR=$1
    local USAGE
    USAGE=$(df -h "$INSTALL_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$USAGE" -lt 80 ]; then
        echo -e "${GREEN}✓${NC} Disk usage: ${USAGE}%"
        return 0
    elif [ "$USAGE" -lt 90 ]; then
        echo -e "${YELLOW}⚠${NC} Disk usage: ${USAGE}% (warning)"
        return 0
    else
        echo -e "${RED}✗${NC} Disk usage: ${USAGE}% (critical)"
        return 1
    fi
}

# Check memory usage
check_memory() {
    local CONTAINER_NAME=$1
    local MEM_USAGE
    
    MEM_USAGE=$(docker stats --no-stream --format "{{.MemPerc}}" "$CONTAINER_NAME" 2>/dev/null | sed 's/%//')
    
    if [ -n "$MEM_USAGE" ]; then
        echo -e "${BLUE}ℹ${NC} Container $CONTAINER_NAME memory usage: ${MEM_USAGE}%"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Could not get memory usage for $CONTAINER_NAME"
        return 0
    fi
}

# Main health checks
echo "Docker Status:"
check_docker || EXIT_CODE=1
echo ""

echo "Container Status:"
check_container "open-webui" || EXIT_CODE=1
check_container "ollama" || EXIT_CODE=1
check_container "chromadb" || EXIT_CODE=1
check_container "pipelines" || EXIT_CODE=1
echo ""

echo "Service Health:"
check_service_health "Open WebUI" "http://localhost:3000" || EXIT_CODE=1
check_service_health "Ollama" "http://localhost:11434" || EXIT_CODE=1
check_service_health "ChromaDB" "http://localhost:8000/api/v1/heartbeat" || EXIT_CODE=1
check_service_health "Pipelines" "http://localhost:9099" || EXIT_CODE=1
echo ""

echo "Resource Usage:"
check_disk_space "$INSTALL_DIR" || EXIT_CODE=1
check_memory "open-webui"
check_memory "ollama"
echo ""

# Show Docker volume sizes
echo "Volume Sizes:"
docker system df -v 2>/dev/null | grep -E "(open-webui|ollama|chromadb)" || true
echo ""

# Summary
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}[SUCCESS]${NC} All health checks passed"
else
    echo -e "${RED}[ERROR]${NC} Some health checks failed"
    echo ""
    echo "Troubleshooting:"
    echo "  • Check logs: docker logs <container-name>"
    echo "  • Restart services: cd $INSTALL_DIR && docker compose restart"
    echo "  • Full restart: cd $INSTALL_DIR && docker compose down && docker compose up -d"
fi

exit $EXIT_CODE
