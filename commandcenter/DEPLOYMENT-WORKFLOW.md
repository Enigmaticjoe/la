# Digital Renegade Deployment Workflow

## Complete Installation Process

The Digital Renegade system uses a **two-stage deployment process** to ensure successful installation:

1. **Pre-Install Auditor** - Validates system and prepares environment
2. **Main Installer** - Deploys Portainer and Digital Renegade stack

---

## Quick Start (3 Commands)

```bash
# 1. Run pre-install auditor
sudo bash pre-install-auditor.sh --auto-fix

# 2. Review audit report
cat /tmp/renegade_audit_report.txt

# 3. Deploy Digital Renegade
sudo bash install-renegade-portainer.sh
```

---

## Detailed Workflow

### Stage 1: Pre-Install Auditor

#### Purpose
Validates system readiness, detects conflicts, and prepares the environment.

#### First Run (Assessment)

```bash
# Dry-run to see what would be checked/changed
sudo bash pre-install-auditor.sh --dry-run
```

**What it checks**:
- ✅ Ubuntu 25.10 "Questing Quokka" (or compatible version)
- ✅ CPU: 8+ cores (14-core i5-13600K ideal)
- ✅ RAM: 32GB minimum, 64GB+ recommended
- ✅ Disk: 100GB minimum, 500GB+ recommended
- ✅ GPU: NVIDIA RTX 4070 (12GB VRAM)
- ✅ NVIDIA Driver: Version 580+ for Ubuntu 25.10
- ✅ CUDA: Version 11.8+
- ✅ Docker: Installed and running
- ✅ Docker Compose: Plugin available
- ✅ NVIDIA Container Toolkit: GPU passthrough working
- ✅ Port availability: 20+ critical ports (Ollama, Portainer, etc.)
- ✅ Service conflicts: Ollama, Portainer duplicates
- ✅ Filesystem: Required directories and files
- ✅ Network: Internet connectivity, local subnet (192.168.1.0/24)
- ✅ NFS mounts: Unraid @ 192.168.1.222 (optional)
- ✅ Security: Firewall, updates, SSH configuration

**Output**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Digital Renegade Pre-Install Audit Report
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SUMMARY
━━━━━━━
✓ Checks Passed
⚠ Warnings: 2
✗ Errors: 0
🔧 Issues Fixed: 0

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

#### Second Run (Fixes)

```bash
# Auto-fix detected issues
sudo bash pre-install-auditor.sh --auto-fix
```

**What it fixes**:
- 🔧 Creates missing directories
- 🔧 Stops conflicting services (Ollama system service)
- 🔧 Cleans dangling Docker resources
- 🔧 Starts Docker daemon if stopped
- 🔧 Mounts NFS shares if configured
- 🔧 Cleans system logs and APT cache

**Backup created**: `/var/backups/renegade_preinstall_YYYYMMDD_HHMMSS/`

#### Deep Clean (Optional)

⚠️ **WARNING**: Only use if starting completely fresh

```bash
# Preview what would be deleted
sudo bash pre-install-auditor.sh --deep-clean --dry-run

# Actually perform deep clean
sudo bash pre-install-auditor.sh --deep-clean --auto-fix
```

**Removes**:
- ALL Docker containers
- ALL Docker images
- ALL Docker volumes (⚠️ DATA LOSS)
- ALL custom networks

---

### Stage 2: Main Installer

#### Prerequisites
- Pre-install auditor has been run successfully
- No critical errors in audit report
- System meets minimum requirements

#### Run Installer

```bash
sudo bash install-renegade-portainer.sh
```

**What it does**:
1. **Validates** auditor was run (checks `/tmp/renegade_audit_report.txt`)
2. **Checks** for critical errors in audit
3. **Collects** credentials:
   - PostgreSQL password
   - Home Assistant token (optional)
   - Blue Iris username/password (optional)
4. **Installs** system dependencies:
   - Docker (if not present)
   - Docker Compose plugin
   - NVIDIA drivers (Ubuntu 25.10: 580 branch)
   - NVIDIA Container Toolkit
   - NFS client (for Unraid)
5. **Configures** Docker daemon:
   - NVIDIA runtime
   - GPU passthrough
   - Daemon.json optimization
6. **Mounts** Unraid storage (if available):
   - NFS mount to `/mnt/brain_memory`
   - Persistent fstab entry
7. **Deploys** Portainer:
   - Latest version
   - Admin user: `admin`
   - Accessible: `http://192.168.1.9:9000`
8. **Provides** deployment instructions for Portainer stack

#### Post-Install Steps

**Access Portainer**:
```
http://192.168.1.9:9000
```

**Deploy Digital Renegade Stack**:
1. Login to Portainer
2. Navigate to **Stacks** → **Add Stack**
3. Name: `digital-renegade`
4. Upload: `/home/user/brain/portainer-stack-renegade.yml`
5. Click **Deploy Stack**

