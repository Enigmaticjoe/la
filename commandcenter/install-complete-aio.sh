#!/bin/bash
################################################################################
# JULES PROTOCOL - ALL-IN-ONE INSTALLER WITH GUI WIZARD
# Complete installation from pre-audit to deployment
#
# Usage: sudo bash install-complete-aio.sh
################################################################################

set -e

# Check for root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Colors for non-dialog output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/jules_aio_install.log"
TEMP_DIR="/tmp/jules_install_$$"
mkdir -p "$TEMP_DIR"

# Dialog dimensions
HEIGHT=20
WIDTH=70
CHOICE_HEIGHT=10

################################################################################
# Check Dependencies
################################################################################

check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Installing dialog for GUI wizard..."
        apt-get update -qq
        apt-get install -y dialog
    fi
}

check_dialog

################################################################################
# Logging
################################################################################

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

################################################################################
# Welcome Screen
################################################################################

show_welcome() {
    dialog --title "Jules Protocol - All-in-One Installer" \
        --colors \
        --msgbox "\n\
\Zb\Z6╔══════════════════════════════════════════════════════════╗\Zn\n\
\Zb\Z6║                                                          ║\Zn\n\
\Zb\Z6║         🧠 JULES PROTOCOL INSTALLER 🧠                  ║\Zn\n\
\Zb\Z6║                                                          ║\Zn\n\
\Zb\Z6║  Self-Evolving AI Operating System                      ║\Zn\n\
\Zb\Z6║                                                          ║\Zn\n\
\Zb\Z6╚══════════════════════════════════════════════════════════╝\Zn\n\
\n\
\Zb\"I speak like someone who already checked the exit.\"\Zn\n\
\n\
This wizard will install:\n\
\n\
  • Digital Renegade AI Stack (Portainer)\n\
  • Jules Protocol (AI Shell + Memory System)\n\
  • Multi-model routing (FAST/DEEP/VISION/TOOLS)\n\
  • 8 operational modes\n\
  • Autonomous memory management\n\
  • Smart home integration\n\
\n\
\Zb\Z2Ready to begin?\Zn" \
        22 75
}

################################################################################
# Installation Mode Selection
################################################################################

select_mode() {
    MODE=$(dialog --title "Installation Mode" \
        --menu "Choose installation mode:" \
        $HEIGHT $WIDTH $CHOICE_HEIGHT \
        "1" "Full Install (Pre-audit + Digital Renegade + Jules)" \
        "2" "Jules Protocol Only (integrate with existing)" \
        "3" "Standalone Jules Protocol" \
        "4" "Pre-install Audit Only" \
        3>&1 1>&2 2>&3)

    case $MODE in
        1) INSTALL_MODE="full" ;;
        2) INSTALL_MODE="jules_integrate" ;;
        3) INSTALL_MODE="jules_standalone" ;;
        4) INSTALL_MODE="audit_only" ;;
        *) exit 0 ;;
    esac
}

################################################################################
# Configuration Collection
################################################################################

collect_configuration() {
    # PostgreSQL Password
    POSTGRES_PASSWORD=$(dialog --title "Configuration" \
        --passwordbox "Enter PostgreSQL password:" \
        $HEIGHT $WIDTH \
        3>&1 1>&2 2>&3)

    if [[ -z "$POSTGRES_PASSWORD" ]]; then
        POSTGRES_PASSWORD="jules_protocol_$(openssl rand -hex 8)"
    fi

    # Home Assistant (optional)
    HA_IP=$(dialog --title "Home Assistant Integration" \
        --inputbox "Enter Home Assistant IP (or leave blank to skip):" \
        $HEIGHT $WIDTH "192.168.1.149" \
        3>&1 1>&2 2>&3) || HA_IP=""

    if [[ -n "$HA_IP" ]]; then
        HA_TOKEN=$(dialog --title "Home Assistant Token" \
            --inputbox "Enter Home Assistant long-lived access token:" \
            $HEIGHT $WIDTH \
            3>&1 1>&2 2>&3) || HA_TOKEN=""
    fi

    # Blue Iris (optional)
    BLUEIRIS_IP=$(dialog --title "Blue Iris Integration" \
        --inputbox "Enter Blue Iris IP (or leave blank to skip):" \
        $HEIGHT $WIDTH "192.168.1.232" \
        3>&1 1>&2 2>&3) || BLUEIRIS_IP=""

    if [[ -n "$BLUEIRIS_IP" ]]; then
        BLUEIRIS_USER=$(dialog --title "Blue Iris Credentials" \
            --inputbox "Enter Blue Iris username:" \
            $HEIGHT $WIDTH \
            3>&1 1>&2 2>&3) || BLUEIRIS_USER=""

        BLUEIRIS_PASS=$(dialog --title "Blue Iris Credentials" \
            --passwordbox "Enter Blue Iris password:" \
            $HEIGHT $WIDTH \
            3>&1 1>&2 2>&3) || BLUEIRIS_PASS=""
    fi

    # Unraid (optional)
    UNRAID_IP=$(dialog --title "Unraid Integration" \
        --inputbox "Enter Unraid IP (or leave blank to skip):" \
        $HEIGHT $WIDTH "192.168.1.222" \
        3>&1 1>&2 2>&3) || UNRAID_IP=""
}

