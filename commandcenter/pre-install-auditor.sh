#!/bin/bash
################################################################################
# Digital Renegade Pre-Install Auditor
#
# Purpose: Validates system requirements, cleans filesystem, checks structure,
#          and prepares environment for Digital Renegade deployment
#
# Usage: sudo bash pre-install-auditor.sh [--auto-fix] [--deep-clean]
#
# Options:
#   --auto-fix     Automatically fix issues where possible
#   --deep-clean   Perform aggressive cleanup (removes ALL Docker data)
#   --dry-run      Check only, don't modify anything
################################################################################

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Script configuration
LOG_FILE="/var/log/renegade_auditor.log"
REPORT_FILE="/tmp/renegade_audit_report.txt"
BACKUP_DIR="/var/backups/renegade_preinstall_$(date +%Y%m%d_%H%M%S)"

# Flags
AUTO_FIX=false
DEEP_CLEAN=false
DRY_RUN=false

# Counters
WARNINGS=0
ERRORS=0
FIXED=0

################################################################################
# Utility Functions
################################################################################

log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ${NC} $*" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}✓${NC} $*" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*" | tee -a "$LOG_FILE"
    ((WARNINGS++))
}

error() {
    echo -e "${RED}✗${NC} $*" | tee -a "$LOG_FILE"
    ((ERRORS++))
}

fixed() {
    echo -e "${GREEN}🔧${NC} $*" | tee -a "$LOG_FILE"
    ((FIXED++))
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD} $*${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "Section: $*"
}

prompt_confirm() {
    if [[ "$AUTO_FIX" == "true" ]] || [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi

    read -p "$(echo -e ${YELLOW}$1 [y/N]:${NC}) " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

################################################################################
# Argument Parsing
################################################################################

parse_args() {
    for arg in "$@"; do
        case $arg in
            --auto-fix)
                AUTO_FIX=true
                info "Auto-fix mode enabled"
                ;;
            --deep-clean)
                DEEP_CLEAN=true
                warning "Deep clean mode enabled - will remove ALL Docker data"
                ;;
            --dry-run)
                DRY_RUN=true
                info "Dry-run mode - no changes will be made"
                ;;
            *)
                error "Unknown argument: $arg"
                echo "Usage: $0 [--auto-fix] [--deep-clean] [--dry-run]"
                exit 1
                ;;
        esac
    done
}

################################################################################
# System Requirements Check
################################################################################

check_root() {
    section "Checking Privileges"
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        echo "Please run: sudo bash $0"
        exit 1
    fi
    success "Running as root"
}

check_os_version() {
    section "Checking OS Version"

    if [[ ! -f /etc/os-release ]]; then
        error "/etc/os-release not found"
        return 1
    fi

    source /etc/os-release

    info "Detected: $PRETTY_NAME"

    # Check if Ubuntu
    if [[ "$ID" != "ubuntu" ]]; then
        warning "Not running Ubuntu - Digital Renegade is optimized for Ubuntu 25.10"
    fi

    # Check version
    if [[ "$VERSION_ID" == "25.10" ]]; then
        success "Ubuntu 25.10 'Questing Quokka' detected - optimal version"
    elif [[ "$VERSION_ID" == "24.04" ]]; then
        warning "Ubuntu 24.04 LTS detected - compatible but missing Ubuntu 25.10 features (Rust coreutils, NVIDIA 580 drivers)"
    elif [[ "$VERSION_ID" == "22.04" ]]; then
        warning "Ubuntu 22.04 LTS detected - will work but consider upgrading to 25.10"
    else
        warning "Ubuntu $VERSION_ID detected - may have compatibility issues"
    fi

    # Check if it's a server or desktop installation
    if dpkg -l | grep -q ubuntu-desktop; then
        info "Desktop environment detected"
    else
        info "Server installation detected (headless)"
    fi
}

