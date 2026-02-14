# Digital Renegade Pre-Install Auditor Guide

## Overview

The **Pre-Install Auditor** is a comprehensive system validation and preparation script that checks your system for compatibility, cleans up conflicts, and prepares the environment for Digital Renegade deployment.

**Run this BEFORE installing the Digital Renegade stack!**

## Quick Start

```bash
# Standard audit (recommended first run)
sudo bash pre-install-auditor.sh

# Auto-fix issues
sudo bash pre-install-auditor.sh --auto-fix

# Deep clean (removes ALL Docker data - use with caution)
sudo bash pre-install-auditor.sh --deep-clean --auto-fix

# Dry run (check only, don't modify anything)
sudo bash pre-install-auditor.sh --dry-run
```

## What It Checks

### 1. System Requirements ✓

#### Operating System
- **Validates Ubuntu version**
  - ✅ Ubuntu 25.10 "Questing Quokka" (optimal)
  - ⚠️ Ubuntu 24.04 LTS (compatible, missing some features)
  - ⚠️ Ubuntu 22.04 LTS (works but upgrade recommended)
- **Detects installation type** (desktop vs server)
- **Checks `/etc/os-release`** for proper OS detection

#### Hardware Validation
- **CPU**: Checks core count (recommends 8+ cores)
- **RAM**: Validates memory (requires 32GB minimum, recommends 64GB+)
- **Disk Space**:
  - Checks root partition (requires 100GB minimum, recommends 500GB+)
  - Detects SSD vs HDD (SSD strongly recommended)
  - Validates available space for AI models

#### GPU Detection
- **NVIDIA GPU**: Detects GPU model and VRAM
- **Driver Validation**: Checks `nvidia-smi` availability and version
- **VRAM Check**: Validates VRAM (recommends 8GB+, optimal 12GB+)
- **CUDA Version**: Reports CUDA compatibility
- **AMD GPU**: Detects AMD GPUs (with warning that NVIDIA is preferred)

### 2. Network Configuration ✓

- **Internet Connectivity**: Validates external connectivity (required for pulling images)
- **Local IP Detection**: Checks IP address and subnet
- **Subnet Validation**: Verifies if IP is in expected 192.168.1.0/24 range
- **NIC Detection**: Counts active network interfaces
- **Multi-NIC Support**: Recommends bonding if multiple NICs detected

### 3. Port Conflict Detection ✓

Checks if critical ports are available:

| Port | Service | Purpose |
|------|---------|---------|
| 9000 | Portainer | Container management UI |
| 9443 | Portainer SSL | Secure container management |
| 11434 | Ollama Brain | Main LLM inference |
| 11435 | Ollama Eyes | Vision model inference |
| 3000 | Open WebUI | Chat interface |
| 6333 | Qdrant HTTP | Vector database |
| 6334 | Qdrant gRPC | Vector database (gRPC) |
| 8188 | ComfyUI | Image generation |
| 8123 | Home Assistant | Smart home hub |
| 1880 | Node-RED | Automation flows |
| 5432 | PostgreSQL | Relational database |
| 6379 | Redis | Cache/message queue |
| 8092 | Persona Manager | Mode switching service |

**Features**:
- Identifies processes using conflicting ports
- Shows PID and process name for conflicts
- Recommends stopping/disabling conflicting services

### 4. Service Conflicts ✓

- **Existing Ollama**: Detects system Ollama service (conflicts with containerized version)
- **Running Containers**: Lists all running Docker containers
- **Existing Portainer**: Checks for previous Portainer installations
- **Auto-Fix**: Can stop/disable conflicting services with permission

### 5. Docker Environment ✓

#### Docker Installation
- **Docker Version**: Validates Docker installation and version
- **Docker Daemon**: Checks if Docker service is running
- **Docker Compose**: Validates Compose plugin availability
- **Auto-Start**: Can enable Docker to start on boot

#### NVIDIA Container Toolkit
- **Runtime Test**: Tests GPU access from containers
- **daemon.json Check**: Validates NVIDIA runtime configuration
- **CUDA Test**: Runs test container to verify GPU passthrough

#### Storage Analysis
- **Docker Root Dir**: Reports Docker data location
- **Disk Usage**: Shows Docker storage consumption
- **Available Space**: Validates sufficient space for images/volumes
- **Dangling Resources**: Counts unused images/volumes

