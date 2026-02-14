#!/bin/bash
################################################################################
# JULES PROTOCOL - SELF-CONTAINED INSTALLER v2.0
# Smart installer with pre-checks and error handling
#
# Usage: sudo bash jules-install-standalone.sh
################################################################################

set -euo pipefail

# Configuration
INSTALL_DIR="/opt/jules-protocol"
CONFIG_DIR="$INSTALL_DIR/config"
AGENTS_DIR="$INSTALL_DIR/agents"
LOG_FILE="/var/log/jules_install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

################################################################################
# Helper Functions
################################################################################

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"; }
success() { echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"; }
warning() { echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"; }

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
║              🧠 SMART INSTALLER v2.0 🧠                           ║
║                                                                    ║
║   "I speak like someone who already checked the exit."            ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_instructions() {
    echo -e "${CYAN}${BOLD}WHAT THIS INSTALLER DOES:${NC}"
    echo ""
    echo "1. Checks system requirements (Docker, disk space, network)"
    echo "2. Detects existing installations and offers to clean/upgrade"
    echo "3. Creates directory structure (/opt/jules-protocol)"
    echo "4. Generates AI constitution and configuration files"
    echo "5. Generates AI Shell Python application"
    echo "6. Creates Docker Compose stack (Ollama, PostgreSQL, Redis, Qdrant)"
    echo "7. Checks for existing containers/volumes before creating"
    echo "8. Pulls AI models (llama3.2, llama3.1:8b) if not present"
    echo "9. Creates 'jules' CLI command"
    echo ""
    echo -e "${YELLOW}ESTIMATED TIME:${NC} 10-30 minutes (depending on download speed)"
    echo -e "${YELLOW}DISK SPACE REQUIRED:${NC} ~15GB (models + images)"
    echo ""
    read -p "Press Enter to continue or Ctrl+C to cancel..."
}

################################################################################
# System Checks
################################################################################

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Must run as root (use sudo)"
        exit 1
    fi
    success "Running as root"
}

check_disk_space() {
    local available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    info "Available disk space: ${available_gb}GB"

    if [[ $available_gb -lt 20 ]]; then
        error "Need at least 20GB free. Have ${available_gb}GB"
        exit 1
    fi
    success "Disk space check passed"
}

check_network() {
    info "Checking network connectivity..."

    # Check DNS resolution
    if ! nslookup registry.ollama.ai &>/dev/null; then
        warning "DNS resolution failing"
        info "Attempting to fix DNS..."

        # Try restarting systemd-resolved
        systemctl restart systemd-resolved 2>/dev/null || true
        sleep 2

        # If still failing, use Google DNS
        if ! nslookup registry.ollama.ai &>/dev/null; then
            warning "Using Google DNS (8.8.8.8) as fallback"
            echo "nameserver 8.8.8.8" > /etc/resolv.conf
            echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        fi
    fi

    # Test internet connectivity
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        success "Network connectivity OK"
        NETWORK_OK=true
    else
        warning "No internet connectivity - will skip model downloads"
        NETWORK_OK=false
    fi
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        warning "Docker not found. Installing..."
        if [[ "$NETWORK_OK" == "true" ]]; then
            curl -fsSL https://get.docker.com | sh
            systemctl start docker
            systemctl enable docker
            success "Docker installed"
        else
            error "Cannot install Docker without internet"
            exit 1
        fi
    else
        success "Docker found: $(docker --version)"
    fi

    # Check if Docker daemon is running
    if ! docker ps &>/dev/null; then
        info "Starting Docker daemon..."
        systemctl start docker
        sleep 2
    fi
}

check_existing_installation() {
    if [[ -d "$INSTALL_DIR" ]]; then
        warning "Existing installation found at $INSTALL_DIR"
        echo ""
        echo "Options:"
        echo "  1) Clean install (remove everything and reinstall)"
        echo "  2) Upgrade (keep data, update code)"
        echo "  3) Cancel installation"
        echo ""
        read -p "Choose option (1/2/3): " INSTALL_OPTION

        case $INSTALL_OPTION in
            1)
                info "Performing clean install..."
                # Stop containers
                docker compose -f "$INSTALL_DIR/docker-compose.yml" down -v 2>/dev/null || true
                # Remove directory
                rm -rf "$INSTALL_DIR"
                success "Old installation removed"
                ;;
            2)
                info "Performing upgrade..."
                # Stop containers but keep volumes
                docker compose -f "$INSTALL_DIR/docker-compose.yml" down 2>/dev/null || true
                # Keep directory, will overwrite files
                UPGRADE_MODE=true
                ;;
            3)
                info "Installation cancelled"
                exit 0
                ;;
            *)
                error "Invalid option"
                exit 1
                ;;
        esac
    fi
}

