#!/bin/bash
################################################################################
# JULES PROTOCOL MASTER DEPLOYER
# Finds and deploys Jules Protocol from git repository to current location
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         🧠 JULES PROTOCOL MASTER DEPLOYER 🧠              ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Find the git repository
GIT_REPO="/home/user/brain"

if [[ ! -d "$GIT_REPO" ]]; then
    echo -e "${RED}✗${NC} Git repository not found at $GIT_REPO"
    exit 1
fi

echo -e "${GREEN}✓${NC} Found git repository at $GIT_REPO"

# Get current directory
CURRENT_DIR=$(pwd)
echo -e "${BLUE}ℹ${NC} Current directory: $CURRENT_DIR"

# Check if we're already in the git repo
if [[ "$CURRENT_DIR" == "$GIT_REPO" ]]; then
    echo -e "${GREEN}✓${NC} Already in git repository"
    echo -e "${BLUE}ℹ${NC} Running installation directly..."

    # Run pre-install auditor
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} STEP 1: PRE-INSTALL AUDIT${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

    if [[ -f "./pre-install-auditor.sh" ]]; then
        sudo bash ./pre-install-auditor.sh --auto-fix
    else
        echo -e "${YELLOW}⚠${NC} Pre-install auditor not found, skipping..."
    fi

    # Show audit report
    if [[ -f "/tmp/renegade_audit_report.txt" ]]; then
        echo ""
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN} AUDIT REPORT${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        cat /tmp/renegade_audit_report.txt
    fi

    # Ask to continue
    echo ""
    read -p "Continue with Jules Protocol installation? (yes/no): " CONTINUE

    if [[ "$CONTINUE" != "yes" ]]; then
        echo -e "${YELLOW}⚠${NC} Installation cancelled"
        exit 0
    fi

    # Run Jules Protocol installer
    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} STEP 2: JULES PROTOCOL INSTALLATION${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"

    if [[ -f "./install-jules-protocol.sh" ]]; then
        sudo bash ./install-jules-protocol.sh --integrate
    else
        echo -e "${RED}✗${NC} Jules Protocol installer not found"
        exit 1
    fi

else
    # We're in a different directory - copy files here
    echo -e "${YELLOW}⚠${NC} You're in a different directory than the git repo"
    echo ""
    echo "Options:"
    echo "  1) Copy Jules Protocol files here and install"
    echo "  2) Change to git repo directory and install from there"
    echo "  3) Cancel"
    echo ""
    read -p "Choose option (1/2/3): " OPTION

    case $OPTION in
        1)
            echo ""
            echo -e "${BLUE}ℹ${NC} Copying files to $CURRENT_DIR..."

            # Copy necessary files
            cp "$GIT_REPO/pre-install-auditor.sh" . 2>/dev/null || echo "No pre-install-auditor.sh"
            cp "$GIT_REPO/install-jules-protocol.sh" . 2>/dev/null || echo "No install-jules-protocol.sh"
            cp "$GIT_REPO/install-renegade-portainer.sh" . 2>/dev/null || echo "No install-renegade-portainer.sh"

            # Copy entire config and agents directories
            if [[ -d "$GIT_REPO/config" ]]; then
                cp -r "$GIT_REPO/config" .
                echo -e "${GREEN}✓${NC} Copied config directory"
            fi

            if [[ -d "$GIT_REPO/agents" ]]; then
                cp -r "$GIT_REPO/agents" .
                echo -e "${GREEN}✓${NC} Copied agents directory"
            fi

            # Copy docker compose files
            cp "$GIT_REPO"/docker-compose*.yml . 2>/dev/null || true
            cp "$GIT_REPO"/portainer-stack*.yml . 2>/dev/null || true

            # Copy documentation
            cp "$GIT_REPO"/*.md . 2>/dev/null || true

            echo -e "${GREEN}✓${NC} Files copied"
            echo ""
            echo -e "${CYAN}Now run:${NC}"
            echo "  sudo bash pre-install-auditor.sh --auto-fix"
            echo "  sudo bash install-jules-protocol.sh --integrate"
            ;;

        2)
            echo ""
            echo -e "${CYAN}Run these commands:${NC}"
            echo "  cd $GIT_REPO"
            echo "  sudo bash pre-install-auditor.sh --auto-fix"
            echo "  sudo bash install-jules-protocol.sh --integrate"
            ;;

        3)
            echo -e "${YELLOW}⚠${NC} Installation cancelled"
            exit 0
            ;;

        *)
            echo -e "${RED}✗${NC} Invalid option"
            exit 1
            ;;
    esac
fi

echo ""
echo -e "${GREEN}✓${NC} Done"
