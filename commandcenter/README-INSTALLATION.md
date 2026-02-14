# Chimera Brain AI - Installation Guide

## 🧠 Overview

Project Chimera is a comprehensive, self-hosted AI system designed for:
- **Local LLM Inference** with Ollama (RTX 4070 accelerated)
- **Knowledge Ingestion** from documents, web, and media
- **RAG (Retrieval Augmented Generation)** for intelligent document search
- **Image Generation** via ComfyUI
- **Voice Control** with TTS/STT
- **22TB Unraid Storage** integration for mass knowledge storage
- **Self-Healing Monitoring** with AI-powered sentinel agent

---

## 📋 Prerequisites

### Hardware Requirements
- **CPU**: Modern multi-core processor (Intel i5-13600K or equivalent)
- **RAM**: Minimum 32GB, recommended 64GB+ (you have 96GB DDR5 ✓)
- **GPU**: NVIDIA RTX 4070 12GB VRAM (or compatible NVIDIA GPU)
- **Storage**: 50GB+ for system, plus network storage for knowledge base
- **Network**: 1 Gbit+ Ethernet connection to Unraid server

### Software Requirements
- **OS**: Ubuntu Server 25.10 (or Ubuntu 22.04+)
- **Network Access**:
  - Brain node at `192.168.1.9`
  - Unraid server at `192.168.1.222`
- **NFS/CIFS**: Network share access to Unraid

### Network Topology
```
┌─────────────────────┐         ┌─────────────────────┐
│   Brain Node        │         │   Unraid Server     │
│   192.168.1.9       │◄───────►│   192.168.1.222     │
│                     │  NFS    │                     │
│  - RTX 4070 GPU     │         │  - 22TB Storage     │
│  - 96GB RAM         │         │  - Intel Arc A770   │
│  - Docker Stack     │         │  - Existing AI      │
└─────────────────────┘         └─────────────────────┘
```

---

## 🚀 Quick Start Installation

### Step 1: Prepare Ubuntu Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone or download Chimera
cd /tmp
# If you have git clone, otherwise copy files manually
# git clone https://github.com/YOUR_REPO/brain.git
# cd brain

# Or if files are already present:
cd /home/user/brain
```

### Step 2: Run Interactive Installer

```bash
sudo bash install-chimera.sh
```

The installer will prompt you for:
1. **Network Configuration** - Confirm Brain IP (192.168.1.9) and Unraid IP (192.168.1.222)
2. **Installation Mode** - Full, Core, or Minimal
3. **GPU Configuration** - Auto-detect NVIDIA RTX 4070
4. **Features** - Voice, Image Gen, RAG, Web Scraping
5. **Security** - PostgreSQL password (auto-generated if skipped)

### Step 3: Wait for Installation

The installer will:
- ✓ Install Docker & Docker Compose
- ✓ Install NVIDIA Container Toolkit
- ✓ Mount Unraid NFS share
- ✓ Configure all services
- ✓ Pull AI models (llama3.2, llama3.1:8b, dolphin-mistral, deepseek-coder, nomic-embed-text)
- ✓ Start entire stack

**Total time**: 15-30 minutes depending on internet speed

---

## 🎯 Installation Modes

### Full Stack (Recommended)
All services including:
- Ollama LLM engine
- Open WebUI
- Qdrant vector database
- PostgreSQL + Redis
- RAG document processor
- Web scraper (Firecrawl)
- Document manager (Paperless-NGX)
- YouTube downloader (MeTube)
- File browser
- ComfyUI (image generation)
- AllTalk TTS + Whisper STT
- Self-healing sentinel agent
- Watchtower (auto-updates)

**RAM Usage**: ~20-30GB
**Docker Containers**: 15-20

### Core Only
Essential AI services:
- Ollama
- Open WebUI
- Qdrant
- PostgreSQL + Redis
- RAG processor
- SearXNG search

**RAM Usage**: ~10-15GB
**Docker Containers**: 8-10

### Minimal
Just the basics:
- Ollama
- Open WebUI

**RAM Usage**: ~5-8GB
**Docker Containers**: 2

---

## 📁 Directory Structure

After installation:

```
/opt/chimera/                    # Main installation directory
├── docker-compose.yml           # Active compose file
├── config/                      # Service configurations
│   ├── homepage/                # Dashboard config
│   ├── searxng/                 # Search engine config
│   ├── paperless/               # Document manager config
│   ├── filebrowser/             # File browser config
│   └── rag/                     # RAG processor config
├── agents/                      # Custom agents
│   ├── rag_processor/           # Document ingestion agent
│   └── sentinel/                # Self-healing monitor
└── logs/                        # Application logs

