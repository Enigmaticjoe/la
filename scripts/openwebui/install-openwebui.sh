#!/bin/bash
################################################################################
# Open WebUI Installation Script
# Supports Brain PC (192.168.1.9) and unRAID Brawn (192.168.1.222)
################################################################################

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Error handler
error_exit() {
    log_error "$1"
    exit 1
}

# Display banner
show_banner() {
    echo "================================================"
    echo "   Open WebUI Installation Script v1.0"
    echo "================================================"
    echo ""
}

# Detect system type
detect_system() {
    if [ -f /etc/unraid-version ]; then
        echo "unraid"
    elif grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/redhat-release ]; then
        echo "redhat"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Docker installation
check_docker() {
    log_info "Checking Docker installation..."
    
    if ! command_exists docker; then
        log_error "Docker is not installed"
        echo ""
        echo "Please install Docker first:"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        echo ""
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running"
        echo "Please start Docker service"
        return 1
    fi
    
    log_success "Docker is installed and running"
    docker --version
    return 0
}

# Check Docker Compose installation
check_docker_compose() {
    log_info "Checking Docker Compose installation..."
    
    if command_exists docker-compose; then
        log_success "Docker Compose is installed (standalone)"
        docker-compose --version
        return 0
    elif docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose is installed (plugin)"
        docker compose version
        return 0
    else
        log_warning "Docker Compose is not installed"
        log_info "Installing Docker Compose plugin..."
        
        # Try to install using apt (Debian/Ubuntu)
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y docker-compose-plugin
            log_success "Docker Compose plugin installed"
            return 0
        fi
        
        log_error "Could not install Docker Compose automatically"
        echo "Please install Docker Compose manually"
        return 1
    fi
}

# Check for NVIDIA GPU
check_nvidia_gpu() {
    log_info "Checking for NVIDIA GPU..."
    
    if command_exists nvidia-smi; then
        log_success "NVIDIA GPU detected"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || true
        return 0
    else
        log_info "No NVIDIA GPU detected or nvidia-smi not available"
        return 1
    fi
}

# Check NVIDIA Container Toolkit
check_nvidia_toolkit() {
    if docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi >/dev/null 2>&1; then
        log_success "NVIDIA Container Toolkit is installed and working"
        return 0
    else
        log_warning "NVIDIA Container Toolkit not found or not working"
        return 1
    fi
}

# Install NVIDIA Container Toolkit
install_nvidia_toolkit() {
    local SYSTEM_TYPE=$1
    
    log_info "Installing NVIDIA Container Toolkit..."
    
    if [ "$SYSTEM_TYPE" == "debian" ]; then
        # Add NVIDIA Docker repository
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit
        sudo nvidia-ctk runtime configure --runtime=docker
        sudo systemctl restart docker
        
        log_success "NVIDIA Container Toolkit installed"
        return 0
    elif [ "$SYSTEM_TYPE" == "unraid" ]; then
        log_warning "For unRAID, install the NVIDIA Driver plugin from Community Applications"
        return 1
    else
        log_warning "Automatic installation not supported for this system"
        log_info "Please install NVIDIA Container Toolkit manually"
        return 1
    fi
}

# Create directory structure
setup_directories() {
    local BASE_DIR=$1
    
    log_info "Creating directory structure at $BASE_DIR..."
    
    mkdir -p "$BASE_DIR"
    mkdir -p "$BASE_DIR/configs/functions"
    mkdir -p "$BASE_DIR/configs/pipelines"
    mkdir -p "$BASE_DIR/backups"
    mkdir -p "$BASE_DIR/logs"
    
    log_success "Directory structure created"
}

# Copy configuration files
copy_configs() {
    local BASE_DIR=$1
    local SCRIPT_DIR=$2
    local USE_GPU=$3
    
    log_info "Copying configuration files..."
    
    # Copy docker-compose file
    if [ "$USE_GPU" == "true" ]; then
        if [ -f "$SCRIPT_DIR/../docker-compose-gpu.yml" ]; then
            cp "$SCRIPT_DIR/../docker-compose-gpu.yml" "$BASE_DIR/docker-compose.yml"
            log_success "Copied GPU-enabled docker-compose.yml"
        else
            log_warning "GPU docker-compose file not found, using standard version"
            cp "$SCRIPT_DIR/../docker-compose.yml" "$BASE_DIR/docker-compose.yml"
        fi
    else
        cp "$SCRIPT_DIR/../docker-compose.yml" "$BASE_DIR/docker-compose.yml"
        log_success "Copied docker-compose.yml"
    fi
    
    # Copy .env.example
    if [ -f "$SCRIPT_DIR/../.env.example" ]; then
        cp "$SCRIPT_DIR/../.env.example" "$BASE_DIR/.env.example"
        log_success "Copied .env.example"
    fi
}

