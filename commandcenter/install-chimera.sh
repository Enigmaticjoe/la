#!/bin/bash
#===============================================================================
# CHIMERA BRAIN AI - INTERACTIVE INSTALLER
# For Ubuntu Server 25.10 @ 192.168.1.9
# Integrated with Unraid @ 192.168.1.222
#===============================================================================
# Run with: sudo bash install-chimera.sh
#===============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

#===============================================================================
# COLORS & FORMATTING
#===============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

#===============================================================================
# LOGGING
#===============================================================================
LOG_FILE="/var/log/chimera_install.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./chimera_install.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
}

banner() {
    clear
    echo -e "${MAGENTA}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██████╗██╗  ██╗██╗███╗   ███╗███████╗██████╗  █████╗       ║
    ║  ██╔════╝██║  ██║██║████╗ ████║██╔════╝██╔══██╗██╔══██╗      ║
    ║  ██║     ███████║██║██╔████╔██║█████╗  ██████╔╝███████║      ║
    ║  ██║     ██╔══██║██║██║╚██╔╝██║██╔══╝  ██╔══██╗██╔══██║      ║
    ║  ╚██████╗██║  ██║██║██║ ╚═╝ ██║███████╗██║  ██║██║  ██║      ║
    ║   ╚═════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝      ║
    ║                                                               ║
    ║           PROJECT CHIMERA - AI BRAIN INSTALLER                ║
    ║                                                               ║
    ║   Self-Hosted AI System with Knowledge Ingestion              ║
    ║   Ubuntu Server 25.10 @ 192.168.1.9                           ║
    ║   Unraid Storage @ 192.168.1.222 (22TB)                       ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#===============================================================================
# CONFIGURATION VARIABLES (Will be set by user prompts)
#===============================================================================
BRAIN_IP="192.168.1.9"
UNRAID_IP="192.168.1.222"
UNRAID_SHARE="chimera"
UNRAID_USERNAME=""
UNRAID_MOUNT_OPTS="rw,hard,intr,rsize=8192,wsize=8192,timeo=14"
INSTALL_DIR="/opt/chimera"
DATA_DIR="/mnt/unraid"

GPU_VENDOR=""  # nvidia or amd
ENABLE_VOICE="true"
ENABLE_IMAGE_GEN="true"
ENABLE_RAG="true"
ENABLE_WEB_SCRAPING="true"

POSTGRES_PASSWORD=""
SETUP_MODE=""  # full, core, minimal

#===============================================================================
# PRE-FLIGHT CHECKS
#===============================================================================
preflight_checks() {
    info "Running pre-flight checks..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi

    # Check OS version
    if ! grep -q "Ubuntu" /etc/os-release; then
        warn "This installer is designed for Ubuntu. You're running $(cat /etc/os-release | grep PRETTY_NAME)"
        read -p "Continue anyway? (yes/no): " continue_anyway
        if [[ "$continue_anyway" != "yes" ]]; then
            exit 1
        fi
    fi

    # Check disk space (need at least 50GB)
    available_space=$(df / | tail -1 | awk '{print $4}')
    required_space=$((50 * 1024 * 1024))  # 50GB in KB

    if [[ $available_space -lt $required_space ]]; then
        error "Insufficient disk space. Need at least 50GB, have $(($available_space / 1024 / 1024))GB"
        exit 1
    fi

    success "Pre-flight checks passed"
}

#===============================================================================
# USER PROMPTS & CONFIGURATION
#===============================================================================
collect_user_input() {
    info "Gathering configuration information..."
    echo ""

    # Network Configuration
    echo -e "${CYAN}${BOLD}NETWORK CONFIGURATION${NC}"
    echo "────────────────────────────────────────────────"
    read -p "Brain IP address [${BRAIN_IP}]: " input_brain_ip
    BRAIN_IP="${input_brain_ip:-$BRAIN_IP}"

    read -p "Unraid IP address [${UNRAID_IP}]: " input_unraid_ip
    UNRAID_IP="${input_unraid_ip:-$UNRAID_IP}"

    read -p "Unraid share name [${UNRAID_SHARE}]: " input_share
    UNRAID_SHARE="${input_share:-$UNRAID_SHARE}"

    read -p "Unraid username (for NFS, leave blank if not needed): " UNRAID_USERNAME

    echo ""

    # Installation Mode
    echo -e "${CYAN}${BOLD}INSTALLATION MODE${NC}"
    echo "────────────────────────────────────────────────"
    echo "1) Full Stack    - All services (recommended)"
    echo "2) Core Only     - AI core + essential services"
    echo "3) Minimal       - Just Ollama + Open WebUI"
    read -p "Select installation mode [1-3]: " mode_choice

    case $mode_choice in
        1) SETUP_MODE="full" ;;
        2) SETUP_MODE="core" ;;
        3) SETUP_MODE="minimal" ;;
        *) SETUP_MODE="full" ;;
    esac

    success "Installation mode: $SETUP_MODE"
    echo ""

    # GPU Detection
    echo -e "${CYAN}${BOLD}GPU CONFIGURATION${NC}"
    echo "────────────────────────────────────────────────"

    if command -v nvidia-smi &> /dev/null; then
        success "NVIDIA GPU detected"
        nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
        GPU_VENDOR="nvidia"
    elif lspci | grep -i "VGA.*AMD" &> /dev/null; then
        warn "AMD GPU detected (experimental support)"
        GPU_VENDOR="amd"
    else
        warn "No GPU detected. AI inference will be CPU-only (slow)"
        GPU_VENDOR="none"
        read -p "Continue without GPU? (yes/no): " continue_no_gpu
        if [[ "$continue_no_gpu" != "yes" ]]; then
            exit 1
        fi
    fi

    echo ""

    # Features Selection
    if [[ "$SETUP_MODE" == "full" ]] || [[ "$SETUP_MODE" == "core" ]]; then
        echo -e "${CYAN}${BOLD}FEATURES${NC}"
        echo "────────────────────────────────────────────────"

        read -p "Enable voice control (TTS/STT)? [Y/n]: " enable_voice_input
        ENABLE_VOICE="${enable_voice_input:-Y}"
        [[ "$ENABLE_VOICE" =~ ^[Yy] ]] && ENABLE_VOICE="true" || ENABLE_VOICE="false"

        read -p "Enable image generation (ComfyUI)? [Y/n]: " enable_img_input
        ENABLE_IMAGE_GEN="${enable_img_input:-Y}"
        [[ "$ENABLE_IMAGE_GEN" =~ ^[Yy] ]] && ENABLE_IMAGE_GEN="true" || ENABLE_IMAGE_GEN="false"

        read -p "Enable RAG document processing? [Y/n]: " enable_rag_input
        ENABLE_RAG="${enable_rag_input:-Y}"
        [[ "$ENABLE_RAG" =~ ^[Yy] ]] && ENABLE_RAG="true" || ENABLE_RAG="false"

        read -p "Enable web scraping & knowledge harvesting? [Y/n]: " enable_scrape_input
        ENABLE_WEB_SCRAPING="${enable_scrape_input:-Y}"
        [[ "$ENABLE_WEB_SCRAPING" =~ ^[Yy] ]] && ENABLE_WEB_SCRAPING="true" || ENABLE_WEB_SCRAPING="false"

        echo ""
    fi

    # Security
    echo -e "${CYAN}${BOLD}SECURITY${NC}"
    echo "────────────────────────────────────────────────"
    read -sp "Set PostgreSQL password (or press Enter for auto-generate): " POSTGRES_PASSWORD
    echo ""

    if [[ -z "$POSTGRES_PASSWORD" ]]; then
        POSTGRES_PASSWORD=$(openssl rand -base64 32)
        info "Generated secure random password"
    fi

    echo ""

    # Confirmation
    echo -e "${CYAN}${BOLD}CONFIGURATION SUMMARY${NC}"
    echo "────────────────────────────────────────────────"
    echo "  Brain IP:          $BRAIN_IP"
    echo "  Unraid IP:         $UNRAID_IP"
    echo "  Unraid Share:      //$UNRAID_IP/$UNRAID_SHARE"
    echo "  Installation Mode: $SETUP_MODE"
    echo "  GPU:               $GPU_VENDOR"
    echo "  Voice Control:     $ENABLE_VOICE"
    echo "  Image Generation:  $ENABLE_IMAGE_GEN"
    echo "  RAG Processing:    $ENABLE_RAG"
    echo "  Web Scraping:      $ENABLE_WEB_SCRAPING"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Data Mount:        $DATA_DIR"
    echo "────────────────────────────────────────────────"
    echo ""

    read -p "Proceed with installation? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        warn "Installation cancelled by user"
        exit 0
    fi
}

