#!/bin/bash
# ==============================================================================
# PROJECT CHIMERA: PHASE III - "RED QUEEN" INITIALIZATION
# Target: Pop!_OS 24.04 | Intel Ultra 7 265F | AMD 7900 XT
# Purpose: Fix libcholmod3 dependency hell & Install ROCm RDNA3 Stack
# ==============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${CYAN}[CHIMERA]${NC} $*"
}

success() {
    echo -e "${GREEN}✅${NC} $*"
}

warn() {
    echo -e "${YELLOW}⚠️${NC} $*"
}

error() {
    echo -e "${RED}❌${NC} $*"
}

# Check root
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
    exit 1
fi

echo -e "${CYAN}"
cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║  PROJECT CHIMERA - RED QUEEN INITIALIZATION                   ║
║  Pop!_OS 24.04 | AMD 7900 XT | ROCm Stack                     ║
╚═══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. FIX LIBCHOLMOD3 DEPENDENCY ISSUE
# ------------------------------------------------------------------------------
log "Resolving 'libcholmod3 not installable' error..."

# Clean up the broken state first
sudo apt-get clean
sudo apt-get autoremove -y
sudo dpkg --configure -a || true

# Check if libcholmod3 is already available in current repos
if apt-cache show libcholmod3 &>/dev/null; then
    log "libcholmod3 found in current repositories, installing directly..."
    sudo apt-get install -y libcholmod3 libsuitesparse-dev || true
else
    # Inject Ubuntu 22.04 (Jammy) Universe repo TEMPORARILY to get the missing library
    # This is safer than downloading random .debs because it pulls dependencies
    warn "libcholmod3 not found in current repos, temporarily adding Jammy Universe..."

    echo "deb http://archive.ubuntu.com/ubuntu/ jammy universe" | sudo tee /etc/apt/sources.list.d/chimera-temp-jammy.list

    # Update and install ONLY the missing math libraries
    sudo apt-get update
    sudo apt-get install -y libcholmod3 libsuitesparse-dev || {
        error "Failed to install libcholmod3"
        # Clean up temp repo even on failure
        sudo rm -f /etc/apt/sources.list.d/chimera-temp-jammy.list
        sudo apt-get update
        exit 1
    }

    # IMMEDIATELY remove the temporary repo to prevent system corruption
    sudo rm -f /etc/apt/sources.list.d/chimera-temp-jammy.list
    sudo apt-get update
fi

success "[FIX] Dependency issue resolved."

# ------------------------------------------------------------------------------
# 2. PURGE CONFLICTING DRIVERS (NVIDIA/OLD AMD)
# ------------------------------------------------------------------------------
log "Purging any existing GPU stacks..."

# Remove NVIDIA components if present (safe to ignore errors if not installed)
sudo apt-get purge -y "*nvidia*" "cuda*" "nsight*" 2>/dev/null || true

# Remove old ROCm/AMD components
sudo apt-get purge -y "rocm*" "amdgpu-install*" 2>/dev/null || true

sudo apt-get autoremove -y

success "[CLEAN] Conflicting drivers purged."

# ------------------------------------------------------------------------------
# 3. INSTALL AMD ROCm STACK (Specific for 7900 XT - RDNA3/Navi 31)
# ------------------------------------------------------------------------------
log "Installing AMD ROCm 6.1.x for Ubuntu 24.04 (Noble)..."

# Get the current Ubuntu/Pop!_OS codename
CODENAME=$(lsb_release -cs)
log "Detected OS codename: $CODENAME"

# For Pop!_OS 24.04, we use the noble ROCm packages
# If the codename isn't recognized by AMD, fall back to noble
case "$CODENAME" in
    noble|mantic|lunar)
        AMD_CODENAME="noble"
        ;;
    jammy)
        AMD_CODENAME="jammy"
        ;;
    *)
        warn "Unknown codename '$CODENAME', defaulting to noble..."
        AMD_CODENAME="noble"
        ;;
esac

# Download the installer specific to the detected version
ROCM_VERSION="6.1.3"
ROCM_PKG="amdgpu-install_6.1.60103-1_all.deb"
ROCM_URL="https://repo.radeon.com/amdgpu-install/${ROCM_VERSION}/ubuntu/${AMD_CODENAME}/${ROCM_PKG}"

log "Downloading ROCm installer from: $ROCM_URL"

# Create temp directory for downloads
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if ! wget -q --show-progress "$ROCM_URL"; then
    error "Failed to download ROCm installer. Check your internet connection."
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Install the amdgpu-install package
log "Installing amdgpu-install package..."
sudo apt-get install -y "./${ROCM_PKG}"