/mnt/unraid/chimera/             # Unraid storage mount
├── documents/                   # Drop documents here for RAG
├── knowledge/                   # Processed knowledge base
├── media/
│   ├── downloads/               # YouTube/media downloads
│   └── audio/                   # Audio files
├── comfyui_output/              # Generated images
├── postgres_backup/             # Database backups
├── qdrant/                      # Vector DB backups
└── ollama_models/               # Optional: Store models here
```

---

## 🌐 Access Your Services

After installation completes, access these URLs:

### Primary Interfaces
- **Open WebUI**: http://192.168.1.9:3000 - Main AI chat interface
- **Dashboard**: http://192.168.1.9:3001 - System overview

### Knowledge & Documents
- **RAG Processor API**: http://192.168.1.9:8085 - Document processing
- **Document Manager**: http://192.168.1.9:8082 - Paperless-NGX
- **File Browser**: http://192.168.1.9:8084 - Browse Unraid files
- **Media Downloader**: http://192.168.1.9:8083 - YouTube/web downloads

### Search & Discovery
- **SearXNG**: http://192.168.1.9:8081 - Privacy search engine

### Creative Tools
- **ComfyUI**: http://192.168.1.9:8188 - Image generation
- **AllTalk TTS**: http://192.168.1.9:8880 - Text-to-speech
- **Whisper STT**: http://192.168.1.9:9000 - Speech-to-text

### APIs
- **Ollama**: http://192.168.1.9:11434 - LLM inference API
- **Qdrant**: http://192.168.1.9:6333 - Vector database

---

## 📚 Using the Knowledge Ingestion System

### Step 1: Add Documents

Copy documents to the Unraid share:

```bash
# From your local machine or any system with access
scp mydocument.pdf user@192.168.1.9:/mnt/unraid/chimera/documents/

# Or use the File Browser web interface
# Visit http://192.168.1.9:8084
```

**Supported formats**: PDF, DOCX, DOC, TXT, MD, JSON

### Step 2: Trigger Processing

```bash
# Via API
curl -X POST http://192.168.1.9:8085/scan

# Or wait for automatic scan (runs on startup and periodically)
```

### Step 3: Search Your Knowledge

```bash
# Via API
curl -X POST http://192.168.1.9:8085/search \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the main topic?", "limit": 10}'

# Or use Open WebUI - it automatically searches your knowledge base
```

### Step 4: Download Web Knowledge

**Option A: YouTube/Media via MeTube**
1. Visit http://192.168.1.9:8083
2. Paste YouTube URL
3. Click Download
4. Files saved to `/mnt/unraid/chimera/media/downloads`
5. Transcripts auto-saved and can be ingested

**Option B: Web Pages via Firecrawl**
```bash
# The web scraper is available for programmatic use
# See RAG processor API documentation
```

---

## 🤖 Using AI Models

### Installed Models

The bootstrap process automatically pulls:
- **llama3.2** (2GB) - Fast reasoning
- **llama3.1:8b** (4.7GB) - Main assistant
- **dolphin-mistral** (~5GB) - Uncensored chat
- **deepseek-coder:6.7b** (3.8GB) - Code assistance
- **nomic-embed-text** (270MB) - Embeddings for RAG

### Pull Additional Models

```bash
# List available models
docker exec chimera_brain ollama list

# Pull a new model
docker exec chimera_brain ollama pull llama3.1:70b

# Pull uncensored models (as per your preferences)
docker exec chimera_brain ollama pull nous-hermes-2:34b
```

### Recommended Models for Your Setup (RTX 4070 12GB)

**Fits comfortably**:
- llama3.1:8b
- dolphin-mistral
- deepseek-coder:6.7b
- mistral:7b-instruct
- mixtral:8x7b (quantized)

**Possible but tight**:
- llama3.1:70b (heavily quantized)
- nous-hermes-2:34b (quantized)

**Too large for 12GB**:
- llama3.1:70b (full precision)
- llama3.1:405b

---

## 🔧 Common Operations

### View Service Status
```bash
cd /opt/chimera
docker compose ps
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f chimera_brain
docker compose logs -f chimera_rag_processor
docker compose logs -f chimera_sentinel
```

### Restart Services
```bash
# Single service
docker compose restart chimera_brain

# All services
docker compose restart

# Stop and start (full reset)
docker compose down && docker compose up -d
```

### Check GPU Usage
```bash
# From host
nvidia-smi

# From container
docker exec chimera_brain nvidia-smi

# Continuous monitoring
watch -n 1 nvidia-smi
```

### Backup Vector Database
```bash
# Qdrant auto-backs up to Unraid
ls -lh /mnt/unraid/chimera/qdrant/

