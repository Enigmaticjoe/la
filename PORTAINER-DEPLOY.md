# 🚀 Brain Stack Deployment via Portainer

## Overview

This guide provides step-by-step instructions for deploying the Brain Stack (brain-stack.yml) through Portainer. The Brain Stack includes:

- **vLLM**: GPU-accelerated LLM inference (RX 7900 XT 20GB)
- **Qdrant**: Vector database for RAG
- **TEI Embeddings**: Text embedding inference (CPU)
- **SearXNG**: Privacy-respecting web search
- **OpenWebUI**: Full-featured chat interface with RAG

## Prerequisites

### System Requirements

- **Node**: Fedora 44 COSMIC (recommended) or Ubuntu-based Linux
- **CPU**: Intel Ultra 9 285K (or similar high-end CPU)
- **GPU**: AMD RX 7900 XT 20GB with ROCm support
- **RAM**: 128GB DDR5
- **Storage**: At least 100GB free for models and data

### Software Requirements

1. **Docker** installed and running
   ```bash
   docker --version  # Should be 20.10+ or newer
   ```

2. **Portainer** installed and accessible
   ```bash
   # Check Portainer is running
   docker ps | grep portainer
   ```

3. **ROCm** drivers installed for AMD GPU
   ```bash
   rocm-smi  # Should show your RX 7900 XT
   ```

## 🔧 Pre-Deployment Setup

### Step 1: Create Required Directories

**CRITICAL**: All directories must exist before deployment, or containers will fail to start.

Run the following commands on your Brain node:

```bash
# Create all required directories
sudo mkdir -p /home/brains/ai-models
sudo mkdir -p /home/brains/openwebui
sudo mkdir -p /home/brains/qdrant/storage
sudo mkdir -p /home/brains/qdrant/snapshots
sudo mkdir -p /home/brains/embeddings-cache
sudo mkdir -p /home/brains/searxng

# Set proper permissions (if running as non-root user)
sudo chown -R $USER:$USER /home/brains
chmod -R 755 /home/brains
```

**Verify directories exist:**
```bash
ls -la /home/brains/
```

You should see all six directories listed.

### Step 2: Generate SearXNG Configuration

Create the SearXNG settings file:

```bash
# Generate a secret key
SECRET_KEY=$(openssl rand -hex 32)

# Create settings.yml
cat > /home/brains/searxng/settings.yml <<EOF
# SearXNG settings - for brain-stack deployment
use_default_settings: true

server:
  secret_key: "$SECRET_KEY"
  limiter: false
  image_proxy: false
  method: "GET"

search:
  safe_search: 0
  autocomplete: "duckduckgo"
  default_lang: "en"
  formats:
    - html
    - json
EOF

# Create limiter.toml (disable rate limiting for single-user)
cat > /home/brains/searxng/limiter.toml <<EOF
# Limiter disabled -- single-user setup
[botdetection.ip_limit]
link_token = false
EOF

echo "✅ SearXNG configuration created"
```

### Step 3: Download AI Models (Optional but Recommended)

Pre-downloading models avoids long startup times:

```bash
# Option 1: Using brain-model-downloader.sh (recommended - fully automated)
bash brain-model-downloader.sh

# Option 2: Manual download using huggingface-cli
pip install -U huggingface_hub[hf_transfer]
huggingface-cli download cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
  --local-dir /home/brains/ai-models/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ \
  --local-dir-use-symlinks False \
  --resume-download

# Option 3: Let vLLM download on first start (adds ~10-15 min to startup)
# Skip this step if you want automatic download
```

**Note**: The TEI embeddings model (Qwen3-Embedding-0.6B, ~1.2GB) will auto-download on first start. This is why the embeddings container has a 5-minute startup grace period.

### Step 4: Verify ROCm Environment

Ensure ROCm environment variables are set (these are in the compose file, but verify your system has ROCm):

```bash
# Check ROCm installation
ls /opt/rocm

# Check GPU is detected
rocm-smi --showproductname

# Check render nodes
ls /dev/dri/render*

# Check KFD device
ls /dev/kfd
```

All these should exist. If not, install ROCm first: https://rocm.docs.amd.com/

## 🐋 Portainer Deployment

### Step 1: Access Portainer

1. Open your web browser
2. Navigate to: `http://YOUR_BRAIN_IP:9000` (replace with your actual IP)
3. Log in with your Portainer credentials

### Step 2: Create the Stack

1. Click **"Stacks"** in the left sidebar
2. Click **"+ Add stack"** button
3. **Stack name**: Enter `brain-stack`

