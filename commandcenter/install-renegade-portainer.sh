#!/bin/bash
#===============================================================================
# DIGITAL RENEGADE - PORTAINER DEPLOYMENT INSTALLER
# Ubuntu Server 25.10 "Questing Quokka" @ 192.168.1.9
# Unraid @ 192.168.1.222
#===============================================================================
# Philosophy: Digital Sovereignty, Uncensored AI, Punk Rock Ethos
# Run with: sudo bash install-renegade-portainer.sh
#===============================================================================

set -e
set -u
set -o pipefail

#===============================================================================
# COLORS
#===============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

#===============================================================================
# CONFIGURATION
#===============================================================================
BRAIN_IP="192.168.1.9"
UNRAID_IP="192.168.1.222"
UNRAID_SHARE="brain_memory"
NFS_MOUNT="/mnt/brain_memory"
INSTALL_DIR="/opt/chimera_renegade"
LOG_FILE="/var/log/renegade_install.log"

HA_IP="192.168.1.149"
BLUEIRIS_IP="192.168.1.232"

POSTGRES_PASSWORD=""
HA_TOKEN=""
BLUEIRIS_USER=""
BLUEIRIS_PASS=""

#===============================================================================
# LOGGING
#===============================================================================
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
    echo -e "${MAGENTA}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║   ██████╗ ██╗ ██████╗ ██╗████████╗ █████╗ ██╗               ║
    ║   ██╔══██╗██║██╔════╝ ██║╚══██╔══╝██╔══██╗██║               ║
    ║   ██║  ██║██║██║  ███╗██║   ██║   ███████║██║               ║
    ║   ██║  ██║██║██║   ██║██║   ██║   ██╔══██║██║               ║
    ║   ██████╔╝██║╚██████╔╝██║   ██║   ██║  ██║███████╗          ║
    ║   ╚═════╝ ╚═╝ ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝          ║
    ║                                                               ║
    ║        ██████╗ ███████╗███╗   ██╗███████╗ ██████╗  █████╗   ║
    ║        ██╔══██╗██╔════╝████╗  ██║██╔════╝██╔════╝ ██╔══██╗  ║
    ║        ██████╔╝█████╗  ██╔██╗ ██║█████╗  ██║  ███╗███████║  ║
    ║        ██╔══██╗██╔══╝  ██║╚██╗██║██╔══╝  ██║   ██║██╔══██║  ║
    ║        ██║  ██║███████╗██║ ╚████║███████╗╚██████╔╝██║  ██║  ║
    ║        ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝  ║
    ║                                                               ║
    ║              🔥 DIGITAL RENEGADE INSTALLER 🔥                 ║
    ║                                                               ║
    ║   Uncensored AI • Digital Sovereignty • Punk Rock Ethos      ║
    ║   Ubuntu 25.10 "Questing Quokka" @ 192.168.1.9              ║
    ║   Unraid @ 192.168.1.222 (22TB Storage)                      ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#===============================================================================
# PRE-FLIGHT CHECKS
#===============================================================================
preflight_checks() {
    info "Running pre-flight checks..."

    # Check if pre-install auditor was run
    if [[ ! -f /tmp/renegade_audit_report.txt ]]; then
        warn "Pre-install auditor has not been run!"
        echo ""
        echo -e "${YELLOW}It is STRONGLY RECOMMENDED to run the pre-install auditor first:${NC}"
        echo -e "  ${CYAN}sudo bash pre-install-auditor.sh${NC}"
        echo ""
        echo "The auditor will:"
        echo "  • Validate system requirements (CPU, RAM, GPU, disk space)"
        echo "  • Check for port conflicts"
        echo "  • Detect conflicting services"
        echo "  • Clean up Docker environment"
        echo "  • Prepare filesystem structure"
        echo ""
        read -p "Continue without running auditor? (yes/no): " skip_auditor
        if [[ "$skip_auditor" != "yes" ]]; then
            info "Exiting. Please run: sudo bash pre-install-auditor.sh"
            exit 0
        fi
        warn "Proceeding without auditor validation - installation may fail"
    else
        success "Pre-install auditor has been run"

        # Check for critical errors in audit report
        if grep -q "critical errors found" /tmp/renegade_audit_report.txt; then
            error "Auditor found critical errors that must be fixed first"
            cat /tmp/renegade_audit_report.txt
            echo ""
            error "Fix errors and re-run auditor before installing"
            exit 1
        fi
    fi

    # Root check
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi

    # OS check
    if ! grep -q "Ubuntu" /etc/os-release; then
        warn "Designed for Ubuntu 25.10. You're running:"
        cat /etc/os-release | grep PRETTY_NAME
        read -p "Continue anyway? (yes/no): " continue_anyway
        [[ "$continue_anyway" != "yes" ]] && exit 1
    fi

    # Check for Ubuntu 25.10 specifically
    if grep -q "25.10" /etc/os-release; then
        info "Ubuntu 25.10 'Questing Quokka' detected - using optimized configuration"
    else
        warn "Not Ubuntu 25.10. Some optimizations may not apply."
    fi

    # Disk space (need 100GB)
    local available_gb=$(df / | tail -1 | awk '{print int($4/1024/1024)}')
    if [[ $available_gb -lt 100 ]]; then
        error "Need at least 100GB free. Have ${available_gb}GB"
        exit 1
    fi

    # Network connectivity
    if ! ping -c 1 -W 3 $UNRAID_IP &>/dev/null; then
        error "Cannot reach Unraid at $UNRAID_IP"
        read -p "Continue without Unraid mount? (yes/no): " skip_unraid
        [[ "$skip_unraid" != "yes" ]] && exit 1
    fi

    success "Pre-flight checks passed"
}

