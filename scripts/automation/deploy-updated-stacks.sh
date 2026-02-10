#!/bin/bash
################################################################################
# Quick Stack Deployment Helper
# Guides deployment of updated stacks to Brawn (Unraid)
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
step()  { echo -e "${CYAN}[→]${NC} $1"; }

clear

cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   BRAWN Stack Deployment Guide                              ║
║   Updated Images - Brain-Brawn Integration                  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

EOF

echo ""
info "This guide will help you deploy your updated stacks to Brawn (Unraid)"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Stack files
STACKS=(
    "01-core-infrastructure.yml:Core Infrastructure (Homepage, Uptime Kuma, Watchtower, etc.)"
    "04-storage-stack.yml:Storage Stack (Nextcloud, MariaDB, Redis)"
    "02-media-stack.yml:Media Stack (Plex, Sonarr, Radarr, etc.)"
    "03-ai-stack.yml:AI Stack (vLLM, OpenWebUI, Qdrant, Embeddings)"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 1: Pre-Deployment Checklist"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

step "Verify you have:"
echo "  □ Access to Portainer at http://192.168.1.222:8008"
echo "  □ Updated brawn-stacks.env file with Brain IP (192.168.1.9)"
echo "  □ Backup of current stacks (auto-created in .stack-backups/)"
echo ""

read -p "Press Enter to continue or Ctrl+C to abort..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 2: Review Updated Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Key image updates applied:"
echo ""
echo "  • vLLM:          v0.6.5  → v0.15.1 (major update)"
echo "  • Qdrant:        v1.13.2 → latest"
echo "  • TEI Embeddings: 1.5    → 89-1.8"
echo "  • Overseerr:     latest  → develop"
echo "  • Redis:         7-alpine → alpine"
echo "  • MariaDB:       11      → latest"
echo ""

warn "Note: vLLM update is significant - may require model reload"
echo ""

read -p "Press Enter to continue..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 3: Brain Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Configure Brain connectivity in brawn-stacks.env:"
echo ""
cat << 'ENV_EXAMPLE'
# Add these to /mnt/user/appdata/brawn-stacks.env
BRAIN_IP=192.168.1.9
BRAIN_VLLM_PORT=8000
BRAIN_OLLAMA_PORT=11434

# API Keys
VLLM_API_KEY=sk-brain-primary
BRAWN_VLLM_API_KEY=sk-brawn-local
ENV_EXAMPLE

echo ""
step "Action required:"
echo "  1. SSH to Brawn: ssh root@192.168.1.222"
echo "  2. Edit: nano /mnt/user/appdata/brawn-stacks/brawn-stacks.env"
echo "  3. Add the above variables"
echo ""

read -p "Press Enter when env file is updated..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 4: Deploy Stacks via Portainer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Open Portainer: http://192.168.1.222:8008"
echo ""

for stack_info in "${STACKS[@]}"; do
    IFS=':' read -r stack_file stack_desc <<< "$stack_info"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    ok "Deploy: $stack_desc"
    echo ""
    
    step "In Portainer:"
    echo "  1. Go to: Stacks → Select existing stack or Add stack"
    echo "  2. Stack name: ${stack_file%.yml}"
    echo "  3. Upload file: $REPO_ROOT/$stack_file"
    echo "     OR paste content from: cat $stack_file"
    echo "  4. Environment → Load from file: brawn-stacks.env"
    echo "  5. Click: Deploy/Update Stack"
    echo ""
    
    # Show file location
    if [ -f "$REPO_ROOT/$stack_file" ]; then
        info "File location: $REPO_ROOT/$stack_file"
        
        # Count services
        service_count=$(grep -c "^  [a-zA-Z0-9_-]*:$" "$REPO_ROOT/$stack_file" || echo "0")
        info "Services in this stack: $service_count"
    fi
    
    echo ""
    read -p "Press Enter when stack is deployed..."
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 5: Verify Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Run validation script:"
echo ""
echo "  ssh root@192.168.1.222"
echo "  cd /mnt/user/appdata/brawn-stacks"
echo "  bash brawn-validate.sh"
echo ""

step "Test key services:"
echo ""
echo "  Homepage:   http://192.168.1.222:8010"
echo "  OpenWebUI:  http://192.168.1.222:3000"
echo "  Plex:       http://192.168.1.222:32400"
echo "  Portainer:  http://192.168.1.222:8008"
echo ""

step "Test Brain connectivity:"
echo ""
echo "  # From Brawn:"
echo "  docker exec openwebui curl -f http://192.168.1.9:8000/health"
echo ""

read -p "Press Enter to continue..."
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  STEP 6: Post-Deployment Tasks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

step "Configure OpenWebUI connections:"
echo "  1. Access: http://192.168.1.222:3000"
echo "  2. Go to Settings → Connections"
echo "  3. Verify both vLLM endpoints are visible:"
echo "     - Brain vLLM:  http://192.168.1.9:8000/v1"
echo "     - Brawn vLLM:  http://172.25.0.20:8000/v1"
echo ""

step "Update Homepage dashboard:"
echo "  1. Edit: /mnt/user/appdata/homepage/services.yaml"
echo "  2. Add Brain services as needed"
echo "  3. Restart: docker restart homepage"
echo ""

echo ""
ok "Deployment guide complete!"
echo ""

info "Next steps:"
echo "  • Review: $REPO_ROOT/BRAIN-BRAWN-INTEGRATION.md"
echo "  • Monitor logs for any issues"
echo "  • Test AI inference on both Brain and Brawn"
echo "  • Set up automated backups"
echo ""

info "For troubleshooting, see: BRAIN-BRAWN-INTEGRATION.md"
echo ""
