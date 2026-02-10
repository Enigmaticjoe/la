# Brain-Brawn Quick Reference Card

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│ BRAIN (192.168.1.9)          BRAWN (192.168.1.222)         │
│                                                              │
│ • Primary AI Compute         • Media Management             │
│ • Model Training             • Network Storage              │
│ • Heavy Inference            • Auxiliary AI Services        │
│ • vLLM Primary               • vLLM Secondary               │
│                              • Monitoring/Automation        │
└─────────────────────────────────────────────────────────────┘
```

## Quick Commands

### Stack Management

```bash
# Sync images from running Unraid containers
bash scripts/automation/sync-stack-images.sh --from-unraid 192.168.1.222

# Interactive deployment guide
bash scripts/automation/deploy-updated-stacks.sh

# Validate all services
bash brawn-validate.sh

# Maintenance and cleanup
bash brawn-maintenance.sh
```

### Access Points

| Service | URL | Purpose |
|---------|-----|---------|
| Portainer | http://192.168.1.222:8008 | Stack management |
| OpenWebUI | http://192.168.1.222:3000 | AI chat interface |
| Homepage | http://192.168.1.222:8010 | Dashboard |
| Uptime Kuma | http://192.168.1.222:3010 | Monitoring |
| Plex | http://192.168.1.222:32400 | Media streaming |
| Jellyfin | http://192.168.1.222:8096 | Media streaming |
| Nextcloud | https://192.168.1.222:8443 | File storage |

### AI Services

| Service | Brain | Brawn | Notes |
|---------|-------|-------|-------|
| vLLM | :8000 | :8002 | OpenAI-compatible API |
| Ollama | :11434 | - | Model management |
| Qdrant | - | :6333 | Vector database |
| Embeddings | - | :8001 | Text embeddings |
| OpenWebUI | - | :3000 | Connects to both vLLM |

### Testing Connectivity

```bash
# From Brawn, test Brain vLLM
curl http://192.168.1.9:8000/health

# From Brain, test Brawn services
curl http://192.168.1.222:6333/healthz  # Qdrant
curl http://192.168.1.222:8001/health   # Embeddings
curl http://192.168.1.222:3000          # OpenWebUI
```

### Docker Commands

```bash
# View logs
docker logs -f <service-name>

# Restart service
docker restart <service-name>

# Check resource usage
docker stats

# List running containers
docker ps

# Check service health
docker ps --filter "health=unhealthy"
```

### Common Services to Check

```bash
# AI Stack
docker logs vllm
docker logs openwebui
docker logs qdrant
docker logs embeddings

# Media Stack
docker logs plex
docker logs sonarr
docker logs radarr

# Core Infrastructure
docker logs homepage
docker logs uptime-kuma
```

## Stack Deployment Order

1. **Core Infrastructure** (`01-core-infrastructure.yml`)
   - Homepage, Uptime Kuma, Monitoring

2. **Storage Stack** (`04-storage-stack.yml`)
   - Nextcloud, MariaDB, Redis

3. **Media Stack** (`02-media-stack.yml`)
   - Plex, Sonarr, Radarr, etc.

4. **AI Stack** (`03-ai-stack.yml`)
   - vLLM, OpenWebUI, Qdrant

## Environment Variables (brawn-stacks.env)

```bash
# Brain Connectivity
BRAIN_IP=192.168.1.9
BRAIN_VLLM_PORT=8000
BRAIN_OLLAMA_PORT=11434

# API Keys
VLLM_API_KEY=sk-brain-primary
BRAWN_VLLM_API_KEY=sk-brawn-local

# Real-Debrid
REAL_DEBRID_API_KEY=your-key

# Plex
PLEX_CLAIM=claim-xxx

# Other service tokens...
```

## GPU Allocation (RTX 4070 12GB on Brawn)

| Service | VRAM | % |
|---------|------|---|
| vLLM | 8.4 GB | 70% |
| TEI Embeddings | 2.4 GB | 20% |
| Plex HW Transcode | Shared | - |
| Headroom | 0.9 GB | 10% |

## Troubleshooting

### OpenWebUI can't connect to Brain

```bash
# Check network connectivity
docker exec openwebui ping 192.168.1.9

# Verify Brain vLLM is running
curl http://192.168.1.9:8000/health

# Check OpenWebUI logs
docker logs openwebui | grep -i error
```

### Service won't start

```bash
# Check container logs
docker logs <service-name>

# Verify ports aren't in use
netstat -tlnp | grep <port>

# Check disk space
df -h

# Validate stack file
docker compose -f <stack-file.yml> config
```

### vLLM out of memory

```bash
# Check GPU usage
nvidia-smi

# Reduce gpu-memory-utilization in stack file
# Change from 0.80 to 0.70

# Or use smaller/quantized model
```

## Key Files

| File | Location |
|------|----------|
| Stack files | `/mnt/user/appdata/brawn-stacks/*.yml` |
| Environment | `/mnt/user/appdata/brawn-stacks/brawn-stacks.env` |
| Scripts | `/mnt/user/appdata/brawn-stacks/scripts/` |
| Backups | `.stack-backups/` |
| Integration guide | `BRAIN-BRAWN-INTEGRATION.md` |

## Support

📖 Full Documentation: `BRAIN-BRAWN-INTEGRATION.md`
📋 README: `README.md`
🔧 Validation: `bash brawn-validate.sh`
🧹 Maintenance: `bash brawn-maintenance.sh`

---

Last Updated: 2026-02-10
Stack Version: vLLM v0.15.1, Qdrant latest, TEI 89-1.8
