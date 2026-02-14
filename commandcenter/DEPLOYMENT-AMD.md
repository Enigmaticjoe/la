# Command Center Deployment Guide - AMD/ROCm Edition

## System Specifications

**Hardware:**
- CPU: AMD Ryzen 7 7700 (8-Core)
- RAM: 30GB DDR5 @ 6400 MT/s
- GPU: AMD Raphael (amdgpu driver)
- Storage:
  - nvme0n1: 119GB (System)
  - nvme1n1: 1.8TB (AI Data)

**Software:**
- OS: Pop!_OS 24.04 LTS
- Kernel: 6.17.9-76061709-generic
- GPU Stack: ROCm + amdgpu kernel driver
- User: jb

---

## Pre-Deployment Setup

### 1. System Prerequisites

Run the bootstrap script with system setup flag:

```bash
sudo chmod +x command-center-bootstrap.sh
sudo ./command-center-bootstrap.sh --setup-system --user jb
```

This will:
- Add user 'jb' to 'render' and 'video' groups for GPU access
- Create /mnt/jai_data directory
- Install node_exporter (system metrics)
- Install amd_gpu_exporter (AMD GPU metrics)
- Configure Prometheus targets

**IMPORTANT:** After running this, user 'jb' must **log out and back in** for group changes to take effect.

### 2. Mount AI Data Drive (Optional)

If you want to use the 1.8TB NVMe drive for AI data:

```bash
# WARNING: This will ERASE all data on /dev/nvme1n1!
sudo mkfs.ext4 /dev/nvme1n1

# Mount it
sudo mount /dev/nvme1n1 /mnt/jai_data

# Make it persistent across reboots
echo '/dev/nvme1n1 /mnt/jai_data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab

# Set ownership
sudo chown -R jb:jb /mnt/jai_data
```

### 3. Verify AMD GPU Access

```bash
sudo ./command-center-bootstrap.sh --verify-gpu
```

Expected output:
- ✅ AMD GPU detected
- ✅ amdgpu kernel module loaded
- ✅ ROCm interface detected (/dev/kfd)
- ✅ Render node detected (/dev/dri/renderD128)

---

## Deployment

### 1. Deploy the Stack

```bash
cd /home/user/brain
docker compose up -d
```

### 2. Monitor Startup

Watch the logs to ensure services start correctly:

```bash
# Watch all services
docker compose logs -f

# Watch Ollama (most critical)
docker compose logs -f chimera_brain

# Check service status
docker compose ps
```

### 3. Verify GPU Access in Container

Once chimera_brain is running:

```bash
docker exec chimera_brain ls -la /dev/kfd /dev/dri/
```

You should see both devices accessible.

### 4. Test Ollama API

```bash
# Check if Ollama is responding
curl http://localhost:11434/api/tags

# Should return JSON with available models
```

---

## Key Differences from NVIDIA Version

### Docker Compose Changes

1. **Ollama Image:**
   - Changed from `ollama/ollama:latest` to `ollama/ollama:rocm`

2. **GPU Access:**
   - Replaced NVIDIA deploy section with AMD device access:
     ```yaml
     devices:
       - /dev/kfd:/dev/kfd
       - /dev/dri:/dev/dri
     group_add:
       - video
       - render
     security_opt:
       - seccomp:unconfined
     ```

3. **Environment Variables:**
   - Removed: `NVIDIA_VISIBLE_DEVICES`, `CUDA_VISIBLE_DEVICES`
   - Added: `HSA_OVERRIDE_GFX_VERSION=11.0.0`, `ROC_ENABLE_PRE_VEGA=1`

4. **Memory Constraints:**
   - Reduced `OLLAMA_MAX_LOADED_MODELS` from 3 to 2
   - Bootstrap only pulls smaller models:
     - llama3.2 (2GB)
     - nomic-embed-text (270MB)
     - llama3.1:8b (4.7GB)
   - Skips large models like dolphin-mistral:8x7b (46GB) and nous-hermes-2:34b (19GB)

5. **ComfyUI:**
   - Changed to `yanwk/comfyui-boot:rocm` for AMD GPU support

6. **AllTalk TTS:**
   - Using CPU mode due to limited ROCm support: `USE_CPU=true`

### Bootstrap Script Changes

1. **GPU Detection:**
   - Checks for `amdgpu` kernel module instead of `nvidia-smi`
   - Verifies `/dev/kfd` and `/dev/dri/renderD128` instead of NVIDIA devices

2. **GPU Exporter:**
   - Replaced `nvidia_gpu_exporter` with custom AMD GPU exporter
   - Three variants:
     - ROCm-based (if `rocm-smi` available)
     - AMD SMI-based (if `amd-smi` available)
     - sysfs-based (fallback, reads `/sys/class/drm/card0/device/`)

3. **User Permissions:**
   - Adds user to `render` and `video` groups instead of NVIDIA-specific groups

---

## Service Endpoints

After deployment, access services at:

- **Open WebUI (Chat):** http://localhost:3000
- **Ollama API:** http://localhost:11434
- **Qdrant (Vector DB):** http://localhost:6333
- **ComfyUI (Image Gen):** http://localhost:8188
- **SearXNG (Search):** http://localhost:8081
- **AllTalk TTS:** http://localhost:8880
- **Dashboard:** http://localhost:3001
- **Node Exporter (Metrics):** http://localhost:9100/metrics
- **AMD GPU Exporter (Metrics):** http://localhost:9400/metrics

---

## Troubleshooting

### Issue: GPU not detected in Ollama

**Symptoms:**
```
docker exec chimera_brain rocm-smi
# Returns: error or "No AMD GPU detected"
```

