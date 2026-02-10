# Quick Reference Card

## 🚀 Quick Deploy

### Brain PC (192.168.1.9)
```bash
./scripts/automation/deploy-brain.sh
```

### unRAID Brawn (192.168.1.222)
```bash
./scripts/automation/deploy-unraid.sh
```

## 🔗 Access URLs

| Service | Brain PC | unRAID |
|---------|----------|--------|
| Open WebUI | http://192.168.1.9:3000 | http://192.168.1.222:3000 |
| Ollama | http://192.168.1.9:11434 | http://192.168.1.222:11434 |
| ChromaDB | http://192.168.1.9:8000 | http://192.168.1.222:8000 |
| Portainer | - | http://192.168.1.222:9000 |

## 📋 Essential Commands

### Models
```bash
./scripts/openwebui/manage-models.sh list
./scripts/openwebui/manage-models.sh pull llama3.2:latest
./scripts/openwebui/manage-models.sh recommended
```

### Maintenance
```bash
./scripts/automation/backup-openwebui.sh
./scripts/automation/update-openwebui.sh
./scripts/automation/health-check.sh
```

### Services
```bash
docker compose up -d              # Start
docker compose down               # Stop
docker compose restart            # Restart
docker logs -f open-webui         # Logs
```

## 🎯 First Time Setup

1. Deploy using script above
2. Access http://192.168.1.X:3000
3. Create admin account
4. Pull models: `./scripts/openwebui/manage-models.sh pull llama3.2:latest`
5. Start chatting!

## 📚 Documentation

- [README.md](../README.md) - Overview
- [QUICKSTART.md](QUICKSTART.md) - Quick start
- [COMPLETE_GUIDE.md](COMPLETE_GUIDE.md) - Full guide
- [TESTING.md](../TESTING.md) - Test results

## 🔧 Troubleshooting

### Can't connect?
```bash
docker ps                          # Check running
./scripts/automation/health-check.sh  # Health check
docker logs open-webui            # Check logs
```

### GPU not working?
```bash
nvidia-smi                        # Check GPU
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
```

### Out of memory?
```bash
# Use smaller model
./scripts/openwebui/manage-models.sh pull llama3.2:latest
```

## ✅ All Systems Ready!