# Clean up downloaded file
rm -f "${ROCM_PKG}"
cd /
rm -rf "$TEMP_DIR"

# Run the installer
# --usecase=rocm: Installs compute stack
# --no-dkms: CRITICAL for Pop!_OS to avoid breaking the custom kernel
log "Running amdgpu-install (this may take 5-10 minutes)..."
sudo amdgpu-install -y --usecase=rocm,hip,hiplibsdk --no-dkms || {
    error "amdgpu-install failed. Check /var/log/amdgpu-install.log for details."
    exit 1
}

success "[INSTALL] ROCm stack installed."

# Add user to render/video groups (Required for GPU access)
CURRENT_USER="${SUDO_USER:-$USER}"
log "Adding user '$CURRENT_USER' to render and video groups..."
sudo usermod -aG render,video "$CURRENT_USER"

success "[GROUPS] User added to render and video groups."

# ------------------------------------------------------------------------------
# 4. CONFIGURE RDNA3 OVERRIDES (The "Magic" Sauce for 7900 XT)
# ------------------------------------------------------------------------------
log "Applying RDNA3 (Navi 31 / gfx1100) overrides..."

# Create a permanent environment variable profile for ROCm
# This forces the system to treat the 7900 XT as compatible enterprise hardware
cat > /etc/profile.d/rocm-chimera.sh << 'EOF'
# Project Chimera - ROCm Configuration for AMD RDNA3 (7900 XT)
# This overrides the GFX version to enable ROCm support on consumer GPUs
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export ROCM_PATH=/opt/rocm
export PATH=$PATH:/opt/rocm/bin:/opt/rocm/hip/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib:/opt/rocm/hip/lib
EOF

chmod 644 /etc/profile.d/rocm-chimera.sh

success "[CONFIG] RDNA3 environment variables configured."

# ------------------------------------------------------------------------------
# 5. DOCKER SETUP
# ------------------------------------------------------------------------------
log "Verifying Docker permissions..."

# Check if docker group exists, create if not
if ! getent group docker > /dev/null; then
    log "Creating docker group..."
    sudo groupadd docker
fi

# Add user to docker group
sudo usermod -aG docker "$CURRENT_USER"

success "[DOCKER] Docker permissions configured."

# ------------------------------------------------------------------------------
# 6. VERIFY INSTALLATION
# ------------------------------------------------------------------------------
log "Verifying installation..."

# Check if ROCm tools are available
if command -v rocm-smi &>/dev/null; then
    success "rocm-smi is available"
    log "GPU Status:"
    rocm-smi --showid --showproductname 2>/dev/null || true
elif command -v rocminfo &>/dev/null; then
    success "rocminfo is available"
    log "ROCm Info:"
    rocminfo 2>/dev/null | head -20 || true
else
    warn "ROCm tools not found in PATH. They may be available after reboot."
fi

# Check for GPU devices
if [[ -e /dev/kfd ]]; then
    success "ROCm KFD device detected (/dev/kfd)"
else
    warn "ROCm KFD device not found. May require reboot."
fi

if [[ -e /dev/dri/renderD128 ]]; then
    success "Render node detected (/dev/dri/renderD128)"
else
    warn "Render node not found. May require reboot."
fi

# ------------------------------------------------------------------------------
# 7. SUMMARY
# ------------------------------------------------------------------------------
echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}              PREP COMPLETE - RED QUEEN INITIALIZED              ${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}What was installed:${NC}"
echo "  • libcholmod3 and libsuitesparse-dev (dependency fix)"
echo "  • AMD ROCm 6.1.3 stack (rocm, hip, hiplibsdk)"
echo "  • RDNA3/gfx1100 environment overrides"
echo "  • User group permissions (render, video, docker)"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. ${RED}REBOOT NOW${NC} for driver and group changes to take effect"
echo "     Run: ${YELLOW}sudo reboot${NC}"
echo ""
echo "  2. After reboot, verify GPU access:"
echo "     Run: ${YELLOW}rocm-smi${NC}"
echo "     Run: ${YELLOW}rocminfo${NC}"
echo ""
echo "  3. Test Docker GPU access:"
echo "     Run: ${YELLOW}docker run --rm --device=/dev/kfd --device=/dev/dri --group-add video rocm/pytorch:latest rocm-smi${NC}"
echo ""
echo "  4. Deploy Chimera stack:"
echo "     Run: ${YELLOW}cd /home/user/brain && docker compose up -d${NC}"
echo ""
echo -e "${RED}⚠️  YOU MUST REBOOT NOW FOR GROUP PERMISSIONS AND DRIVERS TO LOAD.${NC}"
echo ""