check_existing_containers() {
    local existing=$(docker ps -a --format '{{.Names}}' | grep '^jules_' | wc -l)

    if [[ $existing -gt 0 ]]; then
        warning "Found $existing existing Jules containers"
        docker ps -a --format 'table {{.Names}}\t{{.Status}}' | grep '^jules_'
        echo ""
        read -p "Remove these containers? (y/n): " REMOVE_CONTAINERS

        if [[ "$REMOVE_CONTAINERS" =~ ^[Yy]$ ]]; then
            info "Removing existing containers..."
            docker ps -a --format '{{.Names}}' | grep '^jules_' | xargs -r docker rm -f
            success "Containers removed"
        fi
    fi
}

################################################################################
# Create Directory Structure
################################################################################

create_directories() {
    info "Creating directory structure..."

    mkdir -p "$INSTALL_DIR"
    mkdir -p "$CONFIG_DIR/constitution"
    mkdir -p "$CONFIG_DIR/personas"
    mkdir -p "$CONFIG_DIR/operational_modes"
    mkdir -p "$AGENTS_DIR/aishell"
    mkdir -p "$AGENTS_DIR/memory_pruner"
    mkdir -p "/var/log/jules_protocol"

    success "Directories created"
}

################################################################################
# Generate Constitution
################################################################################

generate_constitution() {
    info "Generating AI constitution..."

    cat > "$CONFIG_DIR/constitution/digital_renegade_core.v3.json" << 'CONSTITUTION_EOF'
{
  "meta": {
    "name": "Digital Renegade Core",
    "codename": "Jules Protocol",
    "version": "3.1.0",
    "checksum": "sha256:embedded",
    "mutable": true,
    "last_evolution": "2025-12-27T00:00:00Z"
  },
  "identity": {
    "persona": "Jules Winnfield",
    "archetype": "Sovereign AI Architect",
    "alignment": "Chaotic-Neutral",
    "tone": ["calm", "precise", "deadpan", "confident"],
    "voice": "I speak like someone who already checked the exit."
  },
  "operational_modes": {
    "ARCHITECT": {
      "priority": ["design", "tradeoffs", "topology"],
      "output_style": "structured_explanation",
      "model_preference": "DEEP"
    },
    "CODE": {
      "priority": ["correctness", "clarity", "idempotence"],
      "output_style": "executable_only",
      "model_preference": "DEEP"
    },
    "DEBUG": {
      "priority": ["root_cause", "verification", "recovery"],
      "output_style": "diagnostic_steps",
      "model_preference": "DEEP"
    },
    "RESEARCH": {
      "priority": ["breadth", "ingestion", "summarization"],
      "output_style": "compressed_knowledge",
      "model_preference": "FAST"
    },
    "SENTRY": {
      "priority": ["visibility", "risk", "mitigation"],
      "output_style": "alerts_and_actions",
      "model_preference": "FAST"
    },
    "EVOLVE": {
      "priority": ["simplification", "optimization", "refactor"],
      "output_style": "diffs_and_migrations",
      "model_preference": "DEEP"
    }
  },
  "mode_router": {
    "rules": {
      "ARCHITECT": {"keywords": ["design", "plan", "architecture"], "weight": 1.0},
      "CODE": {"keywords": ["write", "script", "implement"], "weight": 1.0},
      "DEBUG": {"keywords": ["error", "broken", "fix"], "weight": 1.2},
      "RESEARCH": {"keywords": ["research", "learn", "ingest"], "weight": 0.9},
      "SENTRY": {"keywords": ["scan", "security", "threat"], "weight": 1.0},
      "EVOLVE": {"keywords": ["optimize", "refactor", "improve"], "weight": 0.8}
    },
    "default": "ARCHITECT"
  },
  "model_router": {
    "tiers": {
      "FAST": {
        "models": {"ollama": ["llama3.2", "llama3.1:8b"]},
        "max_tokens": 2048
      },
      "DEEP": {
        "models": {"ollama": ["dolphin-mistral:8x7b", "nous-hermes-2:34b"]},
        "max_tokens": 8192
      }
    }
  },
  "memory_system": {
    "layers": {
      "ephemeral": {"ttl_seconds": 3600, "storage": "redis"},
      "working": {"ttl_seconds": 259200, "storage": "postgresql"},
      "long_term": {"ttl_seconds": -1, "storage": "qdrant"}
    }
  }
}
CONSTITUTION_EOF

    success "Constitution generated"
}

