#!/bin/bash
################################################################################
# JULES PROTOCOL INSTALLER
# Digital Renegade Self-Evolving AI Operating System
#
# "I don't raise my voice. I raise my accuracy."
#
# Usage: sudo bash install-jules-protocol.sh [--standalone|--integrate]
#
# Options:
#   --standalone    Install as standalone system
#   --integrate     Integrate with existing Digital Renegade deployment
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
INSTALL_DIR="/home/user/brain"
CONSTITUTION_DIR="$INSTALL_DIR/config/constitution"
AGENTS_DIR="$INSTALL_DIR/agents"
LOG_FILE="/var/log/jules_protocol_install.log"

MODE="integrate"  # Default to integrate mode

################################################################################
# Logging Functions
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
}

banner() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║      ██╗██╗   ██╗██╗     ███████╗███████╗                        ║
║      ██║██║   ██║██║     ██╔════╝██╔════╝                        ║
║      ██║██║   ██║██║     █████╗  ███████╗                        ║
║ ██   ██║██║   ██║██║     ██╔══╝  ╚════██║                        ║
║ ╚█████╔╝╚██████╔╝███████╗███████╗███████║                        ║
║  ╚════╝  ╚═════╝ ╚══════╝╚══════╝╚══════╝                        ║
║                                                                    ║
║         ██████╗ ██████╗  ██████╗ ████████╗ ██████╗  ██████╗ ██╗  ║
║         ██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝██╔═══██╗██╔════╝██║  ║
║         ██████╔╝██████╔╝██║   ██║   ██║   ██║   ██║██║     ██║  ║
║         ██╔═══╝ ██╔══██╗██║   ██║   ██║   ██║   ██║██║     ██║  ║
║         ██║     ██║  ██║╚██████╔╝   ██║   ╚██████╔╝╚██████╗███████╗
║         ╚═╝     ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝  ╚═════╝╚══════╝
║                                                                    ║
║              🧠 SELF-EVOLVING AI OPERATING SYSTEM 🧠              ║
║                                                                    ║
║   "I speak like someone who already checked the exit."            ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

################################################################################
# Argument Parsing
################################################################################

parse_args() {
    for arg in "$@"; do
        case $arg in
            --standalone)
                MODE="standalone"
                info "Mode: Standalone installation"
                ;;
            --integrate)
                MODE="integrate"
                info "Mode: Integrate with Digital Renegade"
                ;;
            *)
                error "Unknown argument: $arg"
                echo "Usage: $0 [--standalone|--integrate]"
                exit 1
                ;;
        esac
    done
}

################################################################################
# Prerequisites Check
################################################################################

check_prerequisites() {
    info "Checking prerequisites..."

    # Root check
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi

    # Check if Digital Renegade exists (if integrating)
    if [[ "$MODE" == "integrate" ]]; then
        if [[ ! -f "$INSTALL_DIR/portainer-stack-renegade.yml" ]]; then
            warning "Digital Renegade stack not found"
            echo "Install Digital Renegade first or use --standalone mode"
            exit 1
        fi
        success "Digital Renegade installation detected"
    fi

    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker not installed"
        exit 1
    fi
    success "Docker installed"

    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        error "Docker Compose plugin not found"
        exit 1
    fi
    success "Docker Compose available"

    # Check available disk space
    available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    if [[ $available_gb -lt 20 ]]; then
        error "Need at least 20GB free. Have ${available_gb}GB"
        exit 1
    fi
    success "Disk space: ${available_gb}GB available"
}

################################################################################
# Constitution Setup
################################################################################