#===============================================================================
# USER INPUT
#===============================================================================
collect_credentials() {
    echo ""
    echo -e "${CYAN}${BOLD}CONFIGURATION${NC}"
    echo "────────────────────────────────────────────────"

    # PostgreSQL password
    read -sp "PostgreSQL password (or Enter for auto-generate): " POSTGRES_PASSWORD
    echo ""
    if [[ -z "$POSTGRES_PASSWORD" ]]; then
        POSTGRES_PASSWORD=$(openssl rand -base64 32)
        info "Generated secure PostgreSQL password"
    fi

    # Home Assistant token
    echo ""
    info "Home Assistant integration (optional)"
    read -p "Home Assistant long-lived access token (or Enter to skip): " HA_TOKEN

    # Blue Iris credentials
    echo ""
    info "Blue Iris integration (optional)"
    read -p "Blue Iris username (or Enter to skip): " BLUEIRIS_USER
    if [[ -n "$BLUEIRIS_USER" ]]; then
        read -sp "Blue Iris password: " BLUEIRIS_PASS
        echo ""
    fi

    echo ""
    echo -e "${CYAN}${BOLD}SUMMARY${NC}"
    echo "────────────────────────────────────────────────"
    echo "  Brain IP:       $BRAIN_IP"
    echo "  Unraid IP:      $UNRAID_IP"
    echo "  Install Dir:    $INSTALL_DIR"
    echo "  NFS Mount:      $NFS_MOUNT"
    echo "  HA Integration: $([ -n "$HA_TOKEN" ] && echo 'Enabled' || echo 'Disabled')"
    echo "  BI Integration: $([ -n "$BLUEIRIS_USER" ] && echo 'Enabled' || echo 'Disabled')"
    echo "────────────────────────────────────────────────"
    echo ""

    read -p "Proceed with installation? (yes/no): " confirm
    [[ "$confirm" != "yes" ]] && exit 0
}

#===============================================================================
# SYSTEM PREPARATION
#===============================================================================
prepare_system() {
    info "Preparing system..."

    apt-get update | tee -a "$LOG_FILE"

    apt-get install -y \
        curl \
        wget \
        git \
        nfs-common \
        ca-certificates \
        gnupg \
        lsb-release \
        jq \
        nmap \
        net-tools \
        python3-pip \
        | tee -a "$LOG_FILE"

    success "System prepared"
}

#===============================================================================
# DOCKER INSTALLATION
#===============================================================================
install_docker() {
    if command -v docker &>/dev/null; then
        success "Docker already installed: $(docker --version)"
        return 0
    fi

    info "Installing Docker..."

    # Add Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable docker
    systemctl start docker

    # Add user to docker group
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER"
        success "Added $SUDO_USER to docker group"
    fi

    success "Docker installed: $(docker --version)"
}