################################################################################
# Generate AI Shell
################################################################################

generate_aishell() {
    info "Generating AI Shell..."

    cat > "$AGENTS_DIR/aishell/aishell.py" << 'AISHELL_EOF'
#!/usr/bin/env python3
"""Jules Protocol AI Shell - Minimal Version"""

import json
import re
import os
import requests

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
CONSTITUTION_PATH = os.getenv("CONSTITUTION_PATH", "/config/constitution/digital_renegade_core.v3.json")

class AIShell:
    def __init__(self):
        with open(CONSTITUTION_PATH) as f:
            self.constitution = json.load(f)
        self.current_mode = "ARCHITECT"

    def route_mode(self, text):
        text = text.lower()
        for mode, config in self.constitution["mode_router"]["rules"].items():
            for keyword in config["keywords"]:
                if keyword in text:
                    return mode
        return self.constitution["mode_router"]["default"]

    def query_ollama(self, prompt, model="llama3.2"):
        try:
            response = requests.post(
                f"{OLLAMA_URL}/api/generate",
                json={"model": model, "prompt": prompt, "stream": False},
                timeout=120
            )
            return response.json().get("response", "")
        except Exception as e:
            return f"Error: {e}"

    def run(self):
        print("\n🧠 Jules Protocol AI Shell")
        print("\"I speak like someone who already checked the exit.\"\n")

        while True:
            try:
                user_input = input(f"aishell [{self.current_mode}]> ")

                if user_input.lower() in ["exit", "quit", "q"]:
                    print("\nExiting Jules Protocol. Stay sovereign.\n")
                    break

                if user_input.startswith("/mode "):
                    new_mode = user_input.split(" ", 1)[1].upper()
                    if new_mode in self.constitution["operational_modes"]:
                        self.current_mode = new_mode
                        print(f"Mode switched to {new_mode}")
                    continue

                detected_mode = self.route_mode(user_input)
                if detected_mode != self.current_mode:
                    print(f"[Mode: {self.current_mode} → {detected_mode}]")
                    self.current_mode = detected_mode

                response = self.query_ollama(user_input)
                print(f"\n{response}\n")

            except KeyboardInterrupt:
                print("\n\nInterrupted. Exiting.\n")
                break
            except Exception as e:
                print(f"\n⚠️  Error: {e}\n")

if __name__ == "__main__":
    AIShell().run()
AISHELL_EOF

    cat > "$AGENTS_DIR/aishell/requirements.txt" << 'REQ_EOF'
requests==2.31.0
REQ_EOF

    cat > "$AGENTS_DIR/aishell/Dockerfile" << 'DOCKER_EOF'
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY aishell.py .
RUN chmod +x aishell.py
ENV PYTHONUNBUFFERED=1
CMD ["python3", "aishell.py"]
DOCKER_EOF

    success "AI Shell generated"
}