check_hardware() {
    section "Checking Hardware Requirements"

    # CPU Check
    cpu_cores=$(nproc)
    info "CPU Cores: $cpu_cores"

    if [[ $cpu_cores -lt 8 ]]; then
        warning "Less than 8 CPU cores detected - Digital Renegade recommends 8+ cores"
    else
        success "CPU cores: $cpu_cores (sufficient)"
    fi

    # RAM Check
    total_ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    total_ram_gb=$((total_ram_kb / 1024 / 1024))

    info "Total RAM: ${total_ram_gb}GB"

    if [[ $total_ram_gb -lt 32 ]]; then
        error "Less than 32GB RAM detected - Digital Renegade requires minimum 32GB"
    elif [[ $total_ram_gb -lt 64 ]]; then
        warning "Less than 64GB RAM - some features may be limited"
    else
        success "RAM: ${total_ram_gb}GB (excellent)"
    fi

    # Disk Space Check
    info "Checking disk space..."

    root_available=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
    info "Root partition available: ${root_available}GB"

    if [[ $root_available -lt 100 ]]; then
        error "Less than 100GB available on root partition - need minimum 100GB for AI models"
    elif [[ $root_available -lt 500 ]]; then
        warning "Less than 500GB available - recommend 500GB+ for model storage"
    else
        success "Disk space: ${root_available}GB (sufficient)"
    fi

    # Check for SSD
    root_device=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
    if [[ -f /sys/block/$(basename $root_device)/queue/rotational ]]; then
        rotation=$(cat /sys/block/$(basename $root_device)/queue/rotational)
        if [[ $rotation -eq 0 ]]; then
            success "SSD detected for root partition (optimal for AI workloads)"
        else
            warning "HDD detected for root partition - SSD recommended for better performance"
        fi
    fi
}

check_gpu() {
    section "Checking GPU Availability"

    if ! command -v lspci &> /dev/null; then
        warning "lspci not found - installing pciutils"
        if [[ "$DRY_RUN" == "false" ]]; then
            apt-get update -qq
            apt-get install -y pciutils
        fi
    fi

    # Check for NVIDIA GPU
    if lspci | grep -i nvidia &> /dev/null; then
        gpu_info=$(lspci | grep -i nvidia | head -1)
        success "NVIDIA GPU detected: $gpu_info"

        # Check NVIDIA driver
        if command -v nvidia-smi &> /dev/null; then
            driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1)
            success "NVIDIA driver installed: $driver_version"

            # Check VRAM
            vram_mb=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader | head -1 | awk '{print $1}')
            vram_gb=$((vram_mb / 1024))

            info "GPU VRAM: ${vram_gb}GB"

            if [[ $vram_gb -lt 8 ]]; then
                warning "Less than 8GB VRAM - will limit model sizes"
            elif [[ $vram_gb -ge 12 ]]; then
                success "VRAM: ${vram_gb}GB (excellent for vision models)"
            fi

            # Check CUDA version
            cuda_version=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}')
            if [[ -n "$cuda_version" ]]; then
                success "CUDA Version: $cuda_version"
            fi
        else
            warning "NVIDIA GPU detected but nvidia-smi not found - driver may not be installed"
        fi
    else
        warning "No NVIDIA GPU detected - Digital Renegade optimized for NVIDIA GPUs"
        info "Checking for AMD GPU..."

        if lspci | grep -i amd | grep -i vga &> /dev/null; then
            info "AMD GPU detected - ROCm may be used but NVIDIA is recommended"
        fi
    fi
}

check_network() {
    section "Checking Network Configuration"

    # Check internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        success "Internet connectivity available"
    else
        error "No internet connectivity - required for pulling Docker images"
    fi

    # Check local network
    local_ip=$(hostname -I | awk '{print $1}')
    info "Primary IP: $local_ip"

    # Check if IP is in expected range (192.168.1.x)
    if [[ "$local_ip" =~ ^192\.168\.1\. ]]; then
        success "IP in expected subnet (192.168.1.0/24)"
    else
        warning "IP not in 192.168.1.0/24 subnet - may need configuration adjustments"
    fi

    # Check for multiple NICs
    nic_count=$(ip -o link show | grep -v "lo:" | grep "state UP" | wc -l)
    info "Active NICs: $nic_count"

    if [[ $nic_count -ge 2 ]]; then
        success "Multiple NICs detected - can enable NIC bonding for performance"
    fi
}