#===============================================================================
# NVIDIA GPU SETUP (Ubuntu 25.10 specific - 580 branch)
#===============================================================================
install_nvidia_support() {
    info "Setting up NVIDIA GPU support..."

    # Check if GPU exists
    if ! lspci | grep -i nvidia &>/dev/null; then
        warn "No NVIDIA GPU detected. Skipping GPU setup."
        return 0
    fi

    # Check if drivers already installed
    if nvidia-smi &>/dev/null; then
        success "NVIDIA drivers already installed"
    else
        info "Installing NVIDIA drivers (580 branch for compute workloads)..."

        # Ubuntu 25.10 uses 580 branch, install headless/server variant
        ubuntu-drivers install --gpgpu

        # Alternative: Explicitly install 580 server
        # apt-get install -y nvidia-driver-580-server nvidia-utils-580-server

        info "NVIDIA driver installed. Reboot may be required."
    fi

    # Install NVIDIA Container Toolkit
    if dpkg -l | grep -q nvidia-container-toolkit; then
        success "NVIDIA Container Toolkit already installed"
    else
        info "Installing NVIDIA Container Toolkit..."

        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
            gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

        curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

        apt-get update
        apt-get install -y nvidia-container-toolkit

        nvidia-ctk runtime configure --runtime=docker
        systemctl restart docker

        success "NVIDIA Container Toolkit installed"
    fi

    # Test GPU in Docker
    info "Testing GPU access in Docker..."
    if docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi 2>&1 | tee -a "$LOG_FILE"; then
        success "GPU is accessible in Docker!"
    else
        error "GPU test failed. May need reboot or driver fix."
    fi
}

#===============================================================================
# PORTAINER INSTALLATION
#===============================================================================
install_portainer() {
    info "Installing Portainer..."

    # Check if already running
    if docker ps | grep -q portainer; then
        success "Portainer already running"
        return 0
    fi

    # Create portainer volume
    docker volume create portainer_data 2>/dev/null || true

    # Deploy Portainer
    docker run -d \
        --name=portainer \
        --restart=unless-stopped \
        -p 9000:9000 \
        -p 9443:9443 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest

    success "Portainer installed at http://$BRAIN_IP:9000"

    info "Waiting for Portainer to start..."
    sleep 10
}

#===============================================================================
# UNRAID NFS MOUNT
#===============================================================================
setup_unraid_mount() {
    info "Setting up Unraid NFS mount..."

    mkdir -p "$NFS_MOUNT"

    # Check if already mounted
    if mount | grep -q "$NFS_MOUNT"; then
        success "Unraid already mounted at $NFS_MOUNT"
        return 0
    fi

    # Test if Unraid is reachable
    if ! ping -c 1 -W 3 "$UNRAID_IP" &>/dev/null; then
        warn "Cannot reach Unraid at $UNRAID_IP. Skipping mount."
        return 0
    fi

    # Add to fstab
    local FSTAB_ENTRY="$UNRAID_IP:/$UNRAID_SHARE $NFS_MOUNT nfs rw,hard,intr,rsize=8192,wsize=8192,timeo=14,nofail 0 0"

    if ! grep -q "$NFS_MOUNT" /etc/fstab; then
        echo "$FSTAB_ENTRY" >> /etc/fstab
        success "Added Unraid mount to /etc/fstab"
    fi

    # Mount now
    if mount -a 2>&1 | tee -a "$LOG_FILE"; then
        success "Unraid mounted at $NFS_MOUNT"

        # Create directory structure
        mkdir -p "$NFS_MOUNT"/{documents,knowledge,models,camera_analysis,generated_images,qdrant_backup,postgres_backup,harvested,security_scans}
        success "Created directory structure on Unraid"
    else
        warn "Failed to mount Unraid. Will retry on reboot."
    fi
}

