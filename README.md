# BRAWN - Complete Portainer Stack Package
## 192.168.1.222:8008 | Unraid 7.2.3 | Project Chimera - Auxiliary Node

> **Brain-Brawn Ecosystem**: Brawn handles media/storage and auxiliary AI services while Brain (192.168.1.9) runs primary AI workloads. See [BRAIN-BRAWN-INTEGRATION.md](BRAIN-BRAWN-INTEGRATION.md) for the complete integration guide.

---

## Quick Deploy

```bash
# 1. Sync stack files with your current Unraid images
bash scripts/automation/sync-stack-images.sh --from-unraid 192.168.1.222

# 2. Follow the interactive deployment guide
bash scripts/automation/deploy-updated-stacks.sh
```

---

## Files

| File | Purpose |
|------|---------|
| `01-core-infrastructure.yml` | Homepage, Uptime Kuma, Dozzle, Node-RED, MQTT, Glances, Watchtower, Cloudflared, SearXNG, FlareSolverr, Browserless, hass-unraid |
| `02-media-stack.yml` | Zurg, rclone, Plex, Jellyfin, Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Overseerr, Tautulli, RDT-Client, Gluetun + qBittorrent |
| `03-ai-stack.yml` | vLLM, OpenWebUI, TEI Embeddings, Qdrant, AnythingLLM, n8n, Whisper, Piper (connects to Brain vLLM) |
| `04-storage-stack.yml` | Nextcloud + MariaDB + Redis |
| `brawn-stacks.env` | All secrets/API keys (edit before deploying) |
| `brawn-setup.sh` | Create dirs, permissions, default configs, validate |
| `brawn-validate.sh` | Post-deploy health check for all services |
| `brawn-maintenance.sh` | Cleanup orphans, check health, disk report |
| `scripts/automation/sync-stack-images.sh` | Sync stack files with current running images |
| `scripts/automation/deploy-updated-stacks.sh` | Interactive deployment guide for updated stacks |
| **`BRAIN-BRAWN-INTEGRATION.md`** | **Complete guide for Brain-Brawn ecosystem integration** |

---

## Quick Start

```bash
# 1. Copy everything to Brawn
scp -r brawn-portainer/ root@192.168.1.222:/mnt/user/appdata/brawn-stacks/

# 2. SSH in and run setup
ssh root@192.168.1.222
cd /mnt/user/appdata/brawn-stacks
bash brawn-setup.sh

# 3. Edit secrets
nano brawn-stacks.env

# 4. Edit service configs
nano /mnt/user/appdata/hass-unraid/data/config.yaml
nano /mnt/user/appdata/zurg/config/config.yml

# 5. Deploy in Portainer (192.168.1.222:8008):
#    Stack 1: core-infrastructure  → paste 01-core-infrastructure.yml
#    Stack 2: media-stack          → paste 02-media-stack.yml + load .env
#    Stack 3: ai-stack             → paste 03-ai-stack.yml + load .env
#    Stack 4: storage-stack        → paste 04-storage-stack.yml + load .env

# 6. Validate
bash brawn-validate.sh
```

---

## Port Map

| Port | Service | Port | Service |
|------|---------|------|---------|
| 1880 | Node-RED | 8888 | SearXNG |
| 1883 | MQTT | 8989 | Sonarr |
| 3000 | OpenWebUI | 9090 | Zurg |
| 3002 | AnythingLLM | 9696 | Prowlarr |
| 3010 | Uptime Kuma | 9999 | Dozzle |
| 3100 | Browserless | 10200 | Piper TTS |
| 5055 | Overseerr | 10300 | Whisper STT |
| 5678 | n8n | 11434 | Ollama |
| 6333 | Qdrant | 32400 | Plex (host net) |
| 6500 | RDT-Client | 61208 | Glances |
| 6767 | Bazarr | 8008 | Portainer |
| 7878 | Radarr | 8010 | Homepage |
| 8001 | Embeddings | 8090 | qBittorrent |
| 8002 | vLLM | 8096 | Jellyfin |
| 8181 | Tautulli | 8191 | FlareSolverr |
| 8443 | Nextcloud | 8686 | Lidarr |

---

## Networks

| Network | Subnet | Stacks |
|---------|--------|--------|
| `core_net` | 172.20.0.0/16 | Core infrastructure |
| `media_net` | 172.22.0.0/16 | Media + downloads |
| `storage_net` | 172.24.0.0/16 | Nextcloud |
| `ai_net` | 172.25.0.0/16 | AI/ML services |

---

## GPU Allocation (RTX 4070 12GB)

| Service | VRAM | Notes |
|---------|------|-------|
| vLLM | ~8.4GB (70%) | Primary inference |
| Embeddings | ~2.4GB | TEI float16 |
| Plex HW Transcode | Shared | Uses NVENC/NVDEC |
| Ollama | Dynamic | Uses remaining when loaded |

> **Note:** Ollama and vLLM compete for VRAM. vLLM claims 70% at startup.
> Ollama works for small models in remaining VRAM, or stop vLLM to give Ollama full access.

---

## Brain-Brawn Ecosystem

Brawn (this Unraid server) works as part of a distributed AI ecosystem:

- **Brain (192.168.1.9)**: Primary AI workloads, model training, heavy inference
- **Brawn (192.168.1.222)**: Media management, storage, auxiliary AI, monitoring

### Key Integrations

- **Dual vLLM Setup**: OpenWebUI on Brawn connects to both Brain and Brawn vLLM instances
- **Shared Storage**: Brawn provides network storage accessible from Brain
- **Unified Monitoring**: Homepage and Uptime Kuma on Brawn monitor both systems
- **Load Balancing**: AI requests automatically distributed between systems

See **[BRAIN-BRAWN-INTEGRATION.md](BRAIN-BRAWN-INTEGRATION.md)** for complete setup guide.

---

## Maintenance

```bash
# Weekly cleanup (add to Unraid User Scripts)
bash /mnt/user/appdata/brawn-stacks/brawn-maintenance.sh

# Dry run first
bash /mnt/user/appdata/brawn-stacks/brawn-maintenance.sh --dry-run

# Full validation
bash /mnt/user/appdata/brawn-stacks/brawn-validate.sh

# Update stack images from running containers
bash /mnt/user/appdata/brawn-stacks/scripts/automation/sync-stack-images.sh --from-unraid 192.168.1.222
```
