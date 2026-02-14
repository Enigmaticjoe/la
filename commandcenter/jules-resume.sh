#!/bin/bash
################################################################################
# JULES PROTOCOL - RESUME/FIX INSTALLER
# Handles port conflicts and resumes failed installations
#
# Usage: sudo bash jules-resume.sh
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

INSTALL_DIR="/opt/jules-protocol"

info() { echo -e "${BLUE}ℹ${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warning() { echo -e "${YELLOW}⚠${NC} $*"; }
error() { echo -e "${RED}✗${NC} $*"; }

banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════╗"
    echo "║  🔧 JULES PROTOCOL RESUME/FIX INSTALLER 🔧   ║"
    echo "╚════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

################################################################################
# Port Conflict Resolution
################################################################################

find_port_conflicts() {
    info "Checking for port conflicts..."

    local ports=("11434:Ollama" "6333:Qdrant" "5432:PostgreSQL" "6379:Redis")
    local conflicts=()

    for port_info in "${ports[@]}"; do
        local port="${port_info%%:*}"
        local service="${port_info##*:}"

        if lsof -i ":$port" -sTCP:LISTEN &>/dev/null || ss -tuln | grep -q ":$port "; then
            warning "Port $port ($service) is in use"

            # Find what's using it
            local user_process=$(lsof -i ":$port" -sTCP:LISTEN 2>/dev/null | tail -1 || echo "unknown")
            if [[ "$user_process" != "unknown" ]]; then
                info "  └─ Used by: $user_process"
            fi

            conflicts+=("$port:$service")
        fi
    done

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        success "No port conflicts found"
        return 0
    fi

    return 1
}

resolve_port_conflicts() {
    info "Resolving port conflicts..."

    # Find containers using the ports
    local conflicting_containers=$(docker ps -a --format '{{.Names}}' | grep -E 'qdrant|ollama|postgres|redis' | grep -v '^jules_' || true)

    if [[ -n "$conflicting_containers" ]]; then
        warning "Found non-Jules containers using the ports:"
        echo "$conflicting_containers"
        echo ""
        read -p "Stop and remove these containers? (y/n): " REMOVE

        if [[ "$REMOVE" =~ ^[Yy]$ ]]; then
            echo "$conflicting_containers" | while read container; do
                info "Stopping $container..."
                docker stop "$container" 2>/dev/null || true
                docker rm "$container" 2>/dev/null || true
            done
            success "Conflicting containers removed"
        else
            error "Cannot proceed with port conflicts"
            exit 1
        fi
    fi

    # Check for system services
    if systemctl is-active --quiet ollama 2>/dev/null; then
        warning "Ollama system service is running"
        read -p "Stop Ollama system service? (y/n): " STOP_OLLAMA

        if [[ "$STOP_OLLAMA" =~ ^[Yy]$ ]]; then
            systemctl stop ollama
            systemctl disable ollama
            success "Ollama system service stopped"
        fi
    fi
}

################################################################################
# Check Installation State
################################################################################

check_installation_state() {
    info "Checking installation state..."

    # Check if directory exists
    if [[ ! -d "$INSTALL_DIR" ]]; then
        error "Installation directory not found: $INSTALL_DIR"
        error "Run the main installer first: jules-install-standalone.sh"
        exit 1
    fi
    success "Installation directory exists"

    # Check if docker-compose.yml exists
    if [[ ! -f "$INSTALL_DIR/docker-compose.yml" ]]; then
        error "docker-compose.yml not found"
        error "Run the main installer first"
        exit 1
    fi
    success "Docker Compose file exists"

    # Check containers
    local created_containers=$(docker ps -a --format '{{.Names}}' | grep '^jules_' | wc -l)
    info "Found $created_containers Jules containers"

    # Check running containers
    local running_containers=$(docker ps --format '{{.Names}}' | grep '^jules_' | wc -l)
    info "Found $running_containers running Jules containers"

    # Check volumes
    local volumes=$(docker volume ls --format '{{.Name}}' | grep 'jules-protocol' | wc -l)
    info "Found $volumes Jules volumes"
}

################################################################################
# Fix and Restart
################################################################################

fix_and_restart() {
    info "Fixing installation..."

    cd "$INSTALL_DIR"

    # Stop all Jules containers
    info "Stopping all Jules containers..."
    docker compose down 2>/dev/null || true
    sleep 2

    # Remove any stuck containers
    info "Cleaning up stuck containers..."
    docker ps -a --format '{{.Names}}' | grep '^jules_' | while read container; do
        docker rm -f "$container" 2>/dev/null || true
    done

    # Resolve port conflicts
    if ! find_port_conflicts; then
        resolve_port_conflicts
    fi

    # Restart services
    info "Starting services..."
    docker compose up -d

    # Wait for health
    info "Waiting for services to be healthy (up to 60 seconds)..."
    local waited=0
    while [[ $waited -lt 60 ]]; do
        local healthy=$(docker ps --filter "name=jules_" --format '{{.Status}}' | grep -c "(healthy)" || echo "0")
        local total=$(docker ps --filter "name=jules_" --format '{{.Names}}' | wc -l)

        if [[ $healthy -eq $total ]] && [[ $total -gt 0 ]]; then
            success "All $total services are healthy"
            break
        fi

        echo -n "."
        sleep 3
        ((waited+=3))
    done
    echo ""

    if [[ $waited -ge 60 ]]; then
        warning "Some services may not be healthy yet"
        info "Check status with: docker compose -f $INSTALL_DIR/docker-compose.yml ps"
    fi
}

################################################################################
# Check Models
################################################################################

check_and_pull_models() {
    info "Checking AI models..."

    # Wait for Ollama to be ready
    sleep 5

    # Check if Ollama is accessible
    if ! docker exec jules_ollama ollama list &>/dev/null; then
        warning "Ollama not ready yet, skipping model check"
        info "Pull models manually later:"
        echo "  docker exec jules_ollama ollama pull llama3.2"
        echo "  docker exec jules_ollama ollama pull llama3.1:8b"
        return 0
    fi

    local existing_models=$(docker exec jules_ollama ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

    # Check llama3.2
    if echo "$existing_models" | grep -q "llama3.2"; then
        success "llama3.2 already installed"
    else
        info "Pulling llama3.2..."
        if docker exec jules_ollama ollama pull llama3.2; then
            success "llama3.2 installed"
        else
            warning "Failed to pull llama3.2 (check network)"
        fi
    fi

    # Check llama3.1:8b
    if echo "$existing_models" | grep -q "llama3.1:8b"; then
        success "llama3.1:8b already installed"
    else
        info "Pulling llama3.1:8b..."
        if docker exec jules_ollama ollama pull llama3.1:8b; then
            success "llama3.1:8b installed"
        else
            warning "Failed to pull llama3.1:8b (check network)"
        fi
    fi
}

################################################################################
# Verify CLI Command
################################################################################

verify_cli() {
    if [[ ! -f /usr/local/bin/jules ]]; then
        info "Creating 'jules' CLI command..."
        cat > /usr/local/bin/jules << 'CLI_EOF'
#!/bin/bash
docker exec -it jules_aishell python3 /app/aishell.py
CLI_EOF
        chmod +x /usr/local/bin/jules
        success "CLI command created"
    else
        success "CLI command already exists"
    fi
}

################################################################################
# Show Status
################################################################################

show_status() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD} JULES PROTOCOL STATUS${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════${NC}"
    echo ""

    docker compose -f "$INSTALL_DIR/docker-compose.yml" ps

    echo ""
    echo "Models Installed:"
    docker exec jules_ollama ollama list 2>/dev/null | tail -n +2 || echo "  (Ollama not ready)"

    echo ""
    echo "Quick Start:"
    echo -e "  ${CYAN}jules${NC}                    # Access AI Shell"
    echo ""
    echo "Troubleshooting:"
    echo "  docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
    echo "  docker compose -f $INSTALL_DIR/docker-compose.yml restart"
    echo "  docker exec jules_ollama ollama pull llama3.2"
    echo ""
}

################################################################################
# Main
################################################################################

main() {
    banner

    if [[ $EUID -ne 0 ]]; then
        error "Must run as root (use sudo)"
        exit 1
    fi

    check_installation_state
    fix_and_restart
    check_and_pull_models
    verify_cli
    show_status

    echo -e "${GREEN}✓${NC} Jules Protocol is ready!"
    echo ""
}

main