################################################################################
# Service Conflict Checks
################################################################################

check_port_conflicts() {
    section "Checking for Port Conflicts"

    # Critical ports for Digital Renegade
    declare -A PORTS=(
        [9000]="Portainer"
        [9443]="Portainer (SSL)"
        [11434]="Ollama (Brain)"
        [11435]="Ollama (Eyes)"
        [3000]="Open WebUI"
        [6333]="Qdrant HTTP"
        [6334]="Qdrant gRPC"
        [8188]="ComfyUI"
        [8123]="Home Assistant"
        [1880]="Node-RED"
        [5432]="PostgreSQL"
        [6379]="Redis"
        [8092]="Persona Manager"
    )

    for port in "${!PORTS[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
            warning "Port $port (${PORTS[$port]}) is already in use"

            # Try to identify what's using it
            if command -v lsof &> /dev/null; then
                process=$(lsof -i :$port -t 2>/dev/null | head -1)
                if [[ -n "$process" ]]; then
                    process_name=$(ps -p $process -o comm= 2>/dev/null)
                    info "  └─ Used by: $process_name (PID: $process)"
                fi
            fi
        else
            success "Port $port (${PORTS[$port]}) available"
        fi
    done
}

check_existing_services() {
    section "Checking for Conflicting Services"

    # Check for existing Ollama installation
    if systemctl is-active --quiet ollama 2>/dev/null; then
        warning "Ollama systemd service is running - may conflict with containerized version"
        if prompt_confirm "Stop Ollama system service?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                systemctl stop ollama
                systemctl disable ollama
                fixed "Stopped and disabled Ollama system service"
            else
                info "Would stop Ollama service (dry-run)"
            fi
        fi
    fi

    # Check for existing Docker containers
    if command -v docker &> /dev/null; then
        running_containers=$(docker ps -q | wc -l)
        if [[ $running_containers -gt 0 ]]; then
            warning "$running_containers Docker containers currently running"
            docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        else
            success "No running Docker containers"
        fi
    fi

    # Check for existing Portainer
    if docker ps -a 2>/dev/null | grep -q portainer; then
        warning "Existing Portainer container found"
        if prompt_confirm "Remove existing Portainer container?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                docker stop portainer 2>/dev/null || true
                docker rm portainer 2>/dev/null || true
                fixed "Removed existing Portainer container"
            else
                info "Would remove Portainer (dry-run)"
            fi
        fi
    fi
}

################################################################################
# Docker Environment Checks
################################################################################

check_docker() {
    section "Checking Docker Installation"

    if ! command -v docker &> /dev/null; then
        warning "Docker not installed"
        return 1
    fi

    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    success "Docker installed: $docker_version"

    # Check Docker daemon
    if ! systemctl is-active --quiet docker; then
        error "Docker daemon not running"
        if prompt_confirm "Start Docker daemon?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                systemctl start docker
                systemctl enable docker
                fixed "Started Docker daemon"
            fi
        fi
    else
        success "Docker daemon running"
    fi

    # Check Docker Compose
    if docker compose version &> /dev/null; then
        compose_version=$(docker compose version --short)
        success "Docker Compose installed: $compose_version"
    else
        warning "Docker Compose plugin not found"
    fi

    # Check NVIDIA Container Toolkit
    if docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
        success "NVIDIA Container Toolkit working"
    else
        warning "NVIDIA Container Toolkit not configured or not working"
    fi

    # Check Docker daemon config
    if [[ -f /etc/docker/daemon.json ]]; then
        info "Docker daemon.json exists"

        if grep -q "nvidia" /etc/docker/daemon.json; then
            success "NVIDIA runtime configured in daemon.json"
        else
            warning "NVIDIA runtime not found in daemon.json"
        fi
    else
        warning "No /etc/docker/daemon.json - may need NVIDIA runtime configuration"
    fi
}