# Create .env file
create_env_file() {
    local BASE_DIR=$1
    
    if [ -f "$BASE_DIR/.env" ]; then
        log_warning ".env file already exists, skipping creation"
        return 0
    fi
    
    log_info "Creating .env file..."
    
    # Generate secret key
    local SECRET_KEY
    if command_exists openssl; then
        SECRET_KEY=$(openssl rand -base64 32)
    else
        SECRET_KEY="change-me-to-a-random-secret-key"
        log_warning "openssl not found, using placeholder secret key"
    fi
    
    cat > "$BASE_DIR/.env" << EOF
# Open WebUI Configuration
WEBUI_SECRET_KEY=$SECRET_KEY

# Model Configuration
DEFAULT_MODEL=llama3.2:latest
OLLAMA_KEEP_ALIVE=24h
OLLAMA_MAX_LOADED_MODELS=3

# RAG Configuration
RAG_EMBEDDING_MODEL=nomic-embed-text
ENABLE_RAG_WEB_SEARCH=true
EOF
    
    log_success ".env file created"
}

# Start services
start_services() {
    local BASE_DIR=$1
    
    log_info "Starting Open WebUI services..."
    
    cd "$BASE_DIR"
    
    if docker compose version >/dev/null 2>&1; then
        docker compose pull
        docker compose up -d
    else
        docker-compose pull
        docker-compose up -d
    fi
    
    log_success "Services started"
}

# Wait for services to be ready
wait_for_services() {
    local MAX_WAIT=120
    local WAIT_TIME=0
    
    log_info "Waiting for Open WebUI to be ready (max ${MAX_WAIT}s)..."
    
    while [ $WAIT_TIME -lt $MAX_WAIT ]; do
        if curl -sf http://localhost:3000 >/dev/null 2>&1; then
            echo ""
            log_success "Open WebUI is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        WAIT_TIME=$((WAIT_TIME + 2))
    done
    
    echo ""
    log_warning "Open WebUI did not respond within ${MAX_WAIT} seconds"
    log_info "Services may still be starting. Check logs with: docker logs open-webui"
    return 1
}

# Pull initial models
pull_models() {
    log_info "Pulling initial AI models (this may take several minutes)..."
    
    log_info "Pulling llama3.2:latest..."
    docker exec ollama ollama pull llama3.2:latest || {
        log_warning "Failed to pull llama3.2, you can pull it later"
    }
    
    log_info "Pulling nomic-embed-text for embeddings..."
    docker exec ollama ollama pull nomic-embed-text || {
        log_warning "Failed to pull nomic-embed-text, you can pull it later"
    }
    
    log_success "Model pulling completed"
}

# Show completion message
show_completion() {
    local BASE_DIR=$1
    local IP_ADDRESS
    IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
    
    echo ""
    echo "================================================"
    log_success "Installation Complete!"
    echo "================================================"
    echo ""
    echo "Open WebUI is now running at:"
    echo "  • http://localhost:3000"
    echo "  • http://${IP_ADDRESS}:3000"
    echo ""
    echo "Next steps:"
    echo "  1. Open your browser and navigate to one of the URLs above"
    echo "  2. Create your admin account on first visit"
    echo "  3. Start chatting with AI models!"
    echo ""
    echo "Useful commands:"
    echo "  • View logs: docker logs -f open-webui"
    echo "  • Stop services: cd $BASE_DIR && docker compose down"
    echo "  • Restart services: cd $BASE_DIR && docker compose restart"
    echo "  • Pull more models: docker exec ollama ollama pull <model-name>"
    echo ""
    echo "Configuration directory: $BASE_DIR"
    echo ""
}

# Main installation function
main() {
    show_banner
    
    # Detect system
    SYSTEM_TYPE=$(detect_system)
    log_info "Detected system type: $SYSTEM_TYPE"
    echo ""
    
    # Get installation directory
    read -p "Installation directory [${HOME}/open-webui]: " BASE_DIR
    BASE_DIR="${BASE_DIR:-${HOME}/open-webui}"
    
    # Get script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Check prerequisites
    check_docker || error_exit "Docker check failed"
    echo ""
    
    check_docker_compose || error_exit "Docker Compose check failed"
    echo ""
    
    # Check for GPU
    USE_GPU="false"
    if check_nvidia_gpu; then
        echo ""
        read -p "Do you want to enable GPU support? (y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if ! check_nvidia_toolkit; then
                echo ""
                read -p "Install NVIDIA Container Toolkit? (y/n): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    install_nvidia_toolkit "$SYSTEM_TYPE"
                fi
            fi
            USE_GPU="true"
        fi
    fi
    echo ""
    
    # Setup directories
    setup_directories "$BASE_DIR"
    echo ""
    
    # Copy configurations
    copy_configs "$BASE_DIR" "$SCRIPT_DIR" "$USE_GPU"
    echo ""
    
    # Create .env file
    create_env_file "$BASE_DIR"
    echo ""
    
    # Start services
    start_services "$BASE_DIR"
    echo ""
    
    # Wait for services
    wait_for_services
    echo ""
    
    # Pull models
    read -p "Do you want to download initial AI models now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        pull_models
    else
        log_info "You can pull models later with: docker exec ollama ollama pull <model-name>"
    fi
    echo ""
    
    # Show completion
    show_completion "$BASE_DIR"
}

# Run main function
main "$@"