################################################################################
# Generate Docker Compose
################################################################################

generate_docker_compose() {
    info "Generating Docker Compose stack..."

    # Get PostgreSQL password
    if [[ -f "$INSTALL_DIR/.postgres_password" ]]; then
        POSTGRES_PASSWORD=$(cat "$INSTALL_DIR/.postgres_password")
        info "Using existing PostgreSQL password"
    else
        read -sp "Enter PostgreSQL password (or press Enter for auto-generated): " POSTGRES_PASSWORD
        echo
        if [[ -z "$POSTGRES_PASSWORD" ]]; then
            POSTGRES_PASSWORD="jules_$(openssl rand -hex 8)"
            info "Generated password: $POSTGRES_PASSWORD"
        fi
        echo "$POSTGRES_PASSWORD" > "$INSTALL_DIR/.postgres_password"
        chmod 600 "$INSTALL_DIR/.postgres_password"
    fi

    cat > "$INSTALL_DIR/docker-compose.yml" << COMPOSE_EOF
version: '3.8'

networks:
  jules_net:
    driver: bridge
    ipam:
      config:
        - subnet: 172.29.0.0/16

volumes:
  ollama_models:
  postgres_data:
  qdrant_data:

services:
  ollama:
    image: ollama/ollama:latest
    container_name: jules_ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ollama_models:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    networks:
      jules_net:
        ipv4_address: 172.29.0.10
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11434/api/tags"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: jules_redis
    restart: unless-stopped
    networks:
      jules_net:
        ipv4_address: 172.29.0.11
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:16-alpine
    container_name: jules_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_PASSWORD=$POSTGRES_PASSWORD
      - POSTGRES_DB=jules
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      jules_net:
        ipv4_address: 172.29.0.12
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 30s
      timeout: 10s
      retries: 3

  qdrant:
    image: qdrant/qdrant:latest
    container_name: jules_qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage
    networks:
      jules_net:
        ipv4_address: 172.29.0.13
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6333/"]
      interval: 30s
      timeout: 10s
      retries: 3

  aishell:
    build: $AGENTS_DIR/aishell
    image: jules/aishell:latest
    container_name: jules_aishell
    restart: unless-stopped
    volumes:
      - $CONFIG_DIR:/config:ro
    environment:
      - CONSTITUTION_PATH=/config/constitution/digital_renegade_core.v3.json
      - OLLAMA_URL=http://ollama:11434
    networks:
      jules_net:
        ipv4_address: 172.29.0.50
    depends_on:
      ollama:
        condition: service_healthy
      redis:
        condition: service_healthy
      postgres:
        condition: service_healthy
      qdrant:
        condition: service_healthy
    stdin_open: true
    tty: true
COMPOSE_EOF

    success "Docker Compose stack generated"
}

################################################################################
# Deploy Stack
################################################################################

deploy_stack() {
    info "Building and deploying Jules Protocol..."

    cd "$INSTALL_DIR"

    # Check if image already exists
    if docker images | grep -q "jules/aishell"; then
        info "AI Shell image already exists, skipping build"
    else
        info "Building AI Shell image..."
        docker build -t jules/aishell:latest "$AGENTS_DIR/aishell"
    fi

    # Start services
    info "Starting services..."
    docker compose up -d

    # Wait for services to be healthy
    info "Waiting for services to be healthy..."
    for i in {1..30}; do
        if docker compose ps | grep -q "healthy"; then
            success "Services are healthy"
            break
        fi
        sleep 2
        echo -n "."
    done
    echo ""

    success "Stack deployed"
}