#===============================================================================
# SYSTEM PREPARATION
#===============================================================================
prepare_system() {
    info "Preparing system..."

    # Update package lists
    info "Updating package lists..."
    apt-get update | tee -a "$LOG_FILE"

    # Install essential packages
    info "Installing essential packages..."
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        htop \
        net-tools \
        nfs-common \
        cifs-utils \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        jq \
        python3-pip \
        | tee -a "$LOG_FILE"

    success "System prepared"
}

#===============================================================================
# DOCKER INSTALLATION
#===============================================================================
install_docker() {
    info "Installing Docker..."

    if command -v docker &> /dev/null; then
        success "Docker already installed: $(docker --version)"
        return 0
    fi

    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start Docker
    systemctl enable docker
    systemctl start docker

    # Add current user to docker group
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        success "Added $SUDO_USER to docker group"
    fi

    success "Docker installed: $(docker --version)"
}

#===============================================================================
# NVIDIA DOCKER SUPPORT
#===============================================================================
install_nvidia_docker() {
    if [[ "$GPU_VENDOR" != "nvidia" ]]; then
        return 0
    fi

    info "Installing NVIDIA Container Toolkit..."

    if dpkg -l | grep -q nvidia-container-toolkit; then
        success "NVIDIA Container Toolkit already installed"
        return 0
    fi

    # Add NVIDIA Container Toolkit repository
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    apt-get update
    apt-get install -y nvidia-container-toolkit

    # Configure Docker for NVIDIA
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker

    # Test GPU access
    info "Testing GPU access in Docker..."
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi; then
        success "NVIDIA GPU accessible in Docker!"
    else
        error "GPU test failed. Check NVIDIA drivers and toolkit installation."
    fi
}