### Step 3: Upload the Compose File

Choose one of these methods:

#### Method A: Upload (Recommended)
1. Select **"Upload"** tab
2. Click **"Upload file"**
3. Browse to and select: `brain-stack.yml`
4. Click **"Deploy the stack"**

#### Method B: Web editor
1. Select **"Web editor"** tab
2. Copy the entire contents of `brain-stack.yml`
3. Paste into the editor
4. Click **"Deploy the stack"**

#### Method C: Git repository
1. Select **"Repository"** tab
2. Repository URL: `https://github.com/Enigmaticjoe/la`
3. Repository reference: `main` (or your branch)
4. Compose path: `brain-stack.yml`
5. Click **"Deploy the stack"**

### Step 4: Monitor Deployment

After clicking deploy:

1. Portainer will create the network and pull images (2-5 minutes)
2. Containers will start in dependency order:
   - **Qdrant** starts first (~30 seconds)
   - **vLLM** starts next (2-3 minutes to load model to GPU)
   - **TEI Embeddings** starts (5-10 minutes first time due to model download)
   - **SearXNG** starts (~15 seconds)
   - **OpenWebUI** starts last (waits for all dependencies)

**Total startup time**: 10-15 minutes on first deployment (model downloads)

## 🔍 Verifying Deployment

### Check Container Status

In Portainer:
1. Go to **Stacks** → **brain-stack**
2. All containers should show green "running" status
3. Health status should show "healthy" (after startup period)

**If any container shows "unhealthy"**, wait the full startup period:
- **vLLM**: up to 4 minutes (240s start_period)
- **TEI Embeddings**: up to 10 minutes (600s start_period)
- **Qdrant**: up to 30 seconds
- **SearXNG**: up to 15 seconds
- **OpenWebUI**: up to 1 minute (waits for dependencies)

### Test Services Individually

Run these commands from any machine on your network (replace `BRAIN_IP` with actual IP):

```bash
# Replace with your Brain node's IP
BRAIN_IP="192.168.1.9"

# Test Qdrant
curl http://$BRAIN_IP:6333/healthz
# Expected: OK

# Test vLLM
curl http://$BRAIN_IP:8000/v1/models
# Expected: JSON with model info

# Test TEI Embeddings
curl http://$BRAIN_IP:8001/health
# Expected: Health status JSON

# Test SearXNG
curl http://$BRAIN_IP:8888/healthz
# Expected: OK

# Test OpenWebUI
curl http://$BRAIN_IP:3000/
# Expected: HTML page
```

### Access Web Interfaces

Open in your browser:

- **OpenWebUI**: http://BRAIN_IP:3000
  - Create your admin account on first visit
  - Configure workspace settings

- **Qdrant Dashboard**: http://BRAIN_IP:6333/dashboard
  - Monitor vector collections
  - View storage statistics

- **SearXNG**: http://BRAIN_IP:8888
  - Test web search functionality

- **vLLM API Docs**: http://BRAIN_IP:8000/docs
  - OpenAPI documentation
  - Test API endpoints

## 🐛 Troubleshooting

### Container "brain-embeddings" is Unhealthy

**Cause**: Model download in progress or healthcheck timing out

**Solution**:
1. Check logs in Portainer: **Containers** → **brain-embeddings** → **Logs**
2. Look for: "Downloading model Qwen/Qwen3-Embedding-0.6B"
3. Wait up to 10 minutes for model download to complete
4. If still failing after 10 minutes, check:
   ```bash
   # Check if directory is writable
   ls -la /home/brains/embeddings-cache
   
   # Check container logs
   docker logs brain-embeddings
   ```

**Common issues**:
- Directory `/home/brains/embeddings-cache` doesn't exist → Create it
- No disk space → Free up space
- Network issues → Check internet connectivity

### Container "brain-vllm" is Unhealthy

**Cause**: GPU not accessible, ROCm not configured, or model download in progress

**Solution**:
1. Check GPU is accessible:
   ```bash
   rocm-smi
   ls /dev/kfd /dev/dri/render*
   ```

2. Check vLLM logs:
   ```bash
   docker logs brain-vllm
   ```

3. Look for errors about:
   - GPU not found → Ensure ROCm drivers installed
   - Model not found → Wait for download or pre-download model
   - Out of memory → Reduce `--gpu-memory-utilization` (currently 0.90)

### OpenWebUI Can't Connect to Services

**Cause**: Network issues or services not ready

**Solution**:
1. Verify all dependencies are healthy:
   ```bash
   docker ps --filter name=brain-
   ```

2. All should show "healthy" status