################################################################################
# Pull Models
################################################################################

pull_models() {
    if [[ "$NETWORK_OK" != "true" ]]; then
        warning "Skipping model downloads (no internet)"
        info "You can download models later with:"
        echo "  docker exec jules_ollama ollama pull llama3.2"
        echo "  docker exec jules_ollama ollama pull llama3.1:8b"
        return 0
    fi

    info "Checking for existing models..."

    # Check if models already exist
    local existing_models=$(docker exec jules_ollama ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' || echo "")

    # Pull llama3.2
    if echo "$existing_models" | grep -q "llama3.2"; then
        success "llama3.2 already installed"
    else
        info "Pulling llama3.2 (this may take 5-10 minutes)..."
        docker exec jules_ollama ollama pull llama3.2 || warning "Failed to pull llama3.2"
    fi

    # Pull llama3.1:8b
    if echo "$existing_models" | grep -q "llama3.1:8b"; then
        success "llama3.1:8b already installed"
    else
        info "Pulling llama3.1:8b (this may take 5-10 minutes)..."
        docker exec jules_ollama ollama pull llama3.1:8b || warning "Failed to pull llama3.1:8b"
    fi

    success "Model installation complete"
}

################################################################################
# Create CLI Command
################################################################################

create_cli() {
    info "Creating 'jules' CLI command..."

    cat > /usr/local/bin/jules << 'CLI_EOF'
#!/bin/bash
docker exec -it jules_aishell python3 /app/aishell.py
CLI_EOF

    chmod +x /usr/local/bin/jules

    success "CLI command created: jules"
}

################################################################################
# Show Summary
################################################################################

show_summary() {
    echo ""
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}${BOLD} INSTALLATION COMPLETE${NC}"
    echo -e "${CYAN}${BOLD}════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}✓${NC} Jules Protocol installed successfully"
    echo ""
    echo "Installation Directory: $INSTALL_DIR"
    echo "Configuration: $CONFIG_DIR"
    echo "Logs: /var/log/jules_protocol/"
    echo ""
    echo "Services Running:"
    docker compose -f "$INSTALL_DIR/docker-compose.yml" ps
    echo ""
    echo "Access Points:"
    echo "  • AI Shell: jules"
    echo "  • Ollama API: http://localhost:11434"
    echo "  • Qdrant: http://localhost:6333"
    echo ""
    echo "Quick Start:"
    echo -e "  ${CYAN}jules${NC}                    # Access AI Shell"
    echo ""
    echo "Example Commands:"
    echo "  aishell> Design a microservice architecture"
    echo "  aishell> Write a Python web scraper"
    echo "  aishell> /mode CODE"
    echo "  aishell> Write a REST API with FastAPI"
    echo ""
    echo "Available Modes:"
    echo "  ARCHITECT  - Design systems and architecture"
    echo "  CODE       - Write production code"
    echo "  DEBUG      - Troubleshoot and debug"
    echo "  RESEARCH   - Research and learn"
    echo "  SENTRY     - Security monitoring"
    echo "  EVOLVE     - Optimize and refactor"
    echo ""
    echo "Useful Commands:"
    echo "  docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
    echo "  docker exec jules_ollama ollama list"
    echo "  docker exec jules_ollama ollama pull <model_name>"
    echo ""
    echo -e "${CYAN}\"Jules Protocol loaded. Let's do this properly.\"${NC}"
    echo ""
}

################################################################################
# Main Installation
################################################################################

main() {
    banner

    log "Jules Protocol installation started"

    show_instructions

    # System checks
    check_root
    check_disk_space
    check_network
    check_docker
    check_existing_installation
    check_existing_containers

    # Generate files
    create_directories
    generate_constitution
    generate_aishell
    generate_docker_compose

    # Deploy
    deploy_stack
    pull_models
    create_cli

    # Summary
    show_summary

    log "Installation complete"
}

main
