#!/bin/bash
################################################################################
# Selective Stack Update Script
# Updates Docker stack configurations while preserving specific services
#
# Usage:
#   ./selective-stack-update.sh --preserve vllm,openwebui --stack 03-ai-stack.yml
#   ./selective-stack-update.sh --list-services --stack 03-ai-stack.yml
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
BACKUP_DIR="${BACKUP_DIR:-/mnt/user/appdata/stack-backups}"
PRESERVE_SERVICES=()
STACK_FILE=""
LIST_ONLY=false
OUTPUT_FILE=""

# Functions
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1" >&2; }

usage() {
    cat << EOF
Selective Stack Update Script

Usage:
    $0 --stack STACK_FILE [OPTIONS]

Options:
    --stack FILE              Stack file to update (e.g., 03-ai-stack.yml)
    --preserve SERVICE,...    Comma-separated list of services to preserve
    --list-services          List all services in the stack file
    --output FILE            Output file for updated stack (default: overwrites original)
    --backup-dir DIR         Backup directory (default: /mnt/user/appdata/stack-backups)
    --help                   Show this help message

Examples:
    # List all services in a stack
    $0 --stack 03-ai-stack.yml --list-services

    # Update stack while preserving vllm and openwebui
    $0 --stack 03-ai-stack.yml --preserve vllm,openwebui

    # Update and save to a new file
    $0 --stack 03-ai-stack.yml --preserve vllm,openwebui --output 03-ai-stack-updated.yml

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --stack)
            STACK_FILE="$2"
            shift 2
            ;;
        --preserve)
            IFS=',' read -ra PRESERVE_SERVICES <<< "$2"
            # Trim whitespace from each service name
            for i in "${!PRESERVE_SERVICES[@]}"; do
                PRESERVE_SERVICES[$i]=$(echo "${PRESERVE_SERVICES[$i]}" | xargs)
            done
            # Debug: show what was parsed
            echo "DEBUG after parse: Array has ${#PRESERVE_SERVICES[@]} elements" >&2
            for idx in "${!PRESERVE_SERVICES[@]}"; do
                echo "DEBUG after parse:   [$idx] = '${PRESERVE_SERVICES[$idx]}'" >&2
            done
            shift 2
            ;;
        --list-services)
            LIST_ONLY=true
            shift
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
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

# Validate required arguments
if [ -z "$STACK_FILE" ]; then
    error "Stack file is required. Use --stack option."
    usage
fi

# Check if stack file exists
if [ ! -f "$STACK_FILE" ]; then
    # Try in repo root
    if [ -f "$REPO_ROOT/$STACK_FILE" ]; then
        STACK_FILE="$REPO_ROOT/$STACK_FILE"
    else
        error "Stack file not found: $STACK_FILE"
        exit 1
    fi
fi

info "Using stack file: $STACK_FILE"

# Function to extract service names from docker-compose YAML
extract_services() {
    local file="$1"
    # Extract service names using grep and awk
    # This looks for lines after "services:" that are at the top level (2 spaces indent)
    grep -E '^  [a-zA-Z0-9_-]+:' "$file" | sed 's/://g' | awk '{print $1}' | sort
}

# Function to list services
list_services() {
    local file="$1"
    info "Services found in $file:"
    echo ""
    extract_services "$file" | while read -r service; do
        echo "  • $service"
    done
    echo ""
}

# List services if requested
if [ "$LIST_ONLY" = true ]; then
    list_services "$STACK_FILE"
    exit 0
fi

# Check if preserve list is empty
if [ ${#PRESERVE_SERVICES[@]} -eq 0 ]; then
    warn "No services to preserve specified. Use --preserve option."
    echo ""
    list_services "$STACK_FILE"
    exit 0
fi

info "Services to preserve: ${PRESERVE_SERVICES[*]}"

# Create backup
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/$(basename "$STACK_FILE").${TIMESTAMP}.bak"
cp "$STACK_FILE" "$BACKUP_FILE"
ok "Created backup: $BACKUP_FILE"

# Determine output file
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="$STACK_FILE"
fi

info "Output will be written to: $OUTPUT_FILE"

# Export variables for Python script
export PRESERVE_SERVICES="${PRESERVE_SERVICES[*]}"
export STACK_FILE
export OUTPUT_FILE

# Check if PyYAML is available
if ! python3 -c "import yaml" 2>/dev/null; then
    error "PyYAML is not installed. Installing..."
    pip3 install PyYAML --quiet || {
        error "Failed to install PyYAML. Please install manually: pip3 install PyYAML"
        exit 1
    }
fi

# Create temporary Python script
TEMP_SCRIPT=$(mktemp /tmp/stack-update-XXXXXX.py)
trap "rm -f $TEMP_SCRIPT" EXIT

cat > "$TEMP_SCRIPT" << 'PYTHON_SCRIPT'
import sys
import yaml

if len(sys.argv) < 4:
    print("Usage: script.py <stack_file> <output_file> <preserve_service1> [preserve_service2 ...]", file=sys.stderr)
    sys.exit(1)

stack_file = sys.argv[1]
output_file = sys.argv[2]
preserve_services = sys.argv[3:]

print(f"DEBUG: stack_file = '{stack_file}'", file=sys.stderr)
print(f"DEBUG: output_file = '{output_file}'", file=sys.stderr)
print(f"DEBUG: preserve_services = {preserve_services}", file=sys.stderr)

try:
    # Read the stack file
    with open(stack_file, 'r') as f:
        stack = yaml.safe_load(f)

    # Check if services exist
    if 'services' not in stack:
        print(f"Error: No services found in {stack_file}", file=sys.stderr)
        sys.exit(1)

    # Extract preserved services
    preserved = {}
    missing = []

    for service in preserve_services:
        service = service.strip()
        if service in stack['services']:
            preserved[service] = stack['services'][service]
            print(f"✓ Preserved service: {service}")
        else:
            missing.append(service)
            print(f"! Service not found: {service}", file=sys.stderr)

    if missing:
        print(f"\nWarning: Services not found in stack: {', '.join(missing)}", file=sys.stderr)

    if not preserved:
        print("\nError: No services were preserved. Check service names.", file=sys.stderr)
        sys.exit(1)

    # Create new stack with only preserved services
    new_stack = {
        'networks': stack.get('networks', {}),
        'services': preserved
    }

    # Add volumes if they exist
    if 'volumes' in stack:
        new_stack['volumes'] = stack['volumes']

    # Write output
    with open(output_file, 'w') as f:
        yaml.dump(new_stack, f, default_flow_style=False, sort_keys=False, width=80)

    print(f"\n✓ Updated stack written to: {output_file}")
    print(f"  Preserved {len(preserved)} service(s)")

except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc()
    sys.exit(1)

PYTHON_SCRIPT

# Run the Python script with arguments
echo "DEBUG: PRESERVE_SERVICES array has ${#PRESERVE_SERVICES[@]} elements" >&2
for i in "${!PRESERVE_SERVICES[@]}"; do
    echo "DEBUG:   [$i] = '${PRESERVE_SERVICES[$i]}'" >&2
done
python3 "$TEMP_SCRIPT" "$STACK_FILE" "$OUTPUT_FILE" "${PRESERVE_SERVICES[@]}"

ok "Selective stack update complete!"
echo ""
info "Next steps:"
echo "  1. Review the updated stack: $OUTPUT_FILE"
echo "  2. Deploy via Portainer or docker compose"
echo "  3. Original backup saved at: $BACKUP_FILE"
echo ""
