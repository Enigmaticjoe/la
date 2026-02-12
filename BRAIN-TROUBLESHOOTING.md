# Brain Stack - Quick Troubleshooting

## Container Health Status

```bash
# Check all container health
docker ps --filter name=brain- --format "table {{.Names}}\t{{.Status}}"

# Expected output after full startup (5-10 min):
# brain-vllm         Up X minutes (healthy)
# brain-qdrant       Up X minutes (healthy)
# brain-embeddings   Up X minutes (healthy)
# brain-searxng      Up X minutes (healthy)
# brain-openwebui    Up X minutes (healthy)
```

## Startup Time Expectations

| Service | Start Period | What's Happening |
|---------|--------------|------------------|
| **Qdrant** | 20 seconds | Database initialization |
| **SearXNG** | 15 seconds | Config loading |
| **vLLM** | 4 minutes | Model loading to GPU (16-18GB) |
| **Embeddings** | 5 minutes | Model download (~500MB) + loading |
| **OpenWebUI** | 1 minute | Waits for all dependencies |

⚠️ **Total first-time deployment**: 5-10 minutes (includes model downloads)

## Common Issues & Quick Fixes

### 1. "brain-embeddings is unhealthy"

**Status during startup** (first 5 min): `(health: starting)`  
**This is NORMAL** - model is downloading

**Check progress**:
```bash
docker logs brain-embeddings
```

Look for:
- `Downloading model BAAI/bge-base-en-v1.5` ✅ Normal
- `Model loaded` ✅ Ready
- `Error downloading` ❌ Problem

**Fix if error persists**:
```bash
# Ensure directory exists and is writable
sudo mkdir -p /home/brains/embeddings-cache
sudo chown -R $USER:$USER /home/brains/embeddings-cache

# Restart the container
docker restart brain-embeddings

# Wait 5 minutes and check again
docker ps | grep brain-embeddings
```

### 2. "dependency failed to start"

**Cause**: A required service is unhealthy

**Fix**:
```bash
# Check which service is failing
docker ps --filter name=brain- --filter health=unhealthy

# View logs for the unhealthy container
docker logs <container-name>

# Common fixes:
# - Wait longer (check startup times above)
# - Restart the failing container: docker restart <container-name>
# - Check prerequisites (directories, GPU, network)
```

### 3. "brain-vllm is unhealthy"

**Check GPU**:
```bash
rocm-smi  # Should show RX 7900 XT
ls /dev/kfd /dev/dri/render*  # Should exist
```

**Check logs**:
```bash
docker logs brain-vllm | tail -50
```

Look for:
- `Loading model cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ` ✅ Normal
- `Model loaded successfully` ✅ Ready
- `CUDA/ROCm error` ❌ GPU problem
- `Out of memory` ❌ Reduce gpu-memory-utilization

**Fix**:
```bash
# Ensure ROCm is working
rocm-smi

# If GPU issues, check ROCm installation
ls /opt/rocm

# Restart container
docker restart brain-vllm
```

### 4. OpenWebUI can't connect to services

**Check dependencies**:
```bash
# All must be healthy
docker ps --filter name=brain-vllm
docker ps --filter name=brain-qdrant
docker ps --filter name=brain-embeddings
```

**Test connectivity**:
```bash
# From inside OpenWebUI container
docker exec brain-openwebui curl http://172.31.0.10:8000/health  # vLLM
docker exec brain-openwebui curl http://172.31.0.15:6333/healthz # Qdrant
docker exec brain-openwebui curl http://172.31.0.20:80/health    # Embeddings
```

### 5. "Port already allocated"

**Find what's using the port**:
```bash
sudo lsof -i :<port>  # e.g., sudo lsof -i :8000
```

**Options**:
- Kill the conflicting process
- Change the port in brain-stack.yml (edit ports section)

### 6. Missing directories

**Create all required directories**:
```bash
sudo mkdir -p /home/brains/{ai-models,openwebui,qdrant/storage,qdrant/snapshots,embeddings-cache,searxng}
sudo chown -R $USER:$USER /home/brains
chmod -R 755 /home/brains
```

### 7. SearXNG config missing

**Create config**:
```bash
SECRET_KEY=$(openssl rand -hex 32)
cat > /home/brains/searxng/settings.yml <<EOF
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

cat > /home/brains/searxng/limiter.toml <<EOF
[botdetection.ip_limit]
link_token = false
EOF
```

## Service Health Endpoints

Test each service manually:

```bash
BRAIN_IP="192.168.1.9"  # Replace with your IP

# vLLM
curl http://$BRAIN_IP:8000/v1/models

# Qdrant
curl http://$BRAIN_IP:6333/healthz

# Embeddings
curl http://$BRAIN_IP:8001/health

# SearXNG
curl http://$BRAIN_IP:8888/healthz

# OpenWebUI
curl http://$BRAIN_IP:3000/health
```

## Complete Restart Procedure

```bash
# Stop all brain containers
docker stop $(docker ps -q --filter name=brain-)

# Remove containers (data is preserved in volumes)
docker rm $(docker ps -aq --filter name=brain-)

# Remove network
docker network rm brain-stack_brain_net

# Redeploy
docker compose -f brain-stack.yml up -d

# Monitor startup
watch -n 2 "docker ps --filter name=brain- --format 'table {{.Names}}\t{{.Status}}'"
```

## Logs Access

```bash
# View real-time logs
docker logs -f brain-<service>

# Last 100 lines
docker logs --tail 100 brain-<service>

# Follow all brain containers
docker logs -f brain-vllm &
docker logs -f brain-embeddings &
docker logs -f brain-qdrant &
docker logs -f brain-searxng &
docker logs -f brain-openwebui &
```

## Resource Monitoring

```bash
# GPU usage (AMD)
watch -n 1 rocm-smi

# Expected VRAM: ~16-18GB for vLLM

# Container stats
docker stats --filter name=brain-

# Disk usage
du -sh /home/brains/*
docker system df
```

## Getting Help

1. ✅ Check this quick reference
2. ✅ Read full guide: PORTAINER-DEPLOY.md
3. ✅ Check container logs: `docker logs brain-<service>`
4. ✅ Verify prerequisites: Run `bash brain-setup.sh`
5. ✅ Open issue: https://github.com/Enigmaticjoe/la/issues

---

**Remember**: First deployment takes 5-10 minutes due to model downloads.  
**Be patient** and watch the logs! 🚀
