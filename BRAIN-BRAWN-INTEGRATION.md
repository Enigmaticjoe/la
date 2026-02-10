# Brain-Brawn Ecosystem Integration Guide

## Architecture Overview

### System Roles

**BRAIN** (192.168.1.9 - Primary AI/Compute Node)
- Primary AI inference workloads
- High-performance GPU compute
- Model training and fine-tuning
- Primary vLLM instance
- Ollama instance for model management

**BRAWN** (192.168.1.222 - Unraid Server)
- Media management and streaming
- Network storage and file services
- Auxiliary AI services
- Secondary vLLM instance (load balancing)
- Monitoring and automation infrastructure

---

## Network Configuration

### Service Connectivity Matrix

| Service | Brain IP | Brawn IP | Port | Protocol |
|---------|----------|----------|------|----------|
| vLLM Primary | 192.168.1.9 | - | 8000 | HTTP |
| vLLM Secondary | - | 192.168.1.222 | 8002 | HTTP |
| OpenWebUI | - | 192.168.1.222 | 3000 | HTTP |
| Qdrant | - | 192.168.1.222 | 6333 | HTTP |
| TEI Embeddings | - | 192.168.1.222 | 8001 | HTTP |
| Plex | - | 192.168.1.222 | 32400 | HTTP |
| Jellyfin | - | 192.168.1.222 | 8096 | HTTP |
| Homepage Dashboard | - | 192.168.1.222 | 8010 | HTTP |
| Portainer | - | 192.168.1.222 | 8008 | HTTP |

### OpenWebUI Multi-Backend Configuration

OpenWebUI on Brawn connects to **both** vLLM instances for load balancing:

```yaml
environment:
  # Connect to both Brain and Brawn vLLM instances
  - OPENAI_API_BASE_URLS=http://192.168.1.9:8000/v1;http://172.25.0.20:8000/v1
  - OPENAI_API_KEYS=sk-brain-primary;sk-brawn-local
```

---

## Deployment Steps

### 1. Update Stack Images

Sync your stack files with current running images:

```bash
# From your Unraid server (Brawn)
cd /mnt/user/appdata/brawn-stacks

# Sync images from running containers
bash scripts/automation/sync-stack-images.sh --from-unraid 192.168.1.222

# OR use the prepared image list
bash scripts/automation/sync-stack-images.sh --from-file current-unraid-images.txt

# Review changes
git diff *.yml

# Commit if satisfied
git add *.yml
git commit -m "Sync stack images with current Unraid deployment"
```

### 2. Configure Brain Connectivity

Update the `.env` file or Portainer environment variables:

```bash
# On Brawn (Unraid)
nano brawn-stacks.env
```

Add/update these variables:

```bash
# Brain connectivity
BRAIN_IP=192.168.1.9
BRAIN_VLLM_PORT=8000
BRAIN_OLLAMA_PORT=11434

# Brawn configuration  
BRAWN_IP=192.168.1.222
BRAWN_ROLE=auxiliary

# API Keys for cross-system access
VLLM_API_KEY=sk-brain-primary
BRAWN_VLLM_API_KEY=sk-brawn-local
```

### 3. Deploy Updated Stacks

Deploy in this order:

```bash
# Via Portainer UI (192.168.1.222:8008):

# Stack 1: Core Infrastructure
Name: core-infrastructure
File: 01-core-infrastructure.yml
Env: brawn-stacks.env

# Stack 2: Storage
Name: storage-stack
File: 04-storage-stack.yml  
Env: brawn-stacks.env

# Stack 3: Media Stack
Name: media-stack
File: 02-media-stack.yml
Env: brawn-stacks.env

# Stack 4: AI Stack
Name: ai-stack
File: 03-ai-stack.yml
Env: brawn-stacks.env
```

### 4. Verify Cross-System Connectivity

```bash
# From Brawn, test Brain connectivity
curl -f http://192.168.1.9:8000/health

# Test OpenWebUI can reach both vLLM instances
docker exec openwebui curl -f http://192.168.1.9:8000/v1/models
docker exec openwebui curl -f http://172.25.0.20:8000/v1/models
```

---

## Resource Allocation

### GPU Distribution

**Brain GPU Resources:**
- Primary vLLM: 80-90% VRAM
- Ollama: Dynamic allocation
- Model training/fine-tuning: On-demand

**Brawn GPU Resources (RTX 4070 12GB):**
- vLLM: ~8.4GB (70%) - Smaller models or quantized versions
- TEI Embeddings: ~2.4GB
- Plex Hardware Transcoding: NVENC/NVDEC
- Headroom: ~0.9GB