# Manual backup
cd /opt/chimera
docker compose exec chimera_memory /bin/sh -c "qdrant snapshot create"
```

---

## 🐛 Troubleshooting

### GPU Not Accessible

**Symptom**: Models run slowly, GPU not detected

**Solution**:
```bash
# Check NVIDIA driver
nvidia-smi

# Reinstall NVIDIA Container Toolkit
sudo apt remove nvidia-container-toolkit
sudo apt install nvidia-container-toolkit
sudo systemctl restart docker

# Test GPU in Docker
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi
```

### Unraid Mount Not Working

**Symptom**: `/mnt/unraid` is empty

**Solution**:
```bash
# Check if Unraid is reachable
ping 192.168.1.222

# Try manual mount
sudo mount -t nfs 192.168.1.222:/mnt/user/chimera /mnt/unraid

# Check mount status
mount | grep unraid

# View mount errors
dmesg | grep -i nfs
```

### Out of Memory Errors

**Symptom**: Services crashing, OOM errors

**Solution**:
```bash
# Check memory usage
free -h

# Check Docker stats
docker stats

# Unload large AI models
curl -X POST http://192.168.1.9:11434/api/generate \
  -d '{"model": "large-model-name", "keep_alive": 0}'

# Restart memory-hungry services
docker compose restart chimera_brain chimera_artist
```

### RAG Not Processing Documents

**Symptom**: Documents in folder but not searchable

**Solution**:
```bash
# Check RAG processor logs
docker compose logs -f chimera_rag_processor

# Trigger manual scan
curl -X POST http://192.168.1.9:8085/scan

# Check processing stats
curl http://192.168.1.9:8085/stats

# Verify Qdrant is running
curl http://192.168.1.9:6333/collections
```

---

## 🔐 Security Considerations

### Network Security
- **Firewall**: Services currently exposed on all interfaces
  - Recommended: Use UFW to restrict access to local network only
  ```bash
  sudo ufw allow from 192.168.1.0/24 to any port 3000
  sudo ufw allow from 192.168.1.0/24 to any port 11434
  sudo ufw enable
  ```

### Authentication
- **Open WebUI**: Set `WEBUI_AUTH=true` in docker-compose.yml to enable login
- **PostgreSQL**: Password set during installation (stored in docker-compose.yml)
- **File Browser**: Default admin/admin - change immediately

### Unraid Access
- **NFS**: Currently using permissive mount - consider restricting by IP
- **Data**: Sensitive documents stored on Unraid should use encryption

---

## 📈 Performance Optimization

### For RTX 4070 12GB

```yaml
# In docker-compose.yml, Ollama service:
environment:
  - OLLAMA_MAX_LOADED_MODELS=2  # Reduce if running multiple large models
  - OLLAMA_NUM_PARALLEL=2       # Parallel requests
  - OLLAMA_KEEP_ALIVE=5m        # Unload after 5min idle
```

### Reduce Desktop Effects
```bash
# If running Ubuntu Desktop
gsettings set org.gnome.desktop.interface enable-animations false
```

### Use Headless Mode
```bash
# Switch to text-only (no GUI)
sudo systemctl set-default multi-user.target
sudo reboot

# Switch back to GUI
sudo systemctl set-default graphical.target
```

---

## 🆘 Getting Help

### Check Logs
```bash
cat /var/log/chimera_install.log        # Installation log
docker compose logs -f                   # Service logs
docker compose logs chimera_sentinel     # Monitoring agent
```

### Service Health
```bash
curl http://192.168.1.9:8085/health  # RAG processor
docker compose ps                     # All services
```

### Community Resources
- CLAUDE.md - Detailed system documentation
- REVISION-NOTES.md - System improvements and known issues

---

## 🚀 Next Steps

After installation:

1. **Visit Open WebUI**: http://192.168.1.9:3000
2. **Start a conversation** with the AI
3. **Drop documents** into `/mnt/unraid/chimera/documents`
4. **Trigger RAG scan**: `curl -X POST http://192.168.1.9:8085/scan`
5. **Ask questions** about your documents in Open WebUI
6. **Download YouTube content** for knowledge base via http://192.168.1.9:8083
7. **Monitor system** via Dashboard http://192.168.1.9:3001

---

## 📖 Documentation

- **CLAUDE.md** - Comprehensive system guide for AI assistants
- **REVISION-NOTES.md** - System improvements documentation
- **docker-compose-enhanced.yml** - Full service definitions with comments

---

**Happy AI-ing! 🧠🔥**

*Project Chimera - Privacy-first, self-hosted, uncensored AI*