**Solution:**
```bash
# Verify GPU access from host
ls -la /dev/kfd /dev/dri/

# Check container can see devices
docker exec chimera_brain ls -la /dev/kfd /dev/dri/

# Restart with --privileged (testing only)
docker run --rm --privileged -it ollama/ollama:rocm bash
```

### Issue: Models fail to load (Out of Memory)

**Symptoms:**
```
Error: failed to load model: out of memory
```

**Solution:**
```bash
# Check model size before pulling
curl http://localhost:11434/api/show -d '{"name": "model_name"}'

# Use quantized models (Q4 or Q5)
# Instead of: llama3.1:70b
# Use: llama3.1:8b or llama3.2

# Reduce max loaded models
# Edit docker-compose.yml:
# OLLAMA_MAX_LOADED_MODELS=1
```

### Issue: Permission denied accessing GPU

**Symptoms:**
```
Error: permission denied: /dev/kfd
```

**Solution:**
```bash
# Check user groups
groups jb

# Should show: jb video render

# If not, run bootstrap again
sudo ./command-center-bootstrap.sh --setup-system --user jb

# Log out and back in
exit
# Then SSH/login again
```

### Issue: ROCm version mismatch

**Symptoms:**
```
HSA Error: Incompatible ROCm version
```

**Solution:**
```bash
# Set GFX version override in docker-compose.yml
environment:
  - HSA_OVERRIDE_GFX_VERSION=11.0.0  # Try 10.3.0 if 11.0.0 fails

# Restart container
docker compose restart chimera_brain
```

### Issue: Kernel 6.17.9 instability

**Note:** The audit detected kernel 6.17.9-76061709-generic might limit stability.

**Recommended:**
```bash
# Check available kernels
dpkg --list | grep linux-image

# Install LTS kernel
sudo apt install linux-image-generic-lts-24.04

# Update GRUB and reboot
sudo update-grub
sudo reboot
```

---

## Performance Optimization

### Recommended Model Selection for 30GB RAM

**Lightweight (< 5GB VRAM):**
- llama3.2 (2GB) - Fast responses
- phi-3 (2.3GB) - Good balance
- llama3.1:8b (4.7GB) - Main workhorse

**Medium (5-15GB VRAM):**
- mistral:7b-instruct-q6_K (6GB) - Instruction-tuned
- neural-chat:7b-v3 (4.1GB) - Conversational
- codellama:13b (7.4GB) - Coding tasks

**Heavy (> 15GB VRAM) - NOT RECOMMENDED:**
- ❌ nous-hermes-2:34b (19GB) - Too large for 30GB system
- ❌ dolphin-mistral:8x7b (46GB) - Will cause OOM errors

### CPU Optimization

```bash
# Set CPU governor to performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Check current governor
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
```

### GPU Optimization

```bash
# Monitor GPU usage
watch -n 1 'cat /sys/class/drm/card0/device/gpu_busy_percent'

# Check GPU memory
cat /sys/class/drm/card0/device/mem_info_vram_total
cat /sys/class/drm/card0/device/mem_info_vram_used
```

---

## Monitoring

### Prometheus + Grafana (Optional)

If you have Prometheus and Grafana set up:

1. **Prometheus targets are automatically configured** at:
   `/etc/prometheus/targets/command-center-exporters.yml`

2. **Scrape endpoints:**
   - Node metrics: http://localhost:9100/metrics
   - AMD GPU metrics: http://localhost:9400/metrics

3. **Sample Grafana queries:**

```promql
# CPU usage
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# GPU temperature
amd_gpu_temperature

# GPU utilization
amd_gpu_utilization

# Memory usage
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

---

## Scaling Options

### Adding More Models

```bash
# Pull additional models (check size first)
docker exec chimera_brain ollama pull model_name

# List available models
docker exec chimera_brain ollama list

# Remove unused models
docker exec chimera_brain ollama rm model_name
```

### Using External GPU (Future)

If you add a dedicated GPU:

```yaml
# In docker-compose.yml, add to chimera_artist:
environment:
  - CUDA_VISIBLE_DEVICES=1  # Or HIP_VISIBLE_DEVICES for AMD
```

---

## Backup & Recovery

### Backup Docker Volumes

```bash
# Backup all volumes
docker run --rm \
  -v chimera_ollama_models:/source:ro \
  -v /mnt/jai_data/backups:/backup \
  alpine tar czf /backup/ollama_models_$(date +%F).tar.gz -C /source .

# Repeat for other volumes
# - qdrant_data
# - openwebui_data
# - comfyui_models
```

### Restore from Backup

```bash
docker run --rm \
  -v chimera_ollama_models:/target \
  -v /mnt/jai_data/backups:/backup:ro \
  alpine tar xzf /backup/ollama_models_YYYY-MM-DD.tar.gz -C /target
```

---

## Next Steps

1. **Access Open WebUI:** http://localhost:3000
2. **Test a simple prompt:** "Hello, how are you?"
3. **Check GPU usage:** `curl http://localhost:9400/metrics | grep temperature`
4. **Install additional models** as needed (stay under ~15GB for stability)
5. **Configure Home Assistant** integration if desired
6. **Set up backups** for critical volumes

---

## Support & Resources

- **Ollama ROCm Docs:** https://github.com/ollama/ollama/blob/main/docs/gpu.md
- **AMD GPU Support:** https://rocm.docs.amd.com/
- **ComfyUI ROCm:** https://github.com/YanWenKun/ComfyUI-Docker
- **Project Issues:** Check REVISION-NOTES.md for known issues

---

**Deployment Complete!** 🚀

Your AMD-powered AI stack is ready for action. Remember to monitor resource usage and adjust model selection based on your 30GB RAM constraint.