### 6. Filesystem Structure ✓

#### Required Directories
Validates and can create:
```
/home/user/brain/
├── config/
│   ├── personas/
│   └── operational_modes/
└── agents/
```

#### Required Files
Checks for:
- `portainer-stack-renegade.yml`
- `config/personas/renegade_master.json`
- `config/operational_modes/mode_definitions.json`

#### Optional Storage Paths
Checks for (and reports availability):
- `/mnt/warm` - Warm storage for vector databases
- `/mnt/hot` - Hot storage for active data
- `/mnt/cold` - Cold storage for archives

### 7. Mount Points ✓

- **NFS Detection**: Checks `/etc/fstab` for NFS mounts
- **Mount Status**: Validates if NFS shares are mounted
- **Auto-Mount**: Can attempt to mount NFS shares
- **Storage Reporting**: Shows available space on each mount

### 8. Security Validation ✓

- **Firewall Status**: Checks UFW (Uncomplicated Firewall)
- **System Updates**: Counts available package updates
- **SSH Configuration**:
  - Warns if root login enabled
  - Checks password authentication status
- **Recommendations**: Provides security hardening suggestions

## Cleanup Operations

### Standard Cleanup (Safe)

Removes:
- Dangling Docker images
- Dangling Docker volumes
- Unused Docker networks
- Stopped containers (with confirmation)

### Deep Clean (⚠️ DESTRUCTIVE)

**WARNING: Removes ALL Docker data!**

Use only if:
- Starting fresh installation
- Existing Docker setup is corrupted
- You have backed up important data

Removes:
- All containers (running and stopped)
- All images
- All volumes (including data!)
- All custom networks

### System Cleanup

- **Journal Logs**: Cleans systemd journal logs older than 7 days
- **APT Cache**: Removes cached package files
- **Temp Files**: Cleans `/tmp` files older than 7 days

## Command-Line Options

### `--auto-fix`

Automatically fixes issues where possible without prompting.

**Use when**:
- Running in automation/CI
- You trust the script to make changes
- You've reviewed the dry-run output

**Example**:
```bash
sudo bash pre-install-auditor.sh --auto-fix
```

### `--deep-clean`

Enables aggressive cleanup mode.

**⚠️ WARNING**: Removes ALL Docker data (containers, images, volumes)

**Use when**:
- Starting completely fresh
- Docker environment is corrupted
- You've backed up important data

**Example**:
```bash
# Dry run first to see what would be deleted
sudo bash pre-install-auditor.sh --deep-clean --dry-run

# Actually perform deep clean
sudo bash pre-install-auditor.sh --deep-clean --auto-fix
```

### `--dry-run`

Check-only mode - reports issues but makes NO changes.

**Use when**:
- Initial assessment
- Verifying system readiness
- Previewing cleanup operations

**Example**:
```bash
sudo bash pre-install-auditor.sh --dry-run
```

### Combining Options

```bash
# Recommended: Dry run with deep clean preview
sudo bash pre-install-auditor.sh --deep-clean --dry-run

# Full automated deep clean (DESTRUCTIVE)
sudo bash pre-install-auditor.sh --deep-clean --auto-fix

# Safe auto-fix without deep clean
sudo bash pre-install-auditor.sh --auto-fix
```

## Output Files

### Audit Report
**Location**: `/tmp/renegade_audit_report.txt`

Contains:
- Summary statistics (warnings, errors, fixes)
- System information
- GPU details
- Docker status
- Recommendations

**Example**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Digital Renegade Pre-Install Audit Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SUMMARY
━━━━━━━
✓ Checks Passed
⚠ Warnings: 3
✗ Errors: 0
🔧 Issues Fixed: 5

SYSTEM INFORMATION
━━━━━━━━━━━━━━━━━━
OS: Ubuntu 25.10 (Questing Quokka)
CPU Cores: 14
RAM: 96GB
Disk Available: 850G