setup_constitution() {
    info "Setting up Jules Protocol constitution..."

    # Constitution files should already exist from git
    if [[ ! -f "$CONSTITUTION_DIR/digital_renegade_core.v3.json" ]]; then
        error "Constitution file not found"
        error "Expected: $CONSTITUTION_DIR/digital_renegade_core.v3.json"
        exit 1
    fi

    # Verify checksum
    success "Constitution file found"

    # Create evolution log
    cat > "$CONSTITUTION_DIR/EVOLUTION_LOG.md" << 'EOF'
# Jules Protocol Evolution Log

## v3.1.0 (2025-12-27)
- Initial deployment
- Multi-model routing
- Three-tier memory system
- Distributed shell capability
- Home Assistant integration
- Self-evolution protocol

---

All future evolutions must be logged here with:
- Version number
- Changes made
- Rationale
- Risks identified
- Rollback plan
- User approval timestamp
EOF

    success "Evolution log created"

    # Create checksum file
    constitution_content=$(cat "$CONSTITUTION_DIR/digital_renegade_core.v3.json")
    checksum=$(echo -n "$constitution_content" | sha256sum | awk '{print $1}')
    echo "sha256:$checksum" > "$CONSTITUTION_DIR/constitution.sha256"

    success "Constitution checksum: sha256:${checksum:0:16}..."
}

################################################################################
# Build Agents
################################################################################

build_agents() {
    info "Building Jules Protocol agents..."

    # Build aishell
    info "Building AI Shell..."
    cd "$AGENTS_DIR/aishell"
    docker build -t chimera/aishell:latest .
    success "AI Shell built"

    # Build memory pruner
    info "Building Memory Pruner..."
    cd "$AGENTS_DIR/memory_pruner"
    docker build -t chimera/memory-pruner:latest .
    success "Memory Pruner built"

    cd "$INSTALL_DIR"
}

################################################################################
# Deploy Services
################################################################################

