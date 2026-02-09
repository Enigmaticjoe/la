# BRAWN - Complete Portainer Stack Package
## 192.168.1.222:8008 | Unraid 7.2.3 | Project Chimera NODE A

---

## Files

| File | Purpose |
|------|---------|
| `01-core-infrastructure.yml` | Homepage, Uptime Kuma, Dozzle, Node-RED, MQTT, Glances, Watchtower, Cloudflared, SearXNG, FlareSolverr, Browserless, hass-unraid |
| `02-media-stack.yml` | Zurg, rclone, Plex, Jellyfin, Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Overseerr, Tautulli, RDT-Client, Gluetun + qBittorrent |
| `03-ai-stack.yml` | Ollama, OpenWebUI, vLLM, TEI Embeddings, Qdrant, AnythingLLM, n8n, Whisper, Piper |
| `04-storage-stack.yml` | Nextcloud + MariaDB + Redis |
| `brawn-stacks.env` | All secrets/API keys (edit before deploying) |
| `brawn-setup.sh` | Create dirs, permissions, default configs, validate |
| `brawn-validate.sh` | Post-deploy health check for all services |
| `brawn-maintenance.sh` | Cleanup orphans, check health, disk report |

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

## Maintenance

```bash
# Weekly cleanup (add to Unraid User Scripts)
bash /mnt/user/appdata/brawn-stacks/brawn-maintenance.sh

# Dry run first
bash /mnt/user/appdata/brawn-stacks/brawn-maintenance.sh --dry-run

# Full validation
bash /mnt/user/appdata/brawn-stacks/brawn-validate.sh
```