RECOMMENDATIONS
━━━━━━━━━━━━━━━
✓ System ready for Digital Renegade deployment!
```

### Detailed Log
**Location**: `/var/log/renegade_auditor.log`

Contains:
- Timestamped entries for all operations
- Detailed error messages
- Command outputs
- Fix operations performed

### Backup Directory
**Location**: `/var/backups/renegade_preinstall_YYYYMMDD_HHMMSS/`

Contains backups of:
- `docker-compose.yml` (if exists)
- `config/` directory
- Docker volumes list
- Network configuration

## Interpreting Results

### ✓ Success (Green)
No action required - check passed successfully.

### ⚠ Warning (Yellow)
**Non-critical issues** - system will work but may have limitations.

**Common warnings**:
- Less than 64GB RAM (32-64GB range)
- Ubuntu 24.04 instead of 25.10
- Port conflicts (can be resolved)
- Missing optional directories

**Action**: Review warnings and decide if acceptable for your use case.

### ✗ Error (Red)
**Critical issues** - must be fixed before installation.

**Common errors**:
- Less than 32GB RAM
- Less than 100GB disk space
- No internet connectivity
- Required files missing
- Docker not installed

**Action**: Fix errors before proceeding with installation.

### 🔧 Fixed (Green)
Issue was automatically fixed by the script.

**Examples**:
- Started Docker daemon
- Created missing directories
- Stopped conflicting services
- Cleaned up dangling resources

## Typical Workflows

### 1. First-Time Assessment

```bash
# Run dry-run to see current state
sudo bash pre-install-auditor.sh --dry-run

# Review report
cat /tmp/renegade_audit_report.txt

# If acceptable, run with auto-fix
sudo bash pre-install-auditor.sh --auto-fix
```

### 2. Fresh Installation (Clean Slate)

```bash
# Preview deep clean
sudo bash pre-install-auditor.sh --deep-clean --dry-run

# Perform deep clean and auto-fix
sudo bash pre-install-auditor.sh --deep-clean --auto-fix

# Verify clean state
docker ps -a
docker images
docker volume ls
```

### 3. Existing Docker Environment

```bash
# Standard audit without deep clean
sudo bash pre-install-auditor.sh

# Review conflicts
cat /tmp/renegade_audit_report.txt

# Manually stop conflicting services
docker stop <container_name>
systemctl stop ollama

# Re-run audit
sudo bash pre-install-auditor.sh --auto-fix
```

### 4. Troubleshooting Failed Installation

```bash
# Check what went wrong
sudo bash pre-install-auditor.sh --dry-run

# Review detailed log
tail -n 100 /var/log/renegade_auditor.log

# Clean up and retry
sudo bash pre-install-auditor.sh --auto-fix
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (no errors, warnings OK) |
| 1 | Critical errors found (must fix before install) |

## Recommended Pre-Install Sequence

```bash
# 1. Download or clone repository
cd /home/user/brain

# 2. Run auditor dry-run
sudo bash pre-install-auditor.sh --dry-run

# 3. Review report
cat /tmp/renegade_audit_report.txt

# 4. Fix any critical errors manually (if needed)

# 5. Run auditor with auto-fix
sudo bash pre-install-auditor.sh --auto-fix

# 6. Verify readiness
cat /tmp/renegade_audit_report.txt

# 7. Proceed with installation
sudo bash install-renegade-portainer.sh
```

## Common Issues & Fixes

### Issue: "Docker not installed"

**Solution**:
```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Re-run auditor
sudo bash pre-install-auditor.sh --auto-fix
```

### Issue: "NVIDIA driver not installed"

**Solution (Ubuntu 25.10)**:
```bash
# Install NVIDIA driver (580 branch)
sudo ubuntu-drivers install --gpgpu

# Reboot
sudo reboot

# Re-run auditor
sudo bash pre-install-auditor.sh
```

### Issue: "Port 11434 already in use by Ollama"

**Auto-fix** (script will offer):
```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
```

**Manual fix**:
```bash
sudo systemctl stop ollama
sudo systemctl disable ollama
sudo bash pre-install-auditor.sh --auto-fix
```

### Issue: "Less than 32GB RAM"

**No fix** - hardware limitation. Digital Renegade requires minimum 32GB.

**Options**:
- Upgrade RAM
- Use a different system
- Limit number of simultaneous models (not recommended)

### Issue: "Dangling Docker volumes consuming space"

**Auto-fix**:
```bash
sudo bash pre-install-auditor.sh --auto-fix
```

**Manual fix**:
```bash
docker volume prune -f
```

### Issue: "NFS mounts in fstab but not mounted"

**Auto-fix** (script will offer):
```bash
sudo mount -a -t nfs
```