#===============================================================================
# DEPLOY PORTAINER STACK
#===============================================================================
deploy_stack() {
    info "Deploying Digital Renegade stack via Portainer..."

    # Copy files to install directory
    mkdir -p "$INSTALL_DIR"
    cp -r "$(dirname "${BASH_SOURCE[0]}")"/* "$INSTALL_DIR/" 2>/dev/null || true
    cd "$INSTALL_DIR"

    # Create .env file with credentials
    cat > "$INSTALL_DIR/.env" <<EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
HA_TOKEN=${HA_TOKEN:-}
BLUEIRIS_USER=${BLUEIRIS_USER:-}
BLUEIRIS_PASS=${BLUEIRIS_PASS:-}
UNRAID_API_KEY=${UNRAID_API_KEY:-}
EOF

    chmod 600 "$INSTALL_DIR/.env"

    info "Stack files prepared at $INSTALL_DIR"
    info "Portainer deployment:"
    echo ""
    echo "1. Open http://$BRAIN_IP:9000"
    echo "2. Create admin account"
    echo "3. Go to 'Stacks' → 'Add Stack'"
    echo "4. Name: chimera-renegade"
    echo "5. Upload: $INSTALL_DIR/portainer-stack-renegade.yml"
    echo "6. Environment variables: Load from $INSTALL_DIR/.env"
    echo "7. Click 'Deploy the stack'"
    echo ""

    warn "Portainer web UI deployment required (not fully automatable)"
    warn "Follow the steps above to deploy the stack"

    # Alternative: Use Portainer API (if we had credentials)
    # This would require Portainer to be pre-configured

    success "Stack deployment prepared"
}

#===============================================================================
# POST-INSTALL CONFIGURATION
#===============================================================================
post_install() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << 'EOF'
    ╔═══════════════════════════════════════════════════════════════╗
    ║                                                               ║
    ║          🔥 DIGITAL RENEGADE INSTALLATION COMPLETE 🔥         ║
    ║                                                               ║
    ╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    info "Installation completed successfully!"
    echo ""

    echo -e "${CYAN}${BOLD}NEXT STEPS:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo ""
    echo "1. ${BOLD}Access Portainer${NC}"
    echo "   URL: http://$BRAIN_IP:9000"
    echo "   Create admin account"
    echo ""
    echo "2. ${BOLD}Deploy the Stack${NC}"
    echo "   - Go to 'Stacks' → 'Add Stack'"
    echo "   - Name: chimera-renegade"
    echo "   - Upload: $INSTALL_DIR/portainer-stack-renegade.yml"
    echo "   - Environment: Load from $INSTALL_DIR/.env"
    echo "   - Click 'Deploy'"
    echo ""
    echo "3. ${BOLD}Wait for Services${NC}"
    echo "   - AI models will auto-download (15-30 minutes)"
    echo "   - Monitor in Portainer 'Containers' tab"
    echo ""
    echo "4. ${BOLD}Access JARVIS${NC}"
    echo "   URL: http://$BRAIN_IP:3000"
    echo "   Greeting: 'What's up. JARVIS here. What are we building today?'"
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo -e "${CYAN}${BOLD}QUICK REFERENCE:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo "  Portainer:       http://$BRAIN_IP:9000"
    echo "  Open WebUI:      http://$BRAIN_IP:3000"
    echo "  Dashboard:       http://$BRAIN_IP:3001"
    echo "  Ollama API:      http://$BRAIN_IP:11434"
    echo "  Vision API:      http://$BRAIN_IP:11435"
    echo "  RAG Processor:   http://$BRAIN_IP:8085"
    echo "  Unraid Mount:    $NFS_MOUNT"
    echo "  Install Dir:     $INSTALL_DIR"
    echo "  Logs:            $LOG_FILE"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo -e "${CYAN}${BOLD}OPERATIONAL MODES:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo "  /mode DEFAULT    Standard renegade mode"
    echo "  /mode HACK       Red team security analysis"
    echo "  /mode CODE       DevOps engineer mode"
    echo "  /mode RESEARCH   Deep investigation"
    echo "  /mode HUSTLE     Money-making opportunities"
    echo "  /mode SENTRY     Active defense monitoring"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    echo -e "${CYAN}${BOLD}DOCUMENTATION:${NC}"
    echo "────────────────────────────────────────────────────────────"
    echo "  Full Guide:   $INSTALL_DIR/DIGITAL-RENEGADE-DEPLOYMENT.md"
    echo "  Stack Config: $INSTALL_DIR/portainer-stack-renegade.yml"
    echo "  Personality:  $INSTALL_DIR/config/personas/renegade_master.json"
    echo "  Modes:        $INSTALL_DIR/config/operational_modes/mode_definitions.json"
    echo "────────────────────────────────────────────────────────────"
    echo ""

    success "Welcome to Digital Freedom. You are now sovereign. 🔥"
}

#===============================================================================
# MAIN INSTALLATION FLOW
#===============================================================================
main() {
    banner
    preflight_checks
    collect_credentials

    echo ""
    info "Starting installation..."
    echo ""

    prepare_system
    install_docker
    install_nvidia_support
    install_portainer
    setup_unraid_mount
    deploy_stack
    post_install
}

# Run main function
main "$@"