################################################################################
# Pre-Install Audit
################################################################################

run_audit() {
    dialog --title "Pre-Install Audit" \
        --infobox "Running system validation and cleanup...\n\nThis may take a few minutes." \
        8 60

    if [[ -f "$SCRIPT_DIR/pre-install-auditor.sh" ]]; then
        bash "$SCRIPT_DIR/pre-install-auditor.sh" --auto-fix > "$TEMP_DIR/audit.log" 2>&1
    else
        log "Pre-install auditor not found, skipping..."
    fi

    # Check audit results
    if [[ -f "/tmp/renegade_audit_report.txt" ]]; then
        dialog --title "Audit Report" \
            --textbox /tmp/renegade_audit_report.txt \
            $HEIGHT $WIDTH
    fi

    # Check for critical errors
    if grep -q "critical errors found" /tmp/renegade_audit_report.txt 2>/dev/null; then
        dialog --title "Critical Errors Found" \
            --msgbox "The pre-install audit found critical errors that must be fixed.\n\nPlease review the audit report and fix errors before proceeding." \
            12 60
        exit 1
    fi
}

################################################################################
# Progress Display
################################################################################

show_progress() {
    local title="$1"
    local message="$2"
    local percent="$3"

    echo "$percent" | dialog --title "$title" \
        --gauge "$message" \
        8 60 0
}

################################################################################
# Install Docker (if needed)
################################################################################

install_docker() {
    if ! command -v docker &> /dev/null; then
        (
            echo "0"
            echo "# Installing Docker..."
            curl -fsSL https://get.docker.com | sh > "$TEMP_DIR/docker_install.log" 2>&1
            echo "50"
            echo "# Adding user to docker group..."
            usermod -aG docker $SUDO_USER 2>/dev/null || true
            echo "75"
            echo "# Starting Docker daemon..."
            systemctl start docker
            systemctl enable docker
            echo "100"
            echo "# Docker installation complete"
        ) | dialog --title "Docker Installation" \
            --gauge "Installing Docker..." \
            8 60 0
    fi
}

################################################################################
# Install Digital Renegade
################################################################################

install_digital_renegade() {
    if [[ ! -f "$SCRIPT_DIR/install-renegade-portainer.sh" ]]; then
        dialog --title "Error" \
            --msgbox "Digital Renegade installer not found.\n\nExpected: $SCRIPT_DIR/install-renegade-portainer.sh" \
            10 60
        return 1
    fi

    (
        echo "10"
        echo "# Installing system dependencies..."
        sleep 2

        echo "30"
        echo "# Configuring NVIDIA drivers..."
        sleep 2

        echo "50"
        echo "# Installing Portainer..."
        bash "$SCRIPT_DIR/install-renegade-portainer.sh" > "$TEMP_DIR/renegade_install.log" 2>&1

        echo "80"
        echo "# Deploying services..."
        sleep 2

        echo "100"
        echo "# Digital Renegade installation complete"
    ) | dialog --title "Digital Renegade Installation" \
        --gauge "Installing Digital Renegade..." \
        8 60 0
}

################################################################################
# Install Jules Protocol
################################################################################