### Storage Division

**Brain:**
- Model cache: `/mnt/models` or `/root/.cache/huggingface`
- Fast SSD for model loading
- Training datasets

**Brawn (Unraid):**
- Media library: `/mnt/user/media`
- AI model storage: `/mnt/user/appdata/huggingface/models`
- Document store: `/mnt/user/appdata/anythingllm`
- Shared across network via SMB/NFS

---

## Workflow Integration

### AI Inference Load Balancing

OpenWebUI automatically balances requests between:
1. Brain vLLM (priority for heavy workloads)
2. Brawn vLLM (fallback and light queries)

### Media Access from Brain

Brain can access Brawn media services:

```yaml
# On Brain - mount Brawn media
mount -t nfs 192.168.1.222:/mnt/user/media /mnt/brawn-media

# Or use Plex/Jellyfin clients
# Plex: http://192.168.1.222:32400
# Jellyfin: http://192.168.1.222:8096
```

### Shared Vector Database

Both systems use Brawn's Qdrant instance:

```bash
# From Brain applications
QDRANT_URL=http://192.168.1.222:6333

# From Brawn applications  
QDRANT_URL=http://172.25.0.10:6333  # Internal network
```

---

## Monitoring

### Health Checks

```bash
# Run validation across both systems
bash brawn-validate.sh

# Check cross-system connectivity
bash scripts/automation/health-check.sh --check-brain
```

### Dashboard Access

- **Homepage**: http://192.168.1.222:8010 (shows both systems)
- **Uptime Kuma**: http://192.168.1.222:3010 (monitors both)
- **Portainer**: http://192.168.1.222:8008 (manages Brawn stacks)

---

## Failover Strategy

### Brain Unavailable

When Brain is offline:
1. OpenWebUI automatically uses Brawn vLLM only
2. Smaller models remain available on Brawn
3. Media services unaffected (all on Brawn)

### Brawn Unavailable  

When Brawn is offline:
1. AI inference continues on Brain
2. Media services unavailable
3. Vector database (Qdrant) unavailable - use local fallback

---

## Maintenance

### Weekly Tasks

```bash
# On Brawn
bash brawn-maintenance.sh

# Update images across both systems
docker image prune -f
```

### Model Synchronization

```bash
# Download models on Brain, sync to Brawn for redundancy
rsync -avz /root/.cache/huggingface/ \
  root@192.168.1.222:/mnt/user/appdata/huggingface/models/
```

---

## Quick Commands

```bash
# Update all stacks with current images
bash scripts/automation/sync-stack-images.sh --from-unraid 192.168.1.222

# Deploy updated stacks (via Portainer UI)
# Access: http://192.168.1.222:8008

# Check health of all services
bash brawn-validate.sh

# View logs from any service
docker logs -f <service-name>

# Restart a specific stack
cd /mnt/user/appdata/brawn-stacks
docker compose -f 03-ai-stack.yml restart

# Connect to OpenWebUI
# http://192.168.1.222:3000
```

---

## Troubleshooting

### OpenWebUI Can't Connect to Brain

```bash
# Verify network connectivity
docker exec openwebui ping 192.168.1.9

# Check Brain vLLM is running
curl http://192.168.1.9:8000/health

# Verify firewall allows connection
# On Brain, allow port 8000 from Brawn IP
```

### Slow Model Loading

```bash
# Check if models are on fast storage
# Brain: SSD recommended
# Brawn: Cache array if possible

# Monitor VRAM usage
nvidia-smi -l 1
```

### Storage Full

```bash
# Check disk usage
bash brawn-maintenance.sh

# Clean old images
docker image prune -a -f

# Clear model cache if needed
docker exec vllm rm -rf /root/.cache/huggingface/hub/*
```

---

## Next Steps

1. ✅ Update stack files with current image versions
2. ✅ Configure Brain connectivity in brawn-stacks.env
3. ⬜ Deploy updated stacks via Portainer
4. ⬜ Verify cross-system connectivity  
5. ⬜ Configure monitoring in Homepage/Uptime Kuma
6. ⬜ Test failover scenarios
7. ⬜ Set up automated backups
8. ⬜ Document custom configurations

---

## Support

For issues or questions:
- Check logs: `docker logs <container-name>`
- Run validation: `bash brawn-validate.sh`
- Review this guide: `BRAIN-BRAWN-INTEGRATION.md`
- Check main README: `README.md`