check_docker_storage() {
    section "Checking Docker Storage"

    if ! command -v docker &> /dev/null; then
        return 1
    fi

    docker_root=$(docker info 2>/dev/null | grep "Docker Root Dir" | awk '{print $4}')
    info "Docker root: $docker_root"

    if [[ -d "$docker_root" ]]; then
        docker_size=$(du -sh "$docker_root" 2>/dev/null | awk '{print $1}')
        info "Docker data size: $docker_size"

        # Check available space
        docker_available=$(df -BG "$docker_root" | tail -1 | awk '{print $4}' | sed 's/G//')

        if [[ $docker_available -lt 50 ]]; then
            warning "Less than 50GB available for Docker - recommend 100GB+"
        else
            success "Docker storage: ${docker_available}GB available"
        fi
    fi

    # Check for dangling images/volumes
    dangling_images=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    dangling_volumes=$(docker volume ls -f "dangling=true" -q 2>/dev/null | wc -l)

    if [[ $dangling_images -gt 0 ]]; then
        info "$dangling_images dangling images found"
    fi

    if [[ $dangling_volumes -gt 0 ]]; then
        info "$dangling_volumes dangling volumes found"
    fi
}

################################################################################
# Filesystem Checks & Cleanup
################################################################################

check_directory_structure() {
    section "Checking Directory Structure"

    # Required directories for Digital Renegade
    declare -a REQUIRED_DIRS=(
        "/home/user/brain"
        "/home/user/brain/config"
        "/home/user/brain/config/personas"
        "/home/user/brain/config/operational_modes"
        "/home/user/brain/agents"
    )

    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            success "Directory exists: $dir"
        else
            warning "Directory missing: $dir"

            if prompt_confirm "Create directory $dir?"; then
                if [[ "$DRY_RUN" == "false" ]]; then
                    mkdir -p "$dir"
                    chown -R user:user "$dir" 2>/dev/null || true
                    fixed "Created directory: $dir"
                fi
            fi
        fi
    done

    # Check for required files
    declare -a REQUIRED_FILES=(
        "/home/user/brain/portainer-stack-renegade.yml"
        "/home/user/brain/config/personas/renegade_master.json"
        "/home/user/brain/config/operational_modes/mode_definitions.json"
    )

    for file in "${REQUIRED_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            success "File exists: $file"
        else
            error "Required file missing: $file"
        fi
    done
}