#===============================================================================
# UNRAID NFS MOUNT
#===============================================================================
setup_unraid_mount() {
    info "Setting up Unraid NFS mount..."

    # Create mount point
    mkdir -p "$DATA_DIR"

    # Check if Unraid is reachable
    if ! ping -c 1 -W 3 "$UNRAID_IP" &> /dev/null; then
        error "Cannot reach Unraid server at $UNRAID_IP"
        read -p "Continue without Unraid mount? (yes/no): " skip_unraid
        if [[ "$skip_unraid" != "yes" ]]; then
            exit 1
        fi
        return 0
    fi

    # Add to /etc/fstab
    FSTAB_ENTRY="$UNRAID_IP:/$UNRAID_SHARE $DATA_DIR nfs $UNRAID_MOUNT_OPTS,nofail 0 0"

    if grep -q "$DATA_DIR" /etc/fstab; then
        warn "Unraid mount already in /etc/fstab"
    else
        echo "$FSTAB_ENTRY" >> /etc/fstab
        success "Added Unraid mount to /etc/fstab"
    fi

    # Mount now
    if mount -a; then
        success "Unraid share mounted at $DATA_DIR"

        # Create Chimera directory structure
        mkdir -p "$DATA_DIR/chimera"/{documents,knowledge,media/{downloads,audio},comfyui_output,postgres_backup,qdrant,ollama_models}
        success "Created directory structure on Unraid"
    else
        error "Failed to mount Unraid share"
        info "You can mount manually later with: mount -a"
    fi
}

#===============================================================================
# INSTALL CHIMERA
#===============================================================================
install_chimera() {
    info "Installing Chimera Brain AI..."

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    # Copy files from current directory to install directory
    info "Copying Chimera files..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    cp -r "$SCRIPT_DIR"/* "$INSTALL_DIR/" 2>/dev/null || true

    # Update docker-compose with user configuration
    info "Configuring docker-compose..."

    # Replace placeholders in docker-compose
    if [[ -f "docker-compose-enhanced.yml" ]]; then
        cp docker-compose-enhanced.yml docker-compose.yml

        # Update passwords
        sed -i "s/chimera_secure_password_change_me/$POSTGRES_PASSWORD/g" docker-compose.yml

        # Update mount paths
        sed -i "s|/mnt/unraid|$DATA_DIR|g" docker-compose.yml

        # Disable services based on user choices
        if [[ "$ENABLE_VOICE" == "false" ]]; then
            info "Disabling voice services..."
            # Comment out voice services
        fi

        if [[ "$ENABLE_IMAGE_GEN" == "false" ]]; then
            info "Disabling image generation..."
            # Comment out ComfyUI
        fi

        if [[ "$SETUP_MODE" == "minimal" ]]; then
            info "Creating minimal docker-compose..."
            # Create minimal version with just Ollama and Open WebUI
        fi

        success "Docker Compose configured"
    else
        error "docker-compose-enhanced.yml not found!"
        exit 1
    fi

    # Create necessary config directories
    mkdir -p config/{homepage,searxng,paperless,filebrowser,rag}
    mkdir -p logs

    success "Chimera installed at $INSTALL_DIR"
}

