#!/bin/bash
###############################################################################
# brawn-maintenance.sh
# Cleanup orphan images, dead containers, unused networks, and dangling volumes
# Safe to run periodically via Unraid User Scripts
#
# Usage: bash brawn-maintenance.sh [--dry-run]
###############################################################################

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[✓]${NC} $1"; }
warn() { echo -e "${Y}[!]${NC} $1"; }
info() { echo -e "${BOLD}[i]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   BRAWN Maintenance Script                      ║"
echo "║   $(date '+%Y-%m-%d %H:%M:%S')                          ║"
$DRY_RUN && echo "║   *** DRY RUN — no changes will be made ***      ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── 1. REMOVE STOPPED CONTAINERS ──
info "Checking for dead containers..."
dead=$(docker ps -a --filter "status=exited" --filter "status=dead" --format "{{.Names}}" | wc -l)
if [ "$dead" -gt 0 ]; then
  warn "$dead stopped/dead containers found:"
  docker ps -a --filter "status=exited" --filter "status=dead" --format "  {{.Names}} — {{.Status}}"
  if ! $DRY_RUN; then
    docker container prune -f
    ok "Removed dead containers"
  fi
else
  ok "No dead containers"
fi

# ── 2. REMOVE ORPHAN IMAGES ──
echo ""
info "Checking for dangling images..."
dangling=$(docker images -f "dangling=true" -q | wc -l)
if [ "$dangling" -gt 0 ]; then
  warn "$dangling dangling images found"
  docker images -f "dangling=true" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
  if ! $DRY_RUN; then
    docker image prune -f
    ok "Removed dangling images"
  fi
else
  ok "No dangling images"
fi

# ── 3. REMOVE UNUSED IMAGES (older than 7 days, not in use) ──
echo ""
info "Checking for unused images (>7 days old, not running)..."
unused=$(docker images --format "{{.ID}} {{.Repository}}:{{.Tag}} {{.CreatedSince}}" | grep -E "(weeks|months)" | wc -l)
if [ "$unused" -gt 0 ]; then
  warn "$unused potentially stale images:"
  docker images --format "  {{.Repository}}:{{.Tag}} — {{.CreatedSince}} ({{.Size}})" | grep -E "(weeks|months)" | head -10
  echo ""
  echo "  Run 'docker image prune -a --filter until=168h' to clean (USE CAUTION)"
fi

# ── 4. REMOVE UNUSED NETWORKS ──
echo ""
info "Checking for orphan networks..."
if ! $DRY_RUN; then
  removed=$(docker network prune -f 2>&1)
  if echo "$removed" | grep -q "Deleted"; then
    ok "Removed unused networks"
  else
    ok "No orphan networks"
  fi
else
  unused_nets=$(docker network ls --filter "dangling=true" -q | wc -l)
  ok "Orphan networks: $unused_nets"
fi

# ── 5. CHECK DISK USAGE ──
echo ""
info "Docker disk usage:"
docker system df
echo ""

# ── 6. CHECK CONTAINER HEALTH ──
echo ""
info "Unhealthy containers:"
unhealthy=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" | wc -l)
if [ "$unhealthy" -gt 0 ]; then
  warn "$unhealthy unhealthy containers:"
  docker ps --filter "health=unhealthy" --format "  {{.Names}} — {{.Status}}"
else
  ok "All running containers are healthy"
fi

# ── 7. CHECK APPDATA FOR DUPLICATES ──
echo ""
info "Checking for duplicate appdata directories..."
dupes=0
for dir in /mnt/user/appdata/*/; do
  base=$(basename "$dir")
  # Check for common duplicate patterns
  for suffix in "-old" "-backup" "-bak" ".bak" "-copy" "(1)"; do
    if [ -d "/mnt/user/appdata/${base}${suffix}" ]; then
      warn "Possible duplicate: ${base} ↔ ${base}${suffix}"
      ((dupes++))
    fi
  done
done
if [ "$dupes" -eq 0 ]; then
  ok "No obvious duplicate directories"
fi

# ── 8. LOG SIZES ──
echo ""
info "Largest container logs:"
find /var/lib/docker/containers/ -name "*.log" -exec du -sh {} \; 2>/dev/null | sort -rh | head -5 | while read size path; do
  cid=$(echo "$path" | grep -oP '[a-f0-9]{64}')
  cname=$(docker inspect --format '{{.Name}}' "$cid" 2>/dev/null | sed 's/^\///')
  echo "  $size — $cname"
done

# ── 9. APPDATA SIZE REPORT ──
echo ""
info "Top 10 appdata directories by size:"
du -sh /mnt/user/appdata/*/ 2>/dev/null | sort -rh | head -10 | while read size dir; do
  echo "  $size — $(basename $dir)"
done

echo ""
ok "Maintenance scan complete."
$DRY_RUN && echo -e "\n${Y}This was a dry run. Rerun without --dry-run to apply changes.${NC}"
echo ""
