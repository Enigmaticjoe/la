# Open WebUI Quick Start Guide

Get Open WebUI running in minutes!

## Prerequisites

- Docker installed and running
- Docker Compose installed
- (Optional) NVIDIA GPU with drivers installed

## Installation Methods

### Method 1: Automated Deployment (Recommended)

#### For Brain PC (192.168.1.9)
```bash
git clone <repository-url>
cd la
chmod +x scripts/automation/deploy-brain.sh
./scripts/automation/deploy-brain.sh
```

#### For unRAID Brawn (192.168.1.222)
```bash
git clone <repository-url>
cd la
chmod +x scripts/automation/deploy-unraid.sh
./scripts/automation/deploy-unraid.sh
```

### Method 2: Interactive Installation
```bash
git clone <repository-url>
cd la
chmod +x scripts/openwebui/install-openwebui.sh
./scripts/openwebui/install-openwebui.sh
```

The installer will:
1. Check prerequisites
2. Detect GPU (if available)
3. Create directory structure
4. Configure environment
5. Start services
6. Pull initial models (optional)

### Method 3: Manual Docker Compose

#### Without GPU
```bash
git clone <repository-url>
cd la
cp .env.example .env
# Edit .env and set WEBUI_SECRET_KEY
docker compose up -d
```

#### With GPU
```bash
git clone <repository-url>
cd la
cp .env.example .env
cp docker-compose-gpu.yml docker-compose.yml
# Edit .env and set WEBUI_SECRET_KEY
docker compose up -d
```

## First Steps

### 1. Access Open WebUI
Open your browser and navigate to:
- http://localhost:3000
- http://192.168.1.9:3000 (Brain PC)
- http://192.168.1.222:3000 (unRAID)

### 2. Create Admin Account
On first visit, create your admin account:
- Email: your@email.com
- Password: (choose a strong password)
- Name: Your Name

### 3. Pull AI Models
```bash
# Pull default model
docker exec ollama ollama pull llama3.2:latest

# Pull embedding model for RAG
docker exec ollama ollama pull nomic-embed-text

# Pull code model (optional)
docker exec ollama ollama pull codellama:latest
```

Or use the management script:
```bash
./scripts/openwebui/manage-models.sh pull llama3.2:latest
./scripts/openwebui/manage-models.sh recommended
```

### 4. Start Chatting!
- Click "New Chat"
- Select a model (e.g., llama3.2:latest)
- Start asking questions

## Common Tasks

### Upload Documents for RAG
1. Navigate to **Workspace → Knowledge**
2. Create a new collection
3. Upload your documents (PDF, DOCX, TXT, MD)
4. Documents will be embedded and searchable

### Create Custom Agents
1. Navigate to **Workspace → Agents**
2. Click **Create Agent**
3. Configure:
   - Name and description
   - Select model
   - Set system prompt
   - Enable tools
4. Save and use in chats

### Install Custom Functions
Functions are already included in `configs/functions/`:
- `web_scraper.py` - Scrape web pages
- `knowledge_search.py` - Search knowledge base

To use:
1. Navigate to **Workspace → Functions**
2. Upload or enable functions
3. Use in chats with agents

## Troubleshooting

### Services Won't Start
```bash
# Check Docker daemon
sudo systemctl status docker

# Check logs
docker logs open-webui
docker logs ollama

# Restart services
docker compose restart
```

### GPU Not Detected
```bash
# Check NVIDIA drivers
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Install NVIDIA Container Toolkit if needed
```

### Can't Access Web Interface
```bash
# Check if services are running
docker ps

# Check port availability
netstat -tulpn | grep 3000

# Check firewall
sudo ufw status
sudo ufw allow 3000/tcp
```

### Out of Memory
```bash
# Use smaller models
docker exec ollama ollama pull llama3.2:latest  # 3B model

# Increase Docker memory limit
# Edit Docker settings → Resources → Memory

# Check memory usage
docker stats
```

## Daily Usage

### Starting Services
```bash
cd ~/open-webui  # or your installation directory
docker compose up -d
```

### Stopping Services
```bash
cd ~/open-webui
docker compose down
```

### Viewing Logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs -f open-webui
docker logs -f ollama
```

### Updating
```bash
./scripts/automation/update-openwebui.sh
```

### Backing Up
```bash
./scripts/automation/backup-openwebui.sh
```

### Health Check
```bash
./scripts/automation/health-check.sh
```

## Next Steps

1. **Explore Features**:
   - Try different AI models
   - Upload documents for RAG
   - Create custom agents
   - Install additional functions

2. **Customize**:
   - Edit `.env` for configuration
   - Add custom functions in `configs/functions/`
   - Create pipelines in `configs/pipelines/`

3. **Integrate**:
   - Enable web search for RAG
   - Connect to external APIs
   - Set up MCP servers

4. **Optimize**:
   - Tune model parameters
   - Configure resource limits
   - Set up monitoring

## Resources

- [Complete Guide](OPEN_WEBUI_COMPLETE_GUIDE.md)
- [Open WebUI Docs](https://docs.openwebui.com)
- [Ollama Models](https://ollama.ai/library)
- [Community Forums](https://github.com/open-webui/open-webui/discussions)

## Support

Need help?
- Run health check: `./scripts/automation/health-check.sh`
- Check logs: `docker logs open-webui`
- See full documentation: `docs/OPEN_WEBUI_COMPLETE_GUIDE.md`
