# Project Chimera - Quick Start Guide

**Get your Digital Renegade command center running in 30 minutes.**

---

## TL;DR

```bash
# 1. Clone repo
git clone https://github.com/Enigmaticjoe/brain.git && cd brain

# 2. Run installer
sudo ./chimera_command_center_wizard.sh

# 3. Access dashboard
open http://localhost:3000
```

---

## Prerequisites Checklist

- [ ] Pop!_OS 22.04+ or Ubuntu 24.04+
- [ ] AMD Ryzen 7700 (or similar) + Intel Arc A770 16GB (or NVIDIA RTX)
- [ ] 32GB+ RAM
- [ ] 100GB+ free disk space
- [ ] Sudo/root access
- [ ] Optional: Unraid server IP for Brawn node
- [ ] Optional: Mullvad account for VPN torrents

---

## Installation Steps

### 1. System Prep (5 min)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install git
sudo apt install -y git

# Clone repository
git clone https://github.com/Enigmaticjoe/brain.git
cd brain
```

### 2. Run Installer (15-20 min)

```bash
# Make executable
chmod +x chimera_command_center_wizard.sh

# Run as root
sudo ./chimera_command_center_wizard.sh
```

**Prompts you'll see**:
- **Username**: Your Linux username (e.g., `joe`)
- **Mullvad ID**: Leave blank if you don't have VPN
- **Models**: Accept default or customize
  - Default: `dolphin-llama3:8b,dark-champion-8b-q4_K_M,hermes3:8b,wizardlm-uncensored:13b-q4_K_M`
- **Uncensored mode**: Type `y` to enable full freedom (recommended)
- **Kali GPT**: Type `y` to enable cyber-assistant preset
- **Brawn IP**: Your Unraid server (e.g., `192.168.1.222`)
- **Edge HA IP**: Home Assistant (e.g., `192.168.1.149`)
- **Edge Blue Iris IP**: Security cameras (e.g., `192.168.1.232`)

### 3. Build Dashboard (5 min, optional)

```bash
cd /opt/chimera/dashboard

# Initialize Vite React project
npm create vite@latest . -- --template react

# Install dependencies
npm install lucide-react

# Copy dashboard component
cp /home/user/brain/ChimeraDashboard.jsx src/App.jsx

# Build
npm run build

# Restart dashboard container
docker restart chimera-dashboard
```

### 4. Access Services

| Service | URL | Credentials |
|---------|-----|-------------|
| **Dashboard** | http://localhost:3000 | None |
| **Open WebUI** | http://localhost:11435 | None (auth disabled) |
| **Grafana** | http://localhost:3001 | admin/renegade2026 |
| **Portainer** | https://localhost:9443 | Set on first login |
| **SearXNG** | http://localhost:8080 | None |
| **qBittorrent** | http://localhost:8112 | admin/adminadmin |
| **Prometheus** | http://localhost:9090 | None |

---

## Post-Install Configuration

### Setup Brawn Node (Unraid)

```bash
# SSH into Unraid
ssh root@192.168.1.222

# Download and run Brawn setup script
wget https://raw.githubusercontent.com/Enigmaticjoe/brain/main/scripts/brawn_setup.sh
bash brawn_setup.sh
```

### Connect Brawn to Portainer

1. Open https://localhost:9443
2. Go to **Environments** → **Add environment**
3. Select **Agent**
4. Enter Brawn IP: `192.168.1.222:9001`
5. Click **Connect**

### Setup Tailscale (Optional)

```bash
# On Brain node
sudo tailscale up

# On Brawn node (Unraid)
# Install Tailscale from Community Apps
# Then run: tailscale up
```

### Run First Network Scan

```bash
python3 /opt/chimera/scripts/vulnbot.py --network 192.168.1.0/24 --save
```

---

## Common Commands

### Check Status

```bash
# All services
docker compose -f /opt/chimera/docker-compose.yml ps

# Specific service logs
docker compose -f /opt/chimera/docker-compose.yml logs -f chimera-ollama
```

### Manage Models

```bash
# List models
docker exec chimera-ollama ollama list

# Pull new model
docker exec chimera-ollama ollama pull model-name

# Remove model
docker exec chimera-ollama ollama rm model-name
```

### Restart Services

```bash
# Single service
docker restart chimera-ollama

# All services
docker compose -f /opt/chimera/docker-compose.yml restart
```

### Update Everything

```bash
cd /opt/chimera
docker compose pull
docker compose up -d
```

---

## Troubleshooting

### Ollama won't start

```bash
# Check GPU
ls -la /dev/dri

# Check logs
docker logs chimera-ollama

# Restart
docker restart chimera-ollama
```

### Dashboard shows blank page

```bash
# Rebuild dashboard
cd /opt/chimera/dashboard
npm run build
docker restart chimera-dashboard
```

### Can't access services from other devices

```bash
# Check firewall
sudo ufw status

# Allow from local network
sudo ufw allow from 192.168.1.0/24 to any port 3000
sudo ufw allow from 192.168.1.0/24 to any port 11435
```

### Out of VRAM

```bash
# Unload models
docker exec chimera-ollama ollama rm model-name

# Or use smaller quantized versions (Q4 instead of Q8)
```

---

## Next Steps

1. **Explore Open WebUI**:
   - Select a model (e.g., dolphin-llama3:8b)
   - Try uncensored queries
   - Upload documents for RAG

2. **Setup Grafana Dashboards**:
   - http://localhost:3001
   - Login: admin/renegade2026
   - Import pre-configured dashboards

3. **Configure Home Assistant Integration** (if you have HA):
   - Settings → Integrations → Add Integration → REST
   - Use Ollama API for voice commands

4. **Secure External Access**:
   - Setup Tailscale on all nodes
   - Never expose ports directly to internet

5. **Customize**:
   - Edit system prompts in Open WebUI
   - Add custom models
   - Extend docker-compose.yml

---

## Getting Help

- **README.md**: Full documentation
- **CLAUDE.md**: AI assistant guide
- **Logs**: `/var/log/chimera_command_center.log`
- **Issues**: https://github.com/Enigmaticjoe/brain/issues

---

## Security Reminder

🚨 **You've enabled uncensored AI models**. They will answer **anything**.

- Use responsibly
- Follow the law
- Don't hack systems you don't own
- Keep your network secure

**You are the guardian of your digital empire.**

---

**Stay sovereign. The Renegade watches.**

🏴 Privacy • Freedom • Autonomy 🏴