check_mount_points() {
    section "Checking Mount Points"

    # Check for NFS mounts
    if grep -q nfs /etc/fstab; then
        info "NFS mounts found in /etc/fstab"

        # Check if mounted
        if mount | grep -q "type nfs"; then
            success "NFS shares are mounted"
            mount | grep "type nfs"
        else
            warning "NFS entries in fstab but not mounted"

            if prompt_confirm "Attempt to mount NFS shares?"; then
                if [[ "$DRY_RUN" == "false" ]]; then
                    mount -a -t nfs || warning "Some NFS mounts failed"
                fi
            fi
        fi
    fi

    # Check for expected storage paths
    declare -A STORAGE_PATHS=(
        [/mnt/warm]="Warm storage for vector databases"
        [/mnt/hot]="Hot storage for active data"
        [/mnt/cold]="Cold storage for archives"
    )

    for path in "${!STORAGE_PATHS[@]}"; do
        if [[ -d "$path" ]]; then
            available=$(df -BG "$path" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
            info "$path exists (${available}GB available) - ${STORAGE_PATHS[$path]}"
        else
            info "$path not found - ${STORAGE_PATHS[$path]}"
        fi
    done
}

################################################################################
# Cleanup Functions
################################################################################

cleanup_docker() {
    section "Docker Cleanup"

    if ! command -v docker &> /dev/null; then
        info "Docker not installed, skipping cleanup"
        return 0
    fi

    info "Analyzing Docker resource usage..."
    docker system df

    if [[ "$DEEP_CLEAN" == "true" ]]; then
        warning "DEEP CLEAN MODE: This will remove ALL Docker data"

        if prompt_confirm "Are you ABSOLUTELY SURE? This will delete all containers, images, volumes, and networks"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                info "Stopping all containers..."
                docker stop $(docker ps -aq) 2>/dev/null || true

                info "Removing all containers..."
                docker rm $(docker ps -aq) 2>/dev/null || true

                info "Removing all images..."
                docker rmi $(docker images -q) -f 2>/dev/null || true

                info "Removing all volumes..."
                docker volume rm $(docker volume ls -q) 2>/dev/null || true

                info "Pruning networks..."
                docker network prune -f

                fixed "Deep clean completed"
            else
                info "Would perform deep clean (dry-run)"
            fi
        fi
    else
        # Standard cleanup
        if prompt_confirm "Remove dangling images and volumes?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                docker image prune -f
                docker volume prune -f
                docker network prune -f
                fixed "Cleaned up dangling Docker resources"
            else
                info "Would clean dangling resources (dry-run)"
            fi
        fi

        if prompt_confirm "Remove stopped containers?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                docker container prune -f
                fixed "Removed stopped containers"
            else
                info "Would remove stopped containers (dry-run)"
            fi
        fi
    fi

    info "Docker resource usage after cleanup:"
    docker system df
}

cleanup_system_logs() {
    section "System Log Cleanup"

    journal_size=$(journalctl --disk-usage | grep -oP '\d+\.\d+[GM]' | head -1)
    info "Journal size: $journal_size"

    if prompt_confirm "Clean up system journals older than 7 days?"; then
        if [[ "$DRY_RUN" == "false" ]]; then
            journalctl --vacuum-time=7d
            fixed "Cleaned system journals"
        else
            info "Would clean journals (dry-run)"
        fi
    fi

    # Clean apt cache
    if [[ -d /var/cache/apt/archives ]]; then
        apt_cache_size=$(du -sh /var/cache/apt/archives | awk '{print $1}')
        info "APT cache size: $apt_cache_size"

        if prompt_confirm "Clean APT cache?"; then
            if [[ "$DRY_RUN" == "false" ]]; then
                apt-get clean
                fixed "Cleaned APT cache"
            else
                info "Would clean APT cache (dry-run)"
            fi
        fi
    fi
}

cleanup_temp_files() {
    section "Temporary File Cleanup"

    tmp_size=$(du -sh /tmp 2>/dev/null | awk '{print $1}')
    info "/tmp size: $tmp_size"

    # Find large files in /tmp
    info "Large files in /tmp (>100MB):"
    find /tmp -type f -size +100M -exec ls -lh {} \; 2>/dev/null | awk '{print $9, $5}' || info "  None found"

    if prompt_confirm "Clean /tmp directory?"; then
        if [[ "$DRY_RUN" == "false" ]]; then
            find /tmp -type f -atime +7 -delete 2>/dev/null || true
            fixed "Cleaned old files from /tmp"
        else
            info "Would clean /tmp (dry-run)"
        fi
    fi
}

################################################################################
# Security Checks
################################################################################

check_security() {
    section "Security Checks"

    # Check firewall
    if command -v ufw &> /dev/null; then
        ufw_status=$(ufw status | head -1)
        info "UFW status: $ufw_status"

        if ufw status | grep -q "inactive"; then
            warning "Firewall is disabled - consider enabling for production"
        fi
    else
        info "UFW not installed"
    fi

    # Check for updates
    if command -v apt &> /dev/null; then
        info "Checking for system updates..."
        apt update -qq 2>/dev/null || true

        updates_available=$(apt list --upgradable 2>/dev/null | grep -c upgradable || true)

        if [[ $updates_available -gt 0 ]]; then
            warning "$updates_available package updates available"
        else
            success "System is up to date"
        fi
    fi

    # Check SSH security
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
            warning "SSH root login is enabled - security risk"
        fi

        if grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
            info "SSH password authentication enabled - consider key-only auth"
        fi
    fi
}

################################################################################
# Backup Functions
################################################################################

create_backup() {
    section "Creating Backup"

    if [[ "$DRY_RUN" == "true" ]]; then
        info "Would create backup at $BACKUP_DIR (dry-run)"
        return 0
    fi

    info "Creating backup at: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Backup existing configurations
    if [[ -f /home/user/brain/docker-compose.yml ]]; then
        cp /home/user/brain/docker-compose.yml "$BACKUP_DIR/"
        info "Backed up docker-compose.yml"
    fi

    if [[ -d /home/user/brain/config ]]; then
        cp -r /home/user/brain/config "$BACKUP_DIR/"
        info "Backed up config directory"
    fi

    # Backup Docker volumes list
    if command -v docker &> /dev/null; then
        docker volume ls > "$BACKUP_DIR/docker_volumes.txt"
        info "Backed up Docker volume list"
    fi

    # Backup network configuration
    ip addr > "$BACKUP_DIR/network_config.txt"

    success "Backup created at: $BACKUP_DIR"
}

################################################################################
# Report Generation
################################################################################

generate_report() {
    section "Generating Audit Report"

    cat > "$REPORT_FILE" << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Digital Renegade Pre-Install Audit Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Generated: $(date)
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')

SUMMARY
━━━━━━━
✓ Checks Passed: $((FIXED + WARNINGS + ERRORS > 0 ? 1 : 0))
⚠ Warnings: $WARNINGS
✗ Errors: $ERRORS
🔧 Issues Fixed: $FIXED

SYSTEM INFORMATION
━━━━━━━━━━━━━━━━━━
OS: $(source /etc/os-release && echo "$PRETTY_NAME")
Kernel: $(uname -r)
CPU Cores: $(nproc)
RAM: $(grep MemTotal /proc/meminfo | awk '{print $2/1024/1024}')GB
Disk Available: $(df -BG / | tail -1 | awk '{print $4}')

GPU INFORMATION
━━━━━━━━━━━━━━━
$(lspci | grep -i vga || echo "No GPU info available")
$(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null || echo "NVIDIA driver not installed")

DOCKER STATUS
━━━━━━━━━━━━━
$(docker --version 2>/dev/null || echo "Docker not installed")
$(docker compose version 2>/dev/null || echo "Docker Compose not installed")
Running Containers: $(docker ps -q 2>/dev/null | wc -l)

RECOMMENDATIONS
━━━━━━━━━━━━━━━
EOF

    if [[ $ERRORS -gt 0 ]]; then
        echo "⚠ CRITICAL: $ERRORS errors must be fixed before installation" >> "$REPORT_FILE"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        echo "⚠ $WARNINGS warnings should be reviewed" >> "$REPORT_FILE"
    fi

    if [[ $ERRORS -eq 0 ]] && [[ $WARNINGS -eq 0 ]]; then
        echo "✓ System ready for Digital Renegade deployment!" >> "$REPORT_FILE"
    fi

    echo "" >> "$REPORT_FILE"
    echo "Full log available at: $LOG_FILE" >> "$REPORT_FILE"

    if [[ -d "$BACKUP_DIR" ]]; then
        echo "Backup created at: $BACKUP_DIR" >> "$REPORT_FILE"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$REPORT_FILE"

    cat "$REPORT_FILE"

    success "Full report saved to: $REPORT_FILE"
}

################################################################################
# Main Execution
################################################################################

main() {
    clear

    echo -e "${MAGENTA}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║        🔍 DIGITAL RENEGADE PRE-INSTALL AUDITOR 🔍           ║"
    echo "║                                                               ║"
    echo "║  Validates, cleans, and prepares system for deployment       ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Initialize log
    : > "$LOG_FILE"
    log "Digital Renegade Pre-Install Auditor started"

    # Parse arguments
    parse_args "$@"

    # Create backup first
    create_backup

    # Run all checks
    check_root
    check_os_version
    check_hardware
    check_gpu
    check_network
    check_port_conflicts
    check_existing_services
    check_docker
    check_docker_storage
    check_directory_structure
    check_mount_points
    check_security

    # Cleanup operations
    if [[ "$DRY_RUN" == "false" ]]; then
        cleanup_docker
        cleanup_system_logs
        cleanup_temp_files
    fi

    # Generate final report
    generate_report

    echo ""
    section "Audit Complete"

    if [[ $ERRORS -gt 0 ]]; then
        error "$ERRORS critical errors found - must be fixed before installation"
        exit 1
    elif [[ $WARNINGS -gt 0 ]]; then
        warning "$WARNINGS warnings found - review before proceeding"
        exit 0
    else
        success "System ready for Digital Renegade deployment!"
        info "Next step: sudo bash install-renegade-portainer.sh"
        exit 0
    fi
}

# Run main function
main "$@"