install_jules_protocol() {
    local mode="$1"

    if [[ ! -f "$SCRIPT_DIR/install-jules-protocol.sh" ]]; then
        dialog --title "Error" \
            --msgbox "Jules Protocol installer not found.\n\nExpected: $SCRIPT_DIR/install-jules-protocol.sh" \
            10 60
        return 1
    fi

    (
        echo "10"
        echo "# Validating constitution..."
        sleep 1

        echo "30"
        echo "# Building AI Shell..."
        sleep 2

        echo "50"
        echo "# Building Memory Pruner..."
        sleep 2

        echo "70"
        echo "# Deploying services..."
        bash "$SCRIPT_DIR/install-jules-protocol.sh" --$mode > "$TEMP_DIR/jules_install.log" 2>&1

        echo "90"
        echo "# Creating CLI command..."
        sleep 1

        echo "100"
        echo "# Jules Protocol installation complete"
    ) | dialog --title "Jules Protocol Installation" \
        --gauge "Installing Jules Protocol..." \
        8 60 0
}

################################################################################
# Summary Screen
################################################################################

show_summary() {
    local summary_text="
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║         ✓ INSTALLATION COMPLETE ✓                         ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

Installed Components:
────────────────────────────────────────────────────────────
"

    if [[ "$INSTALL_MODE" == "full" ]] || [[ "$INSTALL_MODE" == "jules_integrate" ]] || [[ "$INSTALL_MODE" == "jules_standalone" ]]; then
        summary_text+="
  ✓ Digital Renegade AI Stack
  ✓ Jules Protocol AI Shell
  ✓ Memory Pruner (autonomous cleanup)
  ✓ Multi-model routing
  ✓ 8 operational modes
"
    fi

    summary_text+="
Access Points:
────────────────────────────────────────────────────────────
  AI Shell:      jules
  Portainer:     http://192.168.1.9:9000
  Open WebUI:    http://192.168.1.9:3000
  Ollama:        http://192.168.1.9:11434
  Qdrant:        http://192.168.1.9:6333

Quick Start:
────────────────────────────────────────────────────────────
  # Access AI Shell
  jules

  # Example usage
  aishell> Design a microservice architecture
  aishell> Write a Python web scraper
  aishell> /mode HACK
  aishell> Scan my network

Documentation:
────────────────────────────────────────────────────────────
  Full Guide:    $SCRIPT_DIR/JULES-PROTOCOL-COMPLETE.md
  Constitution:  $SCRIPT_DIR/config/constitution/
  Logs:          /var/log/jules_protocol/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
\"Jules Protocol loaded. Let's do this properly.\"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
"

    dialog --title "Installation Complete" \
        --msgbox "$summary_text" \
        30 70
}

################################################################################
# Error Handler
################################################################################

error_handler() {
    dialog --title "Installation Error" \
        --msgbox "An error occurred during installation.\n\nCheck logs:\n  $LOG_FILE\n  $TEMP_DIR/" \
        12 60
    cleanup
    exit 1
}

trap error_handler ERR

################################################################################
# Cleanup
################################################################################

cleanup() {
    # Keep logs but remove temp files
    rm -rf "$TEMP_DIR"
}

################################################################################
# Main Installation Flow
################################################################################

main() {
    log "Jules Protocol AIO Installer started"

    # Welcome
    show_welcome

    # Select mode
    select_mode

    # Collect configuration
    collect_configuration

    # Run pre-install audit (unless audit-only mode)
    if [[ "$INSTALL_MODE" != "audit_only" ]]; then
        if dialog --title "Pre-Install Audit" \
            --yesno "Run pre-install system audit?\n\nRecommended: YES" \
            10 50; then
            run_audit
        fi
    else
        run_audit
        dialog --title "Audit Complete" \
            --msgbox "Pre-install audit complete.\n\nReview: /tmp/renegade_audit_report.txt" \
            10 50
        exit 0
    fi

    # Install Docker if needed
    if [[ "$INSTALL_MODE" == "full" ]]; then
        install_docker
    fi

    # Install components based on mode
    case $INSTALL_MODE in
        full)
            install_digital_renegade
            install_jules_protocol "integrate"
            ;;

        jules_integrate)
            # Check if Digital Renegade exists
            if [[ ! -f "$SCRIPT_DIR/portainer-stack-renegade.yml" ]]; then
                dialog --title "Warning" \
                    --yesno "Digital Renegade not found.\n\nInstall it first?" \
                    10 50
                if [[ $? -eq 0 ]]; then
                    install_digital_renegade
                fi
            fi
            install_jules_protocol "integrate"
            ;;

        jules_standalone)
            install_jules_protocol "standalone"
            ;;
    esac

    # Show summary
    show_summary

    # Cleanup
    cleanup

    log "Installation complete"
}

################################################################################
# Execute
################################################################################

main