**Wait for bootstrap** (~10-30 minutes):
- Ollama pulls AI models (~25GB download)
- Vision models (LLaVA, BakLLaVA)
- Chat models (dolphin-mistral, nous-hermes-2, llama3.1/3.2)

**Access services**:
```
Open WebUI:        http://192.168.1.9:3000
Ollama Brain:      http://192.168.1.9:11434
Ollama Eyes:       http://192.168.1.9:11435
ComfyUI:           http://192.168.1.9:8188
Qdrant:            http://192.168.1.9:6333
Home Assistant:    http://192.168.1.149:8123 (external)
Blue Iris:         http://192.168.1.232 (external)
```

---

## Troubleshooting Workflow

### Issue: Auditor reports errors

**Symptoms**:
```
✗ Errors: 3
⚠ Less than 32GB RAM
⚠ Port 11434 already in use
⚠ NVIDIA driver not installed
```

**Solution**:
```bash
# Fix each error manually or use auto-fix
sudo bash pre-install-auditor.sh --auto-fix

# Re-run to verify fixes
sudo bash pre-install-auditor.sh --dry-run
```

### Issue: Installer fails to start

**Symptoms**:
```
✗ Pre-install auditor has not been run!
```

**Solution**:
```bash
# Run auditor first
sudo bash pre-install-auditor.sh --auto-fix

# Then retry installer
sudo bash install-renegade-portainer.sh
```

### Issue: Docker won't start

**Check**:
```bash
sudo systemctl status docker
sudo journalctl -u docker -n 50
```

**Fix**:
```bash
sudo systemctl restart docker
sudo systemctl enable docker
```

### Issue: GPU not accessible in Docker

**Check**:
```bash
# Test GPU passthrough
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

**Fix**:
```bash
# Reinstall NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Issue: Models fail to download

**Symptoms**:
```
chimera_bootstrap | Error: connection refused
```

**Check**:
```bash
# Verify Ollama is running
docker logs chimera_brain

# Check network
docker network inspect chimera_net
```

**Fix**:
```bash
# Restart Ollama
docker restart chimera_brain

# Wait 30 seconds
sleep 30

# Restart bootstrap
docker restart chimera_bootstrap
```

### Issue: Out of VRAM

**Symptoms**:
```
RuntimeError: CUDA out of memory
```

**Check**:
```bash
nvidia-smi
```

**Fix**:
```bash
# Limit simultaneous models in portainer-stack-renegade.yml
environment:
  - OLLAMA_MAX_LOADED_MODELS=2  # Down from 3
  - OLLAMA_KEEP_ALIVE=5m        # Auto-unload after 5 min
```

---

## Advanced Scenarios

### Fresh Installation (New System)

```bash
# 1. Clone repository
cd /home/user
git clone https://github.com/Enigmaticjoe/brain.git
cd brain

# 2. Run deep clean auditor
sudo bash pre-install-auditor.sh --deep-clean --auto-fix

# 3. Install
sudo bash install-renegade-portainer.sh

# 4. Deploy via Portainer UI
```

### Upgrade Existing System

```bash
# 1. Backup current setup
sudo cp -r /home/user/brain /home/user/brain.backup.$(date +%Y%m%d)
docker volume ls > /tmp/docker_volumes_backup.txt

# 2. Run auditor (no deep clean)
sudo bash pre-install-auditor.sh --auto-fix

# 3. Pull latest changes
cd /home/user/brain
git pull

# 4. Redeploy stack via Portainer
# (Portainer UI: Stacks → digital-renegade → Update)
```

### Migration from Another Host

```bash
# On old host: Export data
docker stop $(docker ps -q)
tar -czf /tmp/docker_volumes.tar.gz -C /var/lib/docker/volumes .

# On new host: Run auditor
sudo bash pre-install-auditor.sh --deep-clean --auto-fix

# Install base system
sudo bash install-renegade-portainer.sh

# Restore volumes (before deploying stack)
sudo tar -xzf docker_volumes.tar.gz -C /var/lib/docker/volumes/

# Deploy stack via Portainer
```

### Headless Server (No GUI)

```bash
# 1. Set multi-user target (no GUI)
sudo systemctl set-default multi-user.target

# 2. Disable unnecessary services
sudo systemctl disable gdm
sudo systemctl disable display-manager

# 3. Run auditor
sudo bash pre-install-auditor.sh --auto-fix

# 4. Install (all CLI)
sudo bash install-renegade-portainer.sh

# 5. Access Portainer from another machine
# http://192.168.1.9:9000
```

---

## Verification Checklist

After deployment, verify all services are running:

### Core Services
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep chimera
```

**Expected output**:
```
chimera_brain         Up 5 minutes     0.0.0.0:11434->11434/tcp
chimera_eyes          Up 5 minutes     0.0.0.0:11435->11434/tcp
chimera_face          Up 5 minutes     0.0.0.0:3000->8080/tcp
chimera_memory        Up 5 minutes     0.0.0.0:6333-6334->6333-6334/tcp
chimera_artist        Up 5 minutes     0.0.0.0:8188->8188/tcp
chimera_voice         Up 5 minutes     0.0.0.0:7851->7851/tcp
chimera_ears          Up 5 minutes     0.0.0.0:9000->9000/tcp
chimera_persona       Up 5 minutes     0.0.0.0:8092->8092/tcp
```

### Model Downloads
```bash
# Check bootstrap logs
docker logs chimera_bootstrap

# Should show:
# ✓ dolphin-mistral:8x7b pulled
# ✓ llava:13b pulled
# ✓ bakllava pulled
# ✓ llama3.1:8b pulled
# ... etc
```

### GPU Access
```bash
# From Ollama Brain
docker exec chimera_brain nvidia-smi

# From Ollama Eyes
docker exec chimera_eyes nvidia-smi
```

### API Endpoints
```bash
# Ollama Brain
curl http://192.168.1.9:11434/api/tags

# Ollama Eyes
curl http://192.168.1.9:11435/api/tags

# Qdrant
curl http://192.168.1.9:6333/collections
```

### Web Interfaces
- [ ] Portainer: http://192.168.1.9:9000
- [ ] Open WebUI: http://192.168.1.9:3000
- [ ] ComfyUI: http://192.168.1.9:8188
- [ ] Qdrant Dashboard: http://192.168.1.9:6333/dashboard

---

## Performance Optimization

### After Initial Deployment

**1. Optimize Docker Storage Driver**

Edit `/etc/docker/daemon.json`:
```json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

**2. Enable GPU Persistence Mode**

```bash
sudo nvidia-smi -pm 1
```

**3. Configure Model Preloading**

Edit `portainer-stack-renegade.yml`:
```yaml
chimera_brain:
  environment:
    - OLLAMA_KEEP_ALIVE=-1  # Never unload
    - OLLAMA_NUM_PARALLEL=4 # Parallel requests
```

**4. Optimize Qdrant**

```yaml
chimera_memory:
  environment:
    - QDRANT__STORAGE__PERFORMANCE__MAX_SEARCH_THREADS=8
```

---

## Backup Strategy

### Before Major Changes

```bash
# 1. Backup configs
sudo tar -czf /var/backups/brain_config_$(date +%Y%m%d).tar.gz \
    /home/user/brain/config \
    /home/user/brain/*.yml

# 2. Backup Docker volumes
docker volume ls -q | grep chimera > /tmp/chimera_volumes.txt

# 3. Export volume data
while read vol; do
    docker run --rm -v $vol:/data -v /var/backups:/backup \
        alpine tar czf /backup/${vol}_$(date +%Y%m%d).tar.gz /data
done < /tmp/chimera_volumes.txt

# 4. Backup Qdrant vectors
docker exec chimera_memory qdrant-cli snapshot create

# 5. Backup PostgreSQL
docker exec chimera_postgres pg_dumpall -U postgres > /var/backups/postgres_$(date +%Y%m%d).sql
```

---

## Next Steps After Deployment

1. **Configure Digital Renegade Personality**
   - Edit `/home/user/brain/config/personas/renegade_master.json`
   - Customize speech patterns, profanity level, sarcasm

2. **Set Up Operational Modes**
   - Test mode switching: `/mode HACK`, `/mode CODE`, etc.
   - Customize mode prompts in `/home/user/brain/config/operational_modes/mode_definitions.json`

3. **Integrate Smart Home**
   - Configure Home Assistant token
   - Set up Blue Iris camera feeds
   - Configure OpenRGB for mood lighting

4. **Enable RAG Knowledge Base**
   - Upload documents to Open WebUI
   - Configure Qdrant collections
   - Test retrieval with questions

5. **Security Hardening**
   - Configure UFW firewall rules
   - Set up Tailscale VPN for remote access
   - Enable SSH key-only authentication
   - Configure fail2ban

6. **Monitoring Setup**
   - Access Grafana dashboards
   - Configure Uptime Kuma alerts
   - Set up RGB alert indicators

---

## Support & Resources

- **Pre-Install Auditor Guide**: `PRE-INSTALL-AUDITOR-GUIDE.md`
- **Deployment Guide**: `DIGITAL-RENEGADE-DEPLOYMENT.md`
- **Main README**: `CLAUDE.md`
- **Logs**: `/var/log/renegade_*.log`
- **Audit Reports**: `/tmp/renegade_audit_report.txt`
- **Backups**: `/var/backups/renegade_*`

---

**Ready to Deploy?**

```bash
sudo bash pre-install-auditor.sh --auto-fix
sudo bash install-renegade-portainer.sh
```

🔥 **Welcome to Digital Renegade** 🔥
