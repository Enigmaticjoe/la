#!/bin/bash
#
# Automated Backup Script for Brain AI Stack
# 
# Backs up:
# - Qdrant database (snapshots)
# - OpenWebUI data and configurations
# - Conversation history
# - Custom prompts and settings
# - Evolution metrics and logs
#
# Features:
# - Compression and timestamping
# - Retention policy (keeps last N backups)
# - Integrity verification
# - Detailed logging
#

set -euo pipefail

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
RETENTION_COUNT="${RETENTION_COUNT:-10}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="brain-backup-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

# Service URLs
QDRANT_URL="${QDRANT_URL:-http://qdrant:6333}"
OPENWEBUI_DATA="${OPENWEBUI_DATA:-/data/openwebui}"
EVOLUTION_DATA="${EVOLUTION_DATA:-/data/evolution}"

# Logging
LOG_FILE="${BACKUP_DIR}/backup.log"
mkdir -p "${BACKUP_DIR}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" | tee -a "${LOG_FILE}" >&2
}

log "=========================================="
log "Starting backup: ${BACKUP_NAME}"
log "=========================================="

# Create backup directory
mkdir -p "${BACKUP_PATH}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to backup Qdrant database
backup_qdrant() {
    log "Backing up Qdrant database..."
    
    local qdrant_backup="${BACKUP_PATH}/qdrant"
    mkdir -p "${qdrant_backup}"
    
    # Get list of collections
    local collections
    if ! collections=$(curl -s "${QDRANT_URL}/collections" 2>/dev/null); then
        log_error "Failed to connect to Qdrant at ${QDRANT_URL}"
        return 1
    fi
    
    # Parse collection names (simple jq-free approach)
    local collection_count=0
    
    # Try to create snapshots for each collection
    # Note: This is a simplified version - in production, parse JSON properly
    log "Creating Qdrant snapshots..."
    
    # If Qdrant data directory is accessible, backup directly
    if [ -d "/data/qdrant/storage" ]; then
        log "Backing up Qdrant storage directory..."
        tar -czf "${qdrant_backup}/storage.tar.gz" -C /data/qdrant storage 2>/dev/null || {
            log_error "Failed to backup Qdrant storage"
            return 1
        }
        
        local size
        size=$(du -sh "${qdrant_backup}/storage.tar.gz" | cut -f1)
        log "Qdrant storage backup complete (${size})"
        return 0
    else
        log "Qdrant storage directory not accessible, skipping..."
        return 1
    fi
}

# Function to backup OpenWebUI data
backup_openwebui() {
    log "Backing up OpenWebUI data..."
    
    local openwebui_backup="${BACKUP_PATH}/openwebui"
    mkdir -p "${openwebui_backup}"
    
    if [ ! -d "${OPENWEBUI_DATA}" ]; then
        log "OpenWebUI data directory not found at ${OPENWEBUI_DATA}, skipping..."
        return 1
    fi
    
    # Backup SQLite database
    if [ -f "${OPENWEBUI_DATA}/webui.db" ]; then
        log "Backing up OpenWebUI database..."
        cp "${OPENWEBUI_DATA}/webui.db" "${openwebui_backup}/webui.db" || {
            log_error "Failed to backup OpenWebUI database"
            return 1
        }
        log "Database backup complete"
    fi
    
    # Backup uploads and user data
    if [ -d "${OPENWEBUI_DATA}/uploads" ]; then
        log "Backing up user uploads..."
        tar -czf "${openwebui_backup}/uploads.tar.gz" -C "${OPENWEBUI_DATA}" uploads 2>/dev/null || {
            log_error "Failed to backup uploads"
        }
    fi
    
    # Backup custom prompts
    if [ -f "${OPENWEBUI_DATA}/prompts.json" ]; then
        log "Backing up custom prompts..."
        cp "${OPENWEBUI_DATA}/prompts.json" "${openwebui_backup}/prompts.json" || {
            log_error "Failed to backup prompts"
        }
    fi
    
    # Backup configurations
    if [ -f "${OPENWEBUI_DATA}/config.json" ]; then
        log "Backing up configurations..."
        cp "${OPENWEBUI_DATA}/config.json" "${openwebui_backup}/config.json" || {
            log_error "Failed to backup config"
        }
    fi
    
    local size
    size=$(du -sh "${openwebui_backup}" | cut -f1)
    log "OpenWebUI backup complete (${size})"
}

# Function to backup evolution data
backup_evolution() {
    log "Backing up evolution metrics and logs..."
    
    local evolution_backup="${BACKUP_PATH}/evolution"
    mkdir -p "${evolution_backup}"
    
    if [ ! -d "${EVOLUTION_DATA}" ]; then
        log "Evolution data directory not found at ${EVOLUTION_DATA}, skipping..."
        return 1
    fi
    
    # Backup evolution database
    if [ -f "${EVOLUTION_DATA}/evolution.db" ]; then
        cp "${EVOLUTION_DATA}/evolution.db" "${evolution_backup}/evolution.db" || {
            log_error "Failed to backup evolution database"
        }
    fi
    
    # Backup logs (last 7 days)
    if [ -f "${EVOLUTION_DATA}/evolution.log" ]; then
        tail -n 10000 "${EVOLUTION_DATA}/evolution.log" > "${evolution_backup}/evolution.log" 2>/dev/null || true
    fi
    
    if [ -f "${EVOLUTION_DATA}/auto-optimize.log" ]; then
        tail -n 10000 "${EVOLUTION_DATA}/auto-optimize.log" > "${evolution_backup}/auto-optimize.log" 2>/dev/null || true
    fi
    
    local size
    size=$(du -sh "${evolution_backup}" | cut -f1)
    log "Evolution data backup complete (${size})"
}

