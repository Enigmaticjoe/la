#!/bin/bash
################################################################################
# Stack Image Synchronization Script
# Updates docker-compose stack files with current running image versions
#
# Usage:
#   ./sync-stack-images.sh --from-unraid 192.168.1.222
#   ./sync-stack-images.sh --from-file current-images.txt
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
UNRAID_HOST=""
IMAGE_FILE=""
DRY_RUN=false

# Functions
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; }

usage() {
    cat << EOF
Stack Image Synchronization Script

Updates docker-compose stack YAML files with current image versions from running containers.

Usage:
    $0 [OPTIONS]

Options:
    --from-unraid HOST        Fetch image versions from Unraid host via SSH
    --from-file FILE          Read image versions from file (format: image:tag)
    --dry-run                 Show what would be updated without making changes
    --help                    Show this help message

Examples:
    # Update from running Unraid containers
    $0 --from-unraid 192.168.1.222

    # Update from a saved image list
    $0 --from-file /tmp/current-images.txt

    # Preview changes without updating
    $0 --from-unraid 192.168.1.222 --dry-run

The script will:
    1. Fetch current image:tag versions from running containers
    2. Update all stack YAML files in the repository
    3. Create backups before making changes
    4. Report which images were updated

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-unraid)
            UNRAID_HOST="$2"
            shift 2
            ;;
        --from-file)
            IMAGE_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate input
if [ -z "$UNRAID_HOST" ] && [ -z "$IMAGE_FILE" ]; then
    error "Either --from-unraid or --from-file must be specified"
    usage
fi

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   Stack Image Synchronization                   ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Get current image versions
TEMP_IMAGES=$(mktemp /tmp/stack-images-XXXXXX.txt)
trap "rm -f $TEMP_IMAGES" EXIT

if [ -n "$UNRAID_HOST" ]; then
    info "Fetching image versions from $UNRAID_HOST..."
    
    # Fetch running containers and their images via SSH
    if ! ssh -o ConnectTimeout=5 root@"$UNRAID_HOST" "docker ps --format '{{.Image}}'" > "$TEMP_IMAGES" 2>/dev/null; then
        error "Failed to connect to $UNRAID_HOST"
        error "Make sure SSH is configured and you have access"
        exit 1
    fi
    
    ok "Retrieved $(wc -l < "$TEMP_IMAGES") running container images"
    
elif [ -n "$IMAGE_FILE" ]; then
    if [ ! -f "$IMAGE_FILE" ]; then
        error "Image file not found: $IMAGE_FILE"
        exit 1
    fi
    
    info "Reading image versions from $IMAGE_FILE..."
    cp "$IMAGE_FILE" "$TEMP_IMAGES"
    ok "Loaded $(wc -l < "$TEMP_IMAGES") images"
fi

# Show current images
echo ""
info "Current images to sync:"
echo ""
cat "$TEMP_IMAGES" | sort | while read -r image; do
    echo "  • $image"
done
echo ""

# Create backup directory
BACKUP_DIR="$REPO_ROOT/.stack-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR/$TIMESTAMP"

# Find all stack YAML files
STACK_FILES=$(find "$REPO_ROOT" -maxdepth 1 -name "*-stack.yml" -o -name "0[0-9]-*.yml")

if [ -z "$STACK_FILES" ]; then
    warn "No stack files found in $REPO_ROOT"
    exit 0
fi

info "Found stack files:"
echo "$STACK_FILES" | while read -r file; do
    echo "  • $(basename "$file")"
done
echo ""

# Python script to update image tags in YAML files
info "Creating update script..."

TEMP_SCRIPT=$(mktemp /tmp/update-images-XXXXXX.py)
trap "rm -f $TEMP_SCRIPT $TEMP_IMAGES" EXIT

cat > "$TEMP_SCRIPT" << 'PYTHON_SCRIPT'
import sys
import re
from pathlib import Path