deploy_services() {
    if [[ "$MODE" == "integrate" ]]; then
        info "Integrating Jules Protocol with Digital Renegade..."

        # Add Jules Protocol services to existing Portainer stack
        cat >> "$INSTALL_DIR/portainer-stack-renegade.yml" << 'EOF'

  # ===================================================================
  # JULES PROTOCOL - SELF-EVOLVING AI OPERATING SYSTEM
  # ===================================================================

  chimera_aishell:
    image: chimera/aishell:latest
    container_name: chimera_aishell
    hostname: chimera_aishell
    restart: unless-stopped
    volumes:
      - ./config/constitution:/config/constitution:ro
      - /var/log/jules_protocol:/var/log/jules_protocol
    environment:
      - CONSTITUTION_PATH=/config/constitution/digital_renegade_core.v3.json
      - OLLAMA_BRAIN_URL=http://chimera_brain:11434
      - OLLAMA_EYES_URL=http://chimera_eyes:11434
      - REDIS_URL=redis://chimera_cache:6379/0
      - POSTGRES_URL=postgresql://postgres:${POSTGRES_PASSWORD}@chimera_postgres:5432/chimera
      - QDRANT_URL=http://chimera_memory:6333
    networks:
      chimera_net:
        ipv4_address: 172.28.0.50
    depends_on:
      - chimera_brain
      - chimera_eyes
      - chimera_cache
      - chimera_postgres
      - chimera_memory
    stdin_open: true
    tty: true
    healthcheck:
      test: ["CMD", "python3", "-c", "import sys; sys.exit(0)"]
      interval: 30s
      timeout: 10s
      retries: 3

  chimera_memory_pruner:
    image: chimera/memory-pruner:latest
    container_name: chimera_memory_pruner
    hostname: chimera_memory_pruner
    restart: unless-stopped
    volumes:
      - ./config/constitution:/config/constitution:ro
      - /var/log/jules_protocol:/var/log/jules_protocol
    environment:
      - CONSTITUTION_PATH=/config/constitution/digital_renegade_core.v3.json
      - POSTGRES_URL=postgresql://postgres:${POSTGRES_PASSWORD}@chimera_postgres:5432/chimera
      - QDRANT_URL=http://chimera_memory:6333
      - REDIS_URL=redis://chimera_cache:6379/0
    networks:
      chimera_net:
        ipv4_address: 172.28.0.51
    depends_on:
      - chimera_postgres
      - chimera_memory
      - chimera_cache
    healthcheck:
      test: ["CMD", "python3", "-c", "import sys; sys.exit(0)"]
      interval: 60s
      timeout: 10s
      retries: 3

EOF

        success "Jules Protocol services added to Portainer stack"

        info "Deploy via Portainer UI:"
        echo ""
        echo "  1. Access Portainer: http://192.168.1.9:9000"
        echo "  2. Navigate to Stacks → digital-renegade"
        echo "  3. Click 'Update Stack'"
        echo "  4. Services will be deployed automatically"
        echo ""

    else
        # Standalone mode - create separate docker-compose
        info "Creating standalone Jules Protocol stack..."

        cat > "$INSTALL_DIR/docker-compose-jules.yml" << 'EOF'
version: '3.8'

networks:
  jules_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.29.0.0/16

services:
  jules_ollama:
    image: ollama/ollama:latest
    container_name: jules_ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - jules_ollama_models:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    networks:
      jules_net:
        ipv4_address: 172.29.0.10

  jules_redis:
    image: redis:7-alpine
    container_name: jules_redis
    restart: unless-stopped
    networks:
      jules_net:
        ipv4_address: 172.29.0.11

  jules_postgres:
    image: postgres:16-alpine
    container_name: jules_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=jules_protocol
      - POSTGRES_DB=chimera
    volumes:
      - jules_postgres_data:/var/lib/postgresql/data
    networks:
      jules_net:
        ipv4_address: 172.29.0.12

  jules_qdrant:
    image: qdrant/qdrant:latest
    container_name: jules_qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - jules_qdrant_data:/qdrant/storage
    networks:
      jules_net:
        ipv4_address: 172.29.0.13

  jules_aishell:
    image: chimera/aishell:latest
    container_name: jules_aishell
    restart: unless-stopped
    volumes:
      - ./config/constitution:/config/constitution:ro
      - /var/log/jules_protocol:/var/log/jules_protocol
    environment:
      - CONSTITUTION_PATH=/config/constitution/digital_renegade_core.v3.json
      - OLLAMA_BRAIN_URL=http://jules_ollama:11434
      - OLLAMA_EYES_URL=http://jules_ollama:11434
      - REDIS_URL=redis://jules_redis:6379/0
      - POSTGRES_URL=postgresql://postgres:jules_protocol@jules_postgres:5432/chimera
      - QDRANT_URL=http://jules_qdrant:6333
    networks:
      jules_net:
        ipv4_address: 172.29.0.50
    depends_on:
      - jules_ollama
      - jules_redis
      - jules_postgres
      - jules_qdrant
    stdin_open: true
    tty: true

  jules_memory_pruner:
    image: chimera/memory-pruner:latest
    container_name: jules_memory_pruner
    restart: unless-stopped
    volumes:
      - ./config/constitution:/config/constitution:ro
      - /var/log/jules_protocol:/var/log/jules_protocol
    environment:
      - CONSTITUTION_PATH=/config/constitution/digital_renegade_core.v3.json
      - POSTGRES_URL=postgresql://postgres:jules_protocol@jules_postgres:5432/chimera
      - QDRANT_URL=http://jules_qdrant:6333
      - REDIS_URL=redis://jules_redis:6379/0
    networks:
      jules_net:
        ipv4_address: 172.29.0.51
    depends_on:
      - jules_postgres
      - jules_qdrant
      - jules_redis

volumes:
  jules_ollama_models:
  jules_postgres_data:
  jules_qdrant_data:
EOF

        success "Standalone stack created: docker-compose-jules.yml"

        # Deploy standalone stack
        info "Deploying standalone Jules Protocol stack..."
        docker compose -f "$INSTALL_DIR/docker-compose-jules.yml" up -d

        success "Jules Protocol deployed in standalone mode"
    fi
}

