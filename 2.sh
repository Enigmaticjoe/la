#!/bin/bash

#############################################################################
# PORTAINER CE INSTALLER FOR FEDORA 43
# Installs Docker Engine + Portainer Community Edition
# 
# Requirements:
#   - Fedora 43
#   - Root/sudo privileges
#   - Internet connection
#
# Usage:
#   sudo ./2.sh
#
#############################################################################

set -e  # Exit on error
set -u  # Exit on undefined variable

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
PORTAINER_VERSION="latest"
PORTAINER_DATA_DIR="/var/lib/portainer"
PORTAINER_PORT="9000"
PORTAINER_PORT_HTTPS="9443"
MIN_DISK_SPACE_GB=10
MIN_RAM_GB=2

# State tracking for rollback
DOCKER_INSTALLED=false
DOCKER_STARTED=false
PORTAINER_INSTALLED=false

#############################################################################
# Helper Functions
#############################################################################

print_header() {
    echo -e "\n${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║        PORTAINER CE INSTALLER FOR FEDORA 43                   ║"
    echo "║        Docker Engine + Portainer Community Edition            ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_phase() {
    echo -e "\n${BLUE}[PHASE $1] $2${NC}"
}

print_step() {
    echo -e "${GREEN}[$1] $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root or with sudo"
        exit 1
    fi
}

