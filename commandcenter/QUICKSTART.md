# Chimera Brain AI - Quick Start Guide

## 🚀 5-Minute Installation

### Prerequisites
- Ubuntu Server 25.10 installed at 192.168.1.9
- NVIDIA RTX 4070 with drivers installed
- Unraid server accessible at 192.168.1.222
- Root/sudo access

### Installation

```bash
# 1. Navigate to brain directory
cd /home/user/brain

# 2. Run installer
sudo bash install-chimera.sh

# 3. Follow prompts:
#    - Confirm IPs (192.168.1.9 and 192.168.1.222)
#    - Choose "Full Stack" (option 1)
#    - Enable all features (Voice, Image Gen, RAG, Web Scraping)
#    - Let it auto-generate PostgreSQL password
#    - Type "yes" to confirm

# 4. Wait 15-30 minutes while it installs
```

### First Access

```bash
# After installation, open your browser:
http://192.168.1.9:3000  # Open WebUI - Start chatting with AI
```

---

## 📚 Add Knowledge to Your AI

### Method 1: Drop Documents
```bash
# Copy files to Unraid storage
scp myfile.pdf user@192.168.1.9:/mnt/unraid/chimera/documents/

# Trigger processing
curl -X POST http://192.168.1.9:8085/scan
```

### Method 2: Download from YouTube
```bash
# Visit in browser:
http://192.168.1.9:8083

# Paste YouTube URL, click Download
# Videos saved to /mnt/unraid/chimera/media/downloads
```

### Method 3: Web Pages
```bash
# Use the File Browser to upload files:
http://192.168.1.9:8084
```

---

## 🎯 Essential URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Open WebUI** | http://192.168.1.9:3000 | Main AI interface |
| **Dashboard** | http://192.168.1.9:3001 | System overview |
| **RAG API** | http://192.168.1.9:8085 | Document processing |
| **File Browser** | http://192.168.1.9:8084 | Manage files |
| **YouTube DL** | http://192.168.1.9:8083 | Download media |

---

## 🔧 Basic Commands

```bash
# Check status
cd /opt/chimera && docker compose ps

# View logs
docker compose logs -f chimera_brain

# Restart everything
docker compose restart

# Check GPU
nvidia-smi

# List AI models
docker exec chimera_brain ollama list

# Pull new model
docker exec chimera_brain ollama pull llama3.1:70b
```

---

## 💡 What You Can Do

### 1. Chat with AI
- Open http://192.168.1.9:3000
- Start typing questions
- AI uses your local models (llama3.1:8b, dolphin-mistral, etc.)

### 2. Search Your Documents
- Drop PDFs/docs in `/mnt/unraid/chimera/documents`
- Ask questions about them in Open WebUI
- AI will search and cite sources

### 3. Generate Images
- In Open WebUI, type: "Generate an image of..."
- ComfyUI will create it (GPU accelerated)
- Images saved to `/mnt/unraid/chimera/comfyui_output`

### 4. Voice Control (if enabled)
- Use microphone button in Open WebUI
- Speak your question
- AI responds with text-to-speech

### 5. Download Knowledge
- Visit YouTube downloader (8083)
- Paste educational video URL
- Transcript auto-extracted and indexed

---

## 🚨 Quick Troubleshooting

### AI is slow
```bash
# Check GPU is working
docker exec chimera_brain nvidia-smi

# If GPU not detected
sudo systemctl restart docker
docker compose restart chimera_brain
```

### Unraid not accessible
```bash
# Check mount
mount | grep unraid

# Remount
sudo mount -a
```

### Service won't start
```bash
# Check what failed
docker compose ps

# View errors
docker compose logs chimera_<service_name>

# Restart it
docker compose restart chimera_<service_name>
```

---

## 📖 Full Documentation

- **README-INSTALLATION.md** - Complete installation guide
- **CLAUDE.md** - Comprehensive system documentation
- **docker-compose-enhanced.yml** - Service definitions

---

## 🆘 Need Help?

1. Check logs: `docker compose logs -f`
2. Check health: `curl http://192.168.1.9:8085/health`
3. Review installation log: `cat /var/log/chimera_install.log`

---

**That's it! You're now running a private, uncensored AI with 22TB of storage!** 🧠🔥