3. Check OpenWebUI logs:
   ```bash
   docker logs brain-openwebui
   ```

4. If services not connecting, check network:
   ```bash
   docker network inspect brain-stack_brain_net
   ```

### Port Already in Use

**Error**: "Bind for 0.0.0.0:8000 failed: port is already allocated"

**Solution**:
```bash
# Find what's using the port
sudo lsof -i :8000

# Kill the process or change port in brain-stack.yml
# Edit the ports section for the conflicting service
```

### Qdrant Storage Permission Denied

**Solution**:
```bash
# Fix permissions
sudo chown -R 1000:1000 /home/brains/qdrant/storage
sudo chown -R 1000:1000 /home/brains/qdrant/snapshots
```

### SearXNG Config Missing

**Error**: Container exits immediately

**Solution**:
```bash
# Recreate SearXNG config (see Step 2 above)
# Ensure /home/brains/searxng/settings.yml exists
ls -la /home/brains/searxng/
```

## 🔄 Updating the Stack

### Update Individual Service

1. In Portainer, go to **Images**
2. Pull the latest image (e.g., `ghcr.io/huggingface/text-embeddings-inference:cpu-1.5`)
3. Go to **Stacks** → **brain-stack**
4. Click **Editor**
5. Update the image tag if needed
6. Click **Update the stack**
7. Check **Re-pull images**
8. Click **Update**

### Update Entire Stack

1. Pull latest `brain-stack.yml` from repository
2. In Portainer: **Stacks** → **brain-stack** → **Editor**
3. Replace content with new version
4. Click **Update the stack**
5. Check **Re-pull images** if images changed
6. Click **Update**

## 🔐 Security Considerations

### Network Isolation

The stack creates an isolated bridge network `brain_net` with subnet `172.31.0.0/16`. Containers communicate internally via static IPs.

### Exposed Ports

These ports are exposed to your LAN:
- `8000` - vLLM API (consider firewall rules for production)
- `6333/6334` - Qdrant (restrict to trusted IPs)
- `8001` - TEI Embeddings (internal use only)
- `8888` - SearXNG (internal use only)
- `3000` - OpenWebUI (main user interface)

**Recommendation**: Use a reverse proxy (nginx, Traefik) with SSL for production.

### API Keys

Currently using placeholder keys (`sk-brain-local`, `sk-local`). For production:
1. Generate secure keys: `openssl rand -hex 32`
2. Update in `brain-stack.yml` under OpenWebUI environment variables
3. Redeploy the stack

## 📊 Resource Monitoring

### GPU Usage

```bash
# Monitor in real-time
watch -n 1 rocm-smi

# Expected VRAM usage:
# vLLM: ~16-18GB (90% of 20GB)
# Other services: CPU only
```

### Container Resources

In Portainer:
1. Go to **Containers**
2. Click container name (e.g., **brain-vllm**)
3. View **Stats** tab for CPU, RAM, Network, and Disk usage

### Disk Usage

```bash
# Check Docker disk usage
docker system df

# Check Brain directories
du -sh /home/brains/*
```

## 📝 Next Steps

After successful deployment:

1. **Configure OpenWebUI**:
   - Create admin account
   - Set up your first workspace
   - Test document upload and RAG

2. **Test RAG Pipeline**:
   - Upload a PDF document
   - Ask questions about the content
   - Verify answers use document context

3. **Monitor Performance**:
   - Check GPU utilization during inference
   - Monitor response times
   - Adjust batch sizes if needed

4. **Integrate with Brawn Node** (if applicable):
   - Update Brawn's 03-ai-stack.yml
   - Point to Brain's IP for LLM services
   - Test cross-node communication

5. **Set Up Backups**:
   - Schedule Qdrant snapshots
   - Backup OpenWebUI data directory
   - Document recovery procedures

## 📚 Additional Resources

- **vLLM Documentation**: https://docs.vllm.ai/
- **Qdrant Documentation**: https://qdrant.tech/documentation/
- **OpenWebUI Documentation**: https://docs.openwebui.com/
- **ROCm Installation**: https://rocm.docs.amd.com/
- **TEI Documentation**: https://huggingface.co/docs/text-embeddings-inference/

## 🆘 Getting Help

If you encounter issues:

1. Check container logs in Portainer
2. Review this troubleshooting section
3. Verify all prerequisites are met
4. Check the main repository issues: https://github.com/Enigmaticjoe/la/issues

---

**Last Updated**: 2026-02-10  
**Stack Version**: 1.0  
**Compatible with**: Portainer CE 2.19+