**Manual fix**:
```bash
# Check fstab
cat /etc/fstab | grep nfs

# Mount all NFS shares
sudo mount -a -t nfs

# Or mount specific share
sudo mount -t nfs 192.168.1.222:/mnt/user/ai_data /mnt/warm
```

## Advanced Usage

### Custom Backup Location

Edit the script to change backup directory:
```bash
# Line ~25
BACKUP_DIR="/custom/backup/path/renegade_$(date +%Y%m%d_%H%M%S)"
```

### Adding Custom Checks

Add your own validation functions:

```bash
# Add after existing check functions
check_custom_requirement() {
    section "Checking Custom Requirement"

    if [[ -f /path/to/required/file ]]; then
        success "Custom requirement met"
    else
        error "Custom requirement not met"
    fi
}

# Add to main() function
main() {
    # ... existing checks ...
    check_custom_requirement
    # ... rest of main ...
}
```

### Skipping Specific Checks

Comment out checks in `main()` function:

```bash
main() {
    # ... other checks ...

    # Skip port conflict check
    # check_port_conflicts

    # ... rest of checks ...
}
```

## Integration with Installer

The main installer (`install-renegade-portainer.sh`) will check if the auditor has been run:

```bash
# Installer checks for audit report
if [[ ! -f /tmp/renegade_audit_report.txt ]]; then
    echo "⚠️  Pre-install auditor has not been run!"
    echo "Run: sudo bash pre-install-auditor.sh"
    exit 1
fi
```

**Recommended**: Always run auditor before installer.

## Logs & Troubleshooting

### View Recent Audit Log
```bash
tail -n 100 /var/log/renegade_auditor.log
```

### View Full Audit Log
```bash
less /var/log/renegade_auditor.log
```

### Search Log for Errors
```bash
grep -i error /var/log/renegade_auditor.log
```

### View Audit Report
```bash
cat /tmp/renegade_audit_report.txt
```

### Check Backup Contents
```bash
ls -la /var/backups/renegade_preinstall_*/
```

## Security Considerations

### Running as Root

The auditor **must** run as root because it:
- Modifies system services
- Accesses Docker socket
- Checks firewall configuration
- Installs packages (if needed)
- Mounts filesystems

**Safety measures**:
- Creates backups before changes
- Prompts for confirmation (unless `--auto-fix`)
- Dry-run mode available
- All actions logged

### What Gets Modified

**With default options**:
- Docker cleanup (dangling resources only)
- Log rotation (journals older than 7 days)
- APT cache cleanup
- Directory creation (if missing)

**With `--auto-fix`**:
- Stops conflicting services
- Disables Ollama system service
- Mounts NFS shares
- Starts Docker daemon

**With `--deep-clean`**:
- ⚠️ Removes ALL Docker containers
- ⚠️ Removes ALL Docker images
- ⚠️ Removes ALL Docker volumes (DATA LOSS!)
- ⚠️ Removes ALL custom networks

### Network Security

The auditor does NOT:
- Open firewall ports
- Modify iptables rules
- Change SSH configuration
- Expose services to internet

It DOES:
- Check firewall status
- Report security warnings
- Recommend hardening measures

## Support & Troubleshooting

### Getting Help

1. **Check audit report**: `/tmp/renegade_audit_report.txt`
2. **Review logs**: `/var/log/renegade_auditor.log`
3. **Run dry-run**: See what would be changed
4. **Check backups**: `/var/backups/renegade_preinstall_*/`

### Reporting Issues

Include:
- Audit report output
- Relevant log excerpts
- System specifications (`lsb_release -a`, `uname -r`)
- GPU information (`nvidia-smi`)

### Recovery

If something goes wrong:

```bash
# Restore from backup
LATEST_BACKUP=$(ls -td /var/backups/renegade_preinstall_* | head -1)
echo "Latest backup: $LATEST_BACKUP"

# Restore docker-compose.yml
cp $LATEST_BACKUP/docker-compose.yml /home/user/brain/

# Restore config
cp -r $LATEST_BACKUP/config /home/user/brain/
```

## Version History

- **v1.0** (2025-12-27): Initial release
  - Comprehensive system validation
  - Docker environment checks
  - Cleanup operations
  - Backup functionality
  - Auto-fix capabilities

## License

Part of the Digital Renegade project.

---

**Next Steps**: After running the auditor successfully, proceed to:
```bash
sudo bash install-renegade-portainer.sh
```
