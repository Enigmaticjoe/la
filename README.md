# Open WebUI Complete Setup

Comprehensive setup and optimization for Open WebUI with advanced features on unRAID and Brain PC systems.

## Quick Start

### Brain PC (192.168.1.9)
```bash
git clone <repository-url>
cd la
chmod +x scripts/**/*.sh
./scripts/automation/deploy-brain.sh
```

### unRAID Brawn (192.168.1.222)
```bash
git clone <repository-url>
cd la
chmod +x scripts/**/*.sh
./scripts/automation/deploy-unraid.sh
```

### Manual Installation
```bash
chmod +x scripts/openwebui/install-openwebui.sh
./scripts/openwebui/install-openwebui.sh
```

## Features

- **Complete Docker Setup**: Full stack with Open WebUI, Ollama, ChromaDB, and Pipelines
- **GPU Support**: Automatic NVIDIA GPU detection and configuration
- **Knowledge Base**: RAG (Retrieval Augmented Generation) with ChromaDB
- **Custom Functions**: Web scraping, knowledge search, and more
- **Pipelines**: Text processing and custom workflows
- **Automation**: Backup, update, and health check scripts
- **Multi-System**: Optimized for both Brain PC and unRAID systems

## Documentation

- [Complete Guide](docs/OPEN_WEBUI_COMPLETE_GUIDE.md) - Comprehensive setup and usage guide
- [Quick Start Guide](docs/QUICKSTART.md) - Get started in minutes

## Directory Structure

```
.
├── configs/
│   ├── functions/          # Custom functions
│   └── pipelines/          # Processing pipelines
├── docs/                   # Documentation
├── scripts/
│   ├── openwebui/         # Installation and management
│   ├── automation/        # Automation scripts
│   └── unraid/            # unRAID specific scripts
├── docker-compose.yml     # Standard deployment
└── docker-compose-gpu.yml # GPU-enabled deployment
```

## Management Scripts

### Installation
```bash
./scripts/openwebui/install-openwebui.sh
```

### Deployment
```bash
# Brain PC
./scripts/automation/deploy-brain.sh

# unRAID
./scripts/automation/deploy-unraid.sh
```

### Maintenance
```bash
# Backup
./scripts/automation/backup-openwebui.sh

# Update
./scripts/automation/update-openwebui.sh

# Health Check
./scripts/automation/health-check.sh
```

### Model Management
```bash
# List models
./scripts/openwebui/manage-models.sh list

# Pull a model
./scripts/openwebui/manage-models.sh pull llama3.2:latest

# Show recommendations
./scripts/openwebui/manage-models.sh recommended
```

## Access

After installation:
- **Open WebUI**: http://localhost:3000 or http://192.168.1.9:3000 / http://192.168.1.222:3000
- **Ollama**: http://localhost:11434
- **ChromaDB**: http://localhost:8000
- **Pipelines**: http://localhost:9099

## System Requirements

### Minimum
- CPU: 4+ cores
- RAM: 8GB
- Storage: 100GB
- Docker & Docker Compose

### Recommended
- CPU: 8+ cores
- RAM: 32GB
- GPU: NVIDIA with 8GB+ VRAM
- Storage: 500GB SSD

## Support

For issues:
1. Check logs: `docker logs open-webui`
2. Run health check: `./scripts/automation/health-check.sh`
3. See documentation in `docs/`

## License

MIT