check_fedora_version() {
    if [[ ! -f /etc/fedora-release ]]; then
        print_error "This script is designed for Fedora. Your system doesn't appear to be Fedora."
        exit 1
    fi
    
    local fedora_version=$(rpm -E %fedora)
    print_success "Detected Fedora version: $fedora_version"
    
    if [[ $fedora_version -lt 39 ]]; then
        print_warning "This script is optimized for Fedora 39+. Your version is $fedora_version"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

check_disk_space() {
    print_step "1/4" "Checking disk space..."
    
    local available_gb=$(df / | awk 'NR==2 {print int($4/1024/1024)}')
    
    if [[ $available_gb -lt $MIN_DISK_SPACE_GB ]]; then
        print_error "Insufficient disk space. Available: ${available_gb}GB, Required: ${MIN_DISK_SPACE_GB}GB"
        exit 1
    fi
    
    print_success "Disk space check passed (${available_gb}GB available)"
}

check_ram() {
    print_step "2/4" "Checking system RAM..."
    
    local total_ram_gb=$(free -g | awk '/^Mem:/ {print $2}')
    
    if [[ $total_ram_gb -lt $MIN_RAM_GB ]]; then
        print_warning "Low RAM detected: ${total_ram_gb}GB. Recommended: ${MIN_RAM_GB}GB+"
        print_warning "Docker and Portainer may run slowly"
    else
        print_success "RAM check passed (${total_ram_gb}GB available)"
    fi
}

check_internet() {
    print_step "3/4" "Checking internet connectivity..."
    
    if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        print_success "Internet connectivity verified"
    else
        print_error "No internet connection detected. This installer requires internet access."
        exit 1
    fi
}

check_ports() {
    print_step "4/4" "Checking port availability..."
    
    local ports_in_use=()
    
    if ss -tln | grep -q ":${PORTAINER_PORT} "; then
        ports_in_use+=("$PORTAINER_PORT")
    fi
    
    if ss -tln | grep -q ":${PORTAINER_PORT_HTTPS} "; then
        ports_in_use+=("$PORTAINER_PORT_HTTPS")
    fi
    
    if [[ ${#ports_in_use[@]} -gt 0 ]]; then
        print_warning "Ports already in use: ${ports_in_use[*]}"
        print_warning "These ports will be needed for Portainer"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Required ports are available"
    fi
}

cleanup_on_error() {
    print_error "Installation failed. Rolling back changes..."
    
    # Stop and remove Portainer if it was started
    if [[ "$PORTAINER_INSTALLED" == "true" ]]; then
        print_warning "Removing Portainer..."
        docker stop portainer 2>/dev/null || true
        docker rm portainer 2>/dev/null || true
        docker volume rm portainer_data 2>/dev/null || true
    fi
    
    # Stop Docker if it was started
    if [[ "$DOCKER_STARTED" == "true" ]]; then
        print_warning "Stopping Docker service..."
        systemctl stop docker 2>/dev/null || true
    fi
    
    # Remove Docker if it was installed
    if [[ "$DOCKER_INSTALLED" == "true" ]]; then
        print_warning "Removing Docker packages..."
        dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    fi
    
    print_error "Rollback completed. Please check the errors above and try again."
    exit 1
}

#############################################################################
# Docker Installation
#############################################################################

remove_old_docker() {
    print_step "1/6" "Removing old Docker versions (if any)..."
    
    local old_packages=(
        "docker"
        "docker-client"
        "docker-client-latest"
        "docker-common"
        "docker-latest"
        "docker-latest-logrotate"
        "docker-logrotate"
        "docker-selinux"
        "docker-engine-selinux"
        "docker-engine"
    )
    
    for pkg in "${old_packages[@]}"; do
        if dnf list installed "$pkg" &>/dev/null; then
            print_warning "Removing $pkg..."
            dnf remove -y "$pkg" || true
        fi
    done
    
    print_success "Old Docker versions removed (if any existed)"
}

install_dependencies() {
    print_step "2/6" "Installing dependencies..."
    
    dnf install -y dnf-plugins-core || {
        print_error "Failed to install dnf-plugins-core"
        cleanup_on_error
    }
    
    print_success "Dependencies installed"
}

add_docker_repository() {
    print_step "3/6" "Adding Docker repository..."
    
    # Fedora 43+ uses new DNF5 syntax
    # Try new syntax first, fall back to old syntax
    if dnf config-manager add-repo "$DOCKER_REPO_URL" 2>/dev/null; then
        print_success "Docker repository added (using dnf5 syntax)"
    elif dnf config-manager addrepo --from-repofile="$DOCKER_REPO_URL" 2>/dev/null; then
        print_success "Docker repository added (using dnf5 addrepo syntax)"
    elif dnf config-manager --add-repo "$DOCKER_REPO_URL" 2>/dev/null; then
        print_success "Docker repository added (using legacy syntax)"
    else
        # Manual method as fallback
        print_warning "Standard methods failed, using manual repository configuration..."
        
        local repo_file="/etc/yum.repos.d/docker-ce.repo"
        
        if curl -fsSL "$DOCKER_REPO_URL" -o "$repo_file"; then
            print_success "Docker repository added manually"
        else
            print_error "Failed to add Docker repository"
            cleanup_on_error
        fi
    fi
}

install_docker() {
    print_step "4/6" "Installing Docker Engine..."
    
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || {
        print_error "Failed to install Docker Engine"
        cleanup_on_error
    }
    
    DOCKER_INSTALLED=true
    print_success "Docker Engine installed"
}

start_docker() {
    print_step "5/6" "Starting and enabling Docker service..."
    
    systemctl start docker || {
        print_error "Failed to start Docker service"
        cleanup_on_error
    }
    
    DOCKER_STARTED=true
    
    systemctl enable docker || {
        print_warning "Failed to enable Docker service at boot"
    }
    
    # Verify Docker is running
    if systemctl is-active --quiet docker; then
        print_success "Docker service is running"
    else
        print_error "Docker service failed to start"
        cleanup_on_error
    fi
}

verify_docker() {
    print_step "6/6" "Verifying Docker installation..."
    
    local docker_version=$(docker --version 2>/dev/null || echo "")
    
    if [[ -z "$docker_version" ]]; then
        print_error "Docker installation verification failed"
        cleanup_on_error
    fi
    
    print_success "Docker installed: $docker_version"
    
    # Test with hello-world
    if docker run --rm hello-world &>/dev/null; then
        print_success "Docker test run successful"
    else
        print_warning "Docker installed but test run failed. This may be normal on first install."
    fi
}

#############################################################################
# Portainer Installation
#############################################################################

install_portainer() {
    print_phase "2" "Installing Portainer Community Edition..."
    
    print_step "1/4" "Creating Portainer volume..."
    docker volume create portainer_data || {
        print_error "Failed to create Portainer volume"
        cleanup_on_error
    }
    print_success "Portainer volume created"
    
    print_step "2/4" "Pulling Portainer image..."
    docker pull portainer/portainer-ce:${PORTAINER_VERSION} || {
        print_error "Failed to pull Portainer image"
        cleanup_on_error
    }
    print_success "Portainer image pulled"
    
    print_step "3/4" "Starting Portainer container..."
    
    # Check if Portainer is already running
    if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
        print_warning "Portainer container already exists. Removing old container..."
        docker stop portainer 2>/dev/null || true
        docker rm portainer 2>/dev/null || true
    fi
    
    docker run -d \
        --name portainer \
        --restart=always \
        -p ${PORTAINER_PORT_HTTPS}:9443 \
        -p ${PORTAINER_PORT}:9000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:${PORTAINER_VERSION} || {
        print_error "Failed to start Portainer container"
        cleanup_on_error
    }
    
    PORTAINER_INSTALLED=true
    print_success "Portainer container started"
    
    print_step "4/4" "Verifying Portainer installation..."
    
    # Wait for Portainer to start
    sleep 5
    
    if docker ps --format '{{.Names}}' | grep -q '^portainer$'; then
        print_success "Portainer is running"
    else
        print_error "Portainer failed to start"
        docker logs portainer
        cleanup_on_error
    fi
}

#############################################################################
# Post-Installation
#############################################################################

configure_firewall() {
    print_phase "3" "Configuring firewall (optional)..."
    
    if command -v firewall-cmd &>/dev/null; then
        if systemctl is-active --quiet firewalld; then
            print_step "1/2" "Opening Portainer ports in firewall..."
            
            firewall-cmd --permanent --add-port=${PORTAINER_PORT}/tcp || print_warning "Failed to open port ${PORTAINER_PORT}"
            firewall-cmd --permanent --add-port=${PORTAINER_PORT_HTTPS}/tcp || print_warning "Failed to open port ${PORTAINER_PORT_HTTPS}"
            firewall-cmd --reload || print_warning "Failed to reload firewall"
            
            print_success "Firewall configured"
        else
            print_warning "Firewalld is not running. Skipping firewall configuration."
        fi
    else
        print_warning "Firewalld not found. Skipping firewall configuration."
    fi
}

add_user_to_docker_group() {
    print_step "1/1" "Adding current user to docker group..."
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        usermod -aG docker "$SUDO_USER" || print_warning "Failed to add $SUDO_USER to docker group"
        print_success "User $SUDO_USER added to docker group"
        print_warning "Note: User $SUDO_USER needs to log out and back in for group changes to take effect"
    else
        print_warning "No SUDO_USER detected. You may need to manually add your user to the docker group:"
        echo "  sudo usermod -aG docker \$USER"
    fi
}

print_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    
    echo -e "\n${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                   INSTALLATION COMPLETE!                      ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo -e "${BLUE}Docker Information:${NC}"
    docker --version
    docker compose version
    
    echo -e "\n${BLUE}Portainer Access:${NC}"
    echo "  HTTP:  http://${server_ip}:${PORTAINER_PORT}"
    echo "  HTTPS: https://${server_ip}:${PORTAINER_PORT_HTTPS}"
    echo ""
    echo "  Local: http://localhost:${PORTAINER_PORT}"
    
    echo -e "\n${BLUE}Next Steps:${NC}"
    echo "  1. Open Portainer in your browser (use one of the URLs above)"
    echo "  2. Create your admin account on first login"
    echo "  3. Start deploying your containers!"
    
    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo "  Check Docker status:    systemctl status docker"
    echo "  Check Portainer status: docker ps | grep portainer"
    echo "  View Portainer logs:    docker logs portainer"
    echo "  Restart Portainer:      docker restart portainer"
    
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo -e "\n${YELLOW}⚠️  IMPORTANT:${NC}"
        echo "  User '$SUDO_USER' has been added to the docker group."
        echo "  Log out and back in for this to take effect, or run:"
        echo "    newgrp docker"
    fi
}

#############################################################################
# Main Execution
#############################################################################

main() {
    # Trap errors
    trap cleanup_on_error ERR
    
    print_header
    
    # Pre-flight checks
    check_root
    check_fedora_version
    
    # System requirements check
    print_phase "0" "Checking system requirements..."
    check_disk_space
    check_ram
    check_internet
    check_ports
    
    # Phase 1: Install Docker
    print_phase "1" "Installing Docker Engine for Fedora 43..."
    remove_old_docker
    install_dependencies
    add_docker_repository
    install_docker
    start_docker
    verify_docker
    
    # Phase 2: Install Portainer
    install_portainer
    
    # Phase 3: Post-installation
    configure_firewall
    add_user_to_docker_group
    
    # Summary
    print_summary
    
    echo -e "\n${GREEN}Installation completed successfully!${NC}\n"
}

# Run main function
main "$@"
