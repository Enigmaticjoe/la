#!/bin/bash
###############################################################################
# validate-rocm-ubuntu24.sh
# Validation script for ROCm installation on Ubuntu 24.04
#
# Usage: bash validate-rocm-ubuntu24.sh
#
# What this does:
#   1. Detects Ubuntu version
#   2. Checks ROCm repository configuration
#   3. Validates ROCm installation
#   4. Verifies GPU detection
#   5. Checks environment variables
###############################################################################

set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[✓]${NC} $1"; }
warn() { echo -e "${Y}[!]${NC} $1"; }
fail() { echo -e "${R}[✗]${NC} $1"; }
info() { echo -e "${B}[i]${NC} $1"; }
section() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

echo ""
echo "####################################################"
echo "#  ROCm Installation Validator for Ubuntu 24.04   #"
echo "####################################################"
echo ""

# == OS VERSION ================================================================
section "OS VERSION"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    ok "Detected: $PRETTY_NAME"
    
    if [[ "$VERSION_ID" == "24.04" ]]; then
        ok "Ubuntu 24.04 (Noble) detected - requires ROCm 6.2+"
        EXPECTED_CODENAME="noble"
    elif [[ "$VERSION_ID" == "22.04" ]]; then
        ok "Ubuntu 22.04 (Jammy) detected - requires ROCm 6.0+"
        EXPECTED_CODENAME="jammy"
    else
        warn "Ubuntu version $VERSION_ID - may require custom ROCm setup"
        EXPECTED_CODENAME="unknown"
    fi
else
    fail "Cannot detect OS version (/etc/os-release not found)"
    exit 1
fi

# == REPOSITORY CONFIGURATION ==================================================
section "REPOSITORY CONFIGURATION"

ROCM_LIST="/etc/apt/sources.list.d/rocm.list"
if [ -f "$ROCM_LIST" ]; then
    ok "ROCm repository list found: $ROCM_LIST"
    
    # Check if using modern keyring method
    if grep -q "signed-by=/etc/apt/keyrings/rocm.gpg" "$ROCM_LIST"; then
        ok "Using modern GPG keyring method"
    else
        warn "Not using modern keyring method - consider updating"
    fi
    
    # Check if using correct codename
    if grep -q "$EXPECTED_CODENAME" "$ROCM_LIST" 2>/dev/null; then
        ok "Repository configured for $EXPECTED_CODENAME"
    else
        warn "Repository not configured for $EXPECTED_CODENAME"
        info "Expected: deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest $EXPECTED_CODENAME main"
    fi
    
    # Display current configuration
    info "Current configuration:"
    cat "$ROCM_LIST" | sed 's/^/  /'
else
    fail "ROCm repository list not found: $ROCM_LIST"
    info "Run the installation commands from BRAIN-AMD-SETUP.md"
fi

# == GPG KEY ===================================================================
section "GPG KEY"

if [ -f /etc/apt/keyrings/rocm.gpg ]; then
    ok "Modern GPG keyring exists: /etc/apt/keyrings/rocm.gpg"
elif [ -f /etc/apt/trusted.gpg.d/rocm.gpg ]; then
    warn "Using trusted.gpg.d (old location) - consider updating"
else
    fail "ROCm GPG key not found"
    info "Run: wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null"
fi

# == ROCM INSTALLATION =========================================================
section "ROCM INSTALLATION"

if command -v rocm-smi &>/dev/null; then
    ok "rocm-smi installed"
    ROCM_VERSION=$(rocm-smi --version 2>/dev/null | grep -oP 'ROCm version: \K[0-9.]+' || echo "unknown")
    ok "ROCm version: $ROCM_VERSION"
    
    if [[ "$VERSION_ID" == "24.04" ]] && [[ "$ROCM_VERSION" < "6.2" ]]; then
        warn "ROCm $ROCM_VERSION may be too old for Ubuntu 24.04 (recommend 6.2+)"
    fi
else
    fail "rocm-smi not installed"
    info "Run: sudo apt install rocm-hip-sdk rocm-libs rocm-smi-lib"
fi

if command -v rocminfo &>/dev/null; then
    ok "rocminfo installed"
else
    warn "rocminfo not installed"
fi

if [ -d /opt/rocm ]; then
    ok "/opt/rocm directory exists"
    if [ -L /opt/rocm ]; then
        ROCM_LINK=$(readlink -f /opt/rocm)
        info "  -> symlink to: $ROCM_LINK"
    fi
else
    fail "/opt/rocm directory missing"
fi

# == GPU DETECTION =============================================================
section "GPU DETECTION"

if command -v lspci &>/dev/null; then
    AMD_GPU=$(lspci | grep -i "vga.*amd\|display.*amd" | head -1)
    if [ -n "$AMD_GPU" ]; then
        ok "AMD GPU detected:"
        echo "  $AMD_GPU" | sed 's/^/  /'
    else
        warn "No AMD GPU detected in lspci output"
    fi
fi

if [ -e /dev/kfd ]; then
    ok "/dev/kfd (Kernel Fusion Driver) exists"
else
    fail "/dev/kfd missing - ROCm kernel driver not loaded"
    info "Check if amdgpu kernel module is loaded: lsmod | grep amdgpu"
fi

if [ -d /dev/dri ]; then
    ok "/dev/dri directory exists"
    RENDER_NODES=$(ls /dev/dri/render* 2>/dev/null | wc -l)
    if [ "$RENDER_NODES" -gt 0 ]; then
        ok "$RENDER_NODES render node(s) found"
        ls /dev/dri/render* | sed 's/^/  /'
    else
        warn "No render nodes in /dev/dri"
    fi
else
    fail "/dev/dri missing"
fi

if command -v rocm-smi &>/dev/null; then
    GPU_INFO=$(rocm-smi --showproductname 2>/dev/null | grep -i "GPU\|Card" | head -1)
    if [ -n "$GPU_INFO" ]; then
        ok "GPU visible to ROCm:"
        echo "$GPU_INFO" | sed 's/^/  /'
        
        # Check for RX 7900 XT specifically
        if echo "$GPU_INFO" | grep -qi "7900"; then
            ok "RX 7900 XT detected (gfx1100)"
        fi
    fi
fi

# == ENVIRONMENT VARIABLES =====================================================
section "ENVIRONMENT VARIABLES"

check_env_var() {
    local var_name=$1
    local expected=$2
    local current="${!var_name:-}"
    
    if [ -n "$current" ]; then
        if [ "$current" == "$expected" ]; then
            ok "$var_name=$current"
        else
            warn "$var_name=$current (expected: $expected)"
        fi
    else
        warn "$var_name not set (expected: $expected)"
    fi
}

check_env_var "HSA_OVERRIDE_GFX_VERSION" "11.0.0"
check_env_var "ROCM_PATH" "/opt/rocm"
check_env_var "HIP_VISIBLE_DEVICES" "0"

# == SUMMARY ===================================================================
section "SUMMARY"

echo ""
if command -v rocm-smi &>/dev/null && [ -e /dev/kfd ]; then
    ok "ROCm appears to be correctly installed!"
    echo ""
    info "Next steps:"
    info "  1. Reboot if you just installed ROCm"
    info "  2. Run: bash brain-setup.sh"
    info "  3. Run: bash brain-model-downloader.sh"
    info "  4. Deploy: docker compose -f brain-stack.yml up -d"
else
    warn "ROCm installation incomplete"
    echo ""
    info "Follow the installation guide in BRAIN-AMD-SETUP.md"
    info "For Ubuntu 24.04 specific instructions, see UBUNTU-24.04-SUPPORT.md"
fi

echo ""