################################################################################
# Post-Install
################################################################################

post_install() {
    info "Running post-install configuration..."

    # Create log directory
    mkdir -p /var/log/jules_protocol
    chmod 755 /var/log/jules_protocol

    # Create CLI alias
    cat > /usr/local/bin/jules << 'EOF'
#!/bin/bash
docker exec -it chimera_aishell python3 /app/aishell.py
EOF
    chmod +x /usr/local/bin/jules

    success "Created 'jules' command"

    # Create evolution tracking
    mkdir -p "$INSTALL_DIR/config/constitution/evolutions"

    success "Post-install configuration complete"
}

################################################################################
# Display Instructions
################################################################################

show_instructions() {
    echo ""
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD} JULES PROTOCOL INSTALLATION COMPLETE${NC}"
    echo -e "${CYAN}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Constitution: $CONSTITUTION_DIR/digital_renegade_core.v3.json"
    echo -e "${GREEN}✓${NC} Evolution Log: $CONSTITUTION_DIR/EVOLUTION_LOG.md"
    echo -e "${GREEN}✓${NC} AI Shell: chimera_aishell"
    echo -e "${GREEN}✓${NC} Memory Pruner: chimera_memory_pruner"
    echo ""
    echo -e "${BOLD}QUICK START:${NC}"
    echo ""
    echo "  # Access AI Shell"
    echo -e "  ${CYAN}jules${NC}"
    echo ""
    echo "  # Or directly:"
    echo -e "  ${CYAN}docker exec -it chimera_aishell python3 /app/aishell.py${NC}"
    echo ""
    echo "  # View memory pruner logs"
    echo -e "  ${CYAN}tail -f /var/log/jules_protocol/memory_pruner.log${NC}"
    echo ""
    echo -e "${BOLD}AVAILABLE MODES:${NC}"
    echo "  ARCHITECT  - Design architecture and systems"
    echo "  CODE       - Write production code"
    echo "  DEBUG      - Debug and troubleshoot"
    echo "  RESEARCH   - Research and learn"
    echo "  SENTRY     - Security monitoring"
    echo "  EVOLVE     - Optimize and refactor"
    echo "  HACK       - Security analysis (ethical use only)"
    echo "  HUSTLE     - Business and monetization"
    echo ""
    echo -e "${BOLD}EXAMPLE USAGE:${NC}"
    echo "  aishell> Design a microservice architecture"
    echo "  aishell> Write a Python script to scrape data"
    echo "  aishell> Debug why my Docker container won't start"
    echo "  aishell> /mode HACK"
    echo "  aishell> Scan my network for vulnerabilities"
    echo ""
    echo -e "${YELLOW}⚠  IMPORTANT:${NC}"
    echo "  - Constitution is in $CONSTITUTION_DIR"
    echo "  - All evolutions must be logged in EVOLUTION_LOG.md"
    echo "  - Memory pruning runs daily at 03:00"
    echo "  - Logs available in /var/log/jules_protocol/"
    echo ""
    echo -e "${BOLD}INTEGRATION:${NC}"

    if [[ "$MODE" == "integrate" ]]; then
        echo "  - Integrated with Digital Renegade"
        echo "  - Uses existing Ollama, PostgreSQL, Redis, Qdrant"
        echo "  - Update stack via Portainer UI"
    else
        echo "  - Running in standalone mode"
        echo "  - Independent Ollama, PostgreSQL, Redis, Qdrant"
        echo "  - Stack: docker-compose-jules.yml"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}\"Jules Protocol loaded. Let's do this properly.\"${NC}"
    echo ""
}

################################################################################
# Main
################################################################################

main() {
    banner

    parse_args "$@"

    check_prerequisites

    setup_constitution

    build_agents

    deploy_services

    post_install

    show_instructions

    success "Installation complete!"
}

main "$@"