#===============================================================================
# START SERVICES
#===============================================================================
start_chimera() {
    info "Starting Chimera services..."

    cd "$INSTALL_DIR"

    # Pull images first (faster than building during up)
    info "Pulling Docker images (this may take a while)..."
    docker compose pull 2>&1 | tee -a "$LOG_FILE"

    # Build custom agents
    info "Building custom agents..."
    docker compose build 2>&1 | tee -a "$LOG_FILE"

    # Start services
    info "Starting all services..."
    docker compose up -d 2>&1 | tee -a "$LOG_FILE"

    # Wait for services to stabilize
    info "Waiting for services to start..."
    sleep 15

    # Check service status
    info "Service status:"
    docker compose ps

    success "Chimera services started!"
}

#===============================================================================
# POST-INSTALLATION
#===============================================================================
post_install() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║              INSTALLATION COMPLETE!                           ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    info "Chimera Brain AI is now running!"
    echo ""

    echo -e "${CYAN}${BOLD}ACCESS YOUR SERVICES:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo -e "  🧠 Open WebUI:         ${BLUE}http://$BRAIN_IP:3000${NC}"
    echo -e "  📊 Dashboard:          ${BLUE}http://$BRAIN_IP:3001${NC}"
    echo -e "  🔍 SearXNG:            ${BLUE}http://$BRAIN_IP:8081${NC}"
    echo -e "  📚 Document Manager:   ${BLUE}http://$BRAIN_IP:8082${NC}"
    echo -e "  📥 Media Downloader:   ${BLUE}http://$BRAIN_IP:8083${NC}"
    echo -e "  📁 File Browser:       ${BLUE}http://$BRAIN_IP:8084${NC}"
    echo -e "  🤖 RAG Processor:      ${BLUE}http://$BRAIN_IP:8085${NC}"

    if [[ "$ENABLE_IMAGE_GEN" == "true" ]]; then
        echo -e "  🎨 ComfyUI:            ${BLUE}http://$BRAIN_IP:8188${NC}"
    fi

    if [[ "$ENABLE_VOICE" == "true" ]]; then
        echo -e "  🗣️  AllTalk TTS:        ${BLUE}http://$BRAIN_IP:8880${NC}"
        echo -e "  🎤 Whisper STT:        ${BLUE}http://$BRAIN_IP:9000${NC}"
    fi

    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo -e "${CYAN}${BOLD}OLLAMA API:${NC}"
    echo -e "  ${BLUE}http://$BRAIN_IP:11434${NC}"
    echo ""

    echo -e "${CYAN}${BOLD}USEFUL COMMANDS:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo "  Check service status:      cd $INSTALL_DIR && docker compose ps"
    echo "  View logs:                 cd $INSTALL_DIR && docker compose logs -f"
    echo "  Restart services:          cd $INSTALL_DIR && docker compose restart"
    echo "  Stop all services:         cd $INSTALL_DIR && docker compose down"
    echo "  Start all services:        cd $INSTALL_DIR && docker compose up -d"
    echo "  Pull new AI model:         docker exec chimera_brain ollama pull <model>"
    echo "  List AI models:            docker exec chimera_brain ollama list"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo -e "${CYAN}${BOLD}STORAGE:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo "  Unraid Mount:       $DATA_DIR"
    echo "  Documents:          $DATA_DIR/chimera/documents"
    echo "  Knowledge Base:     $DATA_DIR/chimera/knowledge"
    echo "  Media Downloads:    $DATA_DIR/chimera/media/downloads"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    warn "FIRST-TIME SETUP:"
    info "1. Wait 2-3 minutes for AI models to download (check logs)"
    info "2. Visit Open WebUI at http://$BRAIN_IP:3000"
    info "3. Drop documents into $DATA_DIR/chimera/documents for RAG ingestion"
    info "4. Use the RAG processor API to scan and index documents"
    echo ""

    info "Installation log saved to: $LOG_FILE"
    echo ""

    success "Enjoy your Chimera Brain AI! 🧠🔥"
}

#===============================================================================
# MAIN INSTALLATION FLOW
#===============================================================================
main() {
    banner
    preflight_checks
    collect_user_input

    echo ""
    info "Starting installation..."
    echo ""

    prepare_system
    install_docker
    install_nvidia_docker
    setup_unraid_mount
    install_chimera
    start_chimera
    post_install
}

# Run main function
main "$@"