# Function to backup model configurations
backup_configs() {
    log "Backing up configurations..."
    
    local configs_backup="${BACKUP_PATH}/configs"
    mkdir -p "${configs_backup}"
    
    # Backup docker-compose configuration
    if [ -f "/app/docker-compose.yml" ]; then
        cp "/app/docker-compose.yml" "${configs_backup}/docker-compose.yml" 2>/dev/null || true
    fi
    
    # Backup environment variables (sanitized)
    if [ -f "/app/.env" ]; then
        # Remove sensitive data
        grep -v -E "(PASSWORD|SECRET|KEY|TOKEN)" "/app/.env" > "${configs_backup}/env-sanitized.txt" 2>/dev/null || true
    fi
    
    log "Configuration backup complete"
}

# Function to create backup manifest
create_manifest() {
    log "Creating backup manifest..."
    
    cat > "${BACKUP_PATH}/MANIFEST.txt" <<EOF
Backup Created: $(date '+%Y-%m-%d %H:%M:%S')
Backup Name: ${BACKUP_NAME}
Hostname: $(hostname)

Contents:
$(tree -L 2 "${BACKUP_PATH}" 2>/dev/null || find "${BACKUP_PATH}" -maxdepth 2 -type f)

Sizes:
$(du -sh "${BACKUP_PATH}"/* 2>/dev/null || echo "N/A")

Total Backup Size: $(du -sh "${BACKUP_PATH}" | cut -f1)
EOF
    
    log "Manifest created"
}

# Function to compress backup
compress_backup() {
    log "Compressing backup..."
    
    local archive="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
    
    tar -czf "${archive}" -C "${BACKUP_DIR}" "${BACKUP_NAME}" || {
        log_error "Failed to compress backup"
        return 1
    }
    
    # Calculate checksums
    if command_exists sha256sum; then
        sha256sum "${archive}" > "${archive}.sha256"
        log "Checksum: $(cat "${archive}.sha256")"
    fi
    
    local size
    size=$(du -sh "${archive}" | cut -f1)
    log "Backup compressed: ${archive} (${size})"
    
    # Remove uncompressed directory
    rm -rf "${BACKUP_PATH}"
    
    echo "${archive}"
}

# Function to cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups..."
    
    # Remove backups older than RETENTION_DAYS
    log "Removing backups older than ${RETENTION_DAYS} days..."
    find "${BACKUP_DIR}" -name "brain-backup-*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete 2>/dev/null || true
    
    # Keep only last N backups
    log "Keeping only last ${RETENTION_COUNT} backups..."
    local backup_count
    backup_count=$(find "${BACKUP_DIR}" -name "brain-backup-*.tar.gz" | wc -l)
    
    if [ "${backup_count}" -gt "${RETENTION_COUNT}" ]; then
        local to_delete=$((backup_count - RETENTION_COUNT))
        find "${BACKUP_DIR}" -name "brain-backup-*.tar.gz" | sort | head -n "${to_delete}" | xargs -r rm -f
        log "Deleted ${to_delete} old backup(s)"
    fi
    
    # List remaining backups
    log "Current backups:"
    find "${BACKUP_DIR}" -name "brain-backup-*.tar.gz" -exec ls -lh {} \; | awk '{print "  " $9 " (" $5 ")"}' | tee -a "${LOG_FILE}"
}

# Function to verify backup integrity
verify_backup() {
    local archive="$1"
    
    log "Verifying backup integrity..."
    
    # Check if archive exists and is readable
    if [ ! -f "${archive}" ] || [ ! -r "${archive}" ]; then
        log_error "Backup file not found or not readable: ${archive}"
        return 1
    fi
    
    # Test archive integrity
    if ! tar -tzf "${archive}" >/dev/null 2>&1; then
        log_error "Backup archive is corrupted!"
        return 1
    fi
    
    # Verify checksum if exists
    if [ -f "${archive}.sha256" ]; then
        if command_exists sha256sum; then
            if sha256sum -c "${archive}.sha256" >/dev/null 2>&1; then
                log "Checksum verification passed ✓"
            else
                log_error "Checksum verification failed!"
                return 1
            fi
        fi
    fi
    
    log "Backup integrity verified ✓"
    return 0
}

# Main backup process
main() {
    local success=true
    
    # Perform backups
    backup_qdrant || success=false
    backup_openwebui || success=false
    backup_evolution || success=false
    backup_configs || success=false
    
    # Create manifest
    create_manifest
    
    # Compress
    local archive
    if archive=$(compress_backup); then
        # Verify
        if verify_backup "${archive}"; then
            log "✓ Backup completed successfully: ${archive}"
        else
            log_error "Backup verification failed"
            success=false
        fi
    else
        log_error "Backup compression failed"
        success=false
    fi
    
    # Cleanup old backups
    cleanup_old_backups
    
    log "=========================================="
    if [ "$success" = true ]; then
        log "Backup process completed successfully"
        log "=========================================="
        exit 0
    else
        log "Backup process completed with errors"
        log "=========================================="
        exit 1
    fi
}

# Run main function
main "$@"