def load_current_images(image_file):
    """Load current image:tag mappings"""
    images = {}
    with open(image_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # Parse image:tag
            if ':' in line:
                # Handle full image names like ghcr.io/owner/repo:tag
                parts = line.rsplit(':', 1)
                image_name = parts[0]
                tag = parts[1] if len(parts) > 1 else 'latest'
                
                # Store both full name and short name
                images[image_name] = tag
                
                # Also store just the repo name for matching
                if '/' in image_name:
                    short_name = image_name.split('/')[-1]
                    if short_name not in images:
                        images[short_name] = tag
            else:
                images[line] = 'latest'
    
    return images

def update_stack_file(stack_file, current_images, dry_run=False):
    """Update image tags in a stack file"""
    updates = []
    
    with open(stack_file, 'r') as f:
        lines = f.readlines()
    
    new_lines = []
    for i, line in enumerate(lines):
        # Look for image: lines
        match = re.match(r'^(\s+image:\s+)(.+?)(:.*)?(\s*)$', line)
        if match:
            indent = match.group(1)
            image_name = match.group(2)
            current_tag = match.group(3) if match.group(3) else ':latest'
            trailing = match.group(4) if match.group(4) else ''
            
            # Try to find matching image in current images
            new_tag = None
            
            # Try exact match first
            if image_name in current_images:
                new_tag = current_images[image_name]
            else:
                # Try matching just the repo name
                repo_name = image_name.split('/')[-1]
                if repo_name in current_images:
                    new_tag = current_images[repo_name]
            
            if new_tag and f':{new_tag}' != current_tag:
                new_line = f'{indent}{image_name}:{new_tag}{trailing}\n'
                new_lines.append(new_line)
                updates.append({
                    'line': i + 1,
                    'image': image_name,
                    'old_tag': current_tag,
                    'new_tag': f':{new_tag}'
                })
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    
    # Write updates if not dry run
    if not dry_run and updates:
        with open(stack_file, 'w') as f:
            f.writelines(new_lines)
    
    return updates

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: script.py <image_file> <stack_file> [--dry-run]", file=sys.stderr)
        sys.exit(1)
    
    image_file = sys.argv[1]
    stack_file = sys.argv[2]
    dry_run = '--dry-run' in sys.argv
    
    # Load current images
    current_images = load_current_images(image_file)
    
    # Update stack file
    updates = update_stack_file(stack_file, current_images, dry_run)
    
    if updates:
        print(f"{'[DRY RUN] ' if dry_run else ''}Updates for {Path(stack_file).name}:")
        for update in updates:
            print(f"  Line {update['line']}: {update['image']}")
            print(f"    {update['old_tag']} → {update['new_tag']}")
        print()
    else:
        print(f"No updates needed for {Path(stack_file).name}")

PYTHON_SCRIPT

# Check if PyYAML is available (we don't actually need it for this script, but good to have)
if ! python3 -c "import re" 2>/dev/null; then
    error "Python3 is required but not available"
    exit 1
fi

# Process each stack file
TOTAL_UPDATES=0

echo "$STACK_FILES" | while read -r stack_file; do
    if [ ! -f "$stack_file" ]; then
        continue
    fi
    
    # Create backup
    if [ "$DRY_RUN" = false ]; then
        cp "$stack_file" "$BACKUP_DIR/$TIMESTAMP/$(basename "$stack_file")"
    fi
    
    # Update the file
    if [ "$DRY_RUN" = true ]; then
        python3 "$TEMP_SCRIPT" "$TEMP_IMAGES" "$stack_file" --dry-run
    else
        python3 "$TEMP_SCRIPT" "$TEMP_IMAGES" "$stack_file"
    fi
done

echo ""
if [ "$DRY_RUN" = true ]; then
    info "This was a dry run. No files were modified."
    info "Run without --dry-run to apply changes."
else
    ok "Stack files updated successfully!"
    ok "Backups saved to: $BACKUP_DIR/$TIMESTAMP"
fi

echo ""
info "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Test deployment in Portainer"
echo "  3. Commit changes: git add . && git commit -m 'Update stack image versions'"
echo ""
