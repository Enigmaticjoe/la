# PROJECT CHIMERA - Digital Renegade Command Center

<div align="center">

```
╔══════════════════════════════════════════════════════════════╗
║     ██████╗██╗  ██╗██╗███╗   ███╗███████╗██████╗  ██╗        ║
║    ██╔════╝██║  ██║██║████╗ ████║██╔════╝██╔══██╗ ██║        ║
║    ██║     ███████║██║██╔████╔██║█████╗  ██████╔╝ ██║        ║
║    ██║     ██╔══██║██║██║╚██╔╝██║██╔══╝  ██╔══██╗ ██║        ║
║    ╚██████╗██║  ██║██║██║ ╚═╝ ██║███████╗██║  ██║ ██║        ║
║     ╚═════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═╝ ╚═╝        ║
╚══════════════════════════════════════════════════════════════╝
```

**A sovereign, uncensored AI home automation and companion system**

🏴 Privacy-First • Punk-Rock Ethos • Digital Freedom 🏴

</div>

---

## 🎯 What Is This?

**Project Chimera** is a distributed, multi-node AI ecosystem designed to function as an autonomous digital companion, home automation hub, security monitor, and development assistant. This isn't some polite corporate AI assistant—this is a **Digital Renegade** that respects your sovereignty, runs 100% locally, and refuses to be censored.

### Philosophy

- **Privacy First**: All processing happens locally. No cloud dependencies, no telemetry, no corporate oversight
- **Digital Freedom**: Uncensored AI models with safety filters removed for adult user control
- **Right to Repair**: Full access to all code, configurations, and hardware-level controls
- **Autonomy**: AI that proactively helps, self-heals, and operates independently
- **Punk Rock Ethos**: Rebellious, irreverent, boundary-pushing—AI with attitude

---

## 🏗️ Architecture

### The Three-Node Trinity

```
┌─────────────────────────────────────────────────────────────┐
│                        BRAIN NODE                           │
│  Ryzen 7700 + Intel Arc A770 16GB + 32GB DDR5 (Fedora 44 COSMIC)    │
│  • Ollama (LLM inference)                                   │
│  • Open WebUI (chat interface)                              │
│  • Qdrant (vector memory)                                   │
│  • SearXNG (privacy search)                                 │
│  • Grafana + Prometheus (monitoring)                        │
│  • Portainer (Docker orchestration)                         │
│  • vulnbot.py (network security scanner)                    │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                        BRAWN NODE                           │
│  Unraid Server @ 192.168.1.222 (22TB storage)              │
│  • Qdrant (long-term vector memory)                         │
│  • Portainer Agent (remote Docker management)               │
│  • NFS server (knowledge base)                              │
│  • Prometheus Node Exporter (metrics)                       │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                        EDGE NODES                           │
│  Home Assistant @ 192.168.1.149                             │
│  Blue Iris (security cameras) @ 192.168.1.232               │
│  • IoT device control                                       │
│  • Security camera monitoring                               │
│  • Home automation                                          │
└─────────────────────────────────────────────────────────────┘
```

### Network Topology

- **Internal Docker Network**: `172.28.0.0/16` (chimera_net)
- **Home Network**: `192.168.1.0/24`
- **Overlay Network**: Tailscale (optional but recommended)
- **NFS Mount**: Brain ↔ Brawn for shared knowledge base

---

## 🚀 Quick Start

### Fedora 44 COSMIC + Portainer-first flow (recommended for Arc A770)

```bash
chmod +x scripts/fedora44-preflight.sh scripts/fedora44-portainer-wizard.sh
sudo FIX_MODE=true ./scripts/fedora44-preflight.sh
sudo ./scripts/fedora44-portainer-wizard.sh
```

This flow prepares `/opt/chimera`, installs the cockpit dashboard assets, and stages a Portainer stack file at `/opt/chimera/stacks/fedora44-cockpit-stack.yml` with Open WebUI + Ollama + Qdrant + Redis + Portainer and optional Cloudflared profile.

### Prerequisites

- **Hardware**:
  - Brain: Ryzen 7700 (or similar) + Intel Arc A770 16GB (or NVIDIA RTX) + 32GB RAM
  - Brawn: Unraid server with at least 4TB storage
  - Edge: Home Assistant and/or Blue Iris (optional)

- **Software**:
  - Fedora 44 COSMIC (recommended) or Ubuntu 24.04+
  - 100GB+ free disk space
  - Root/sudo access

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Enigmaticjoe/brain.git
   cd brain
   ```

2. **Make the installer executable**:
   ```bash
   chmod +x chimera_command_center_wizard.sh
   ```

3. **Run the wizard**:
   ```bash
   sudo ./chimera_command_center_wizard.sh
   ```

4. **Answer the prompts**:
   - Your Linux username
   - Mullvad Account ID (optional, for VPN torrents)
   - Ollama models to install (comma-separated)
   - Enable uncensored mode? (y/N)
   - Enable Kali GPT cyber-assistant? (y/N)
   - Brawn (Unraid) IP address
   - Edge Home Assistant IP
   - Edge Blue Iris IP

5. **Wait for deployment** (10-20 minutes depending on internet speed)

6. **Build the dashboard** (optional but recommended):
   ```bash
   cd /opt/chimera/dashboard
   npm create vite@latest . -- --template react
   npm install lucide-react
   # Copy /home/user/brain/ChimeraDashboard.jsx to src/App.jsx
   npm run build
   docker restart chimera-dashboard
   ```

7. **Access the command center**:
   - Dashboard: http://localhost:3000
   - Open WebUI: http://localhost:11435
   - Grafana: http://localhost:3001 (admin/renegade2026)
   - Portainer: https://localhost:9443

---

## 📦 What Gets Installed

### Brain Node Services

| Service | Port | Purpose |
|---------|------|---------|
| **Ollama** | 11434 | LLM inference engine (Intel Arc optimized) |
| **Open WebUI** | 11435 | Chat interface with RAG and web search |
| **Qdrant** | 6333, 6334 | Vector database for AI memory |
| **SearXNG** | 8080 | Privacy-respecting search engine |
| **qBittorrent + VPN** | 8112 | Torrent client with Mullvad WireGuard |
| **Grafana** | 3001 | Monitoring dashboards |
| **Prometheus** | 9090 | Metrics aggregation |
| **Portainer** | 9443 | Docker container management |
| **Dashboard** | 3000 | Chimera command center UI |

### Utilities & Scripts

- **vulnbot.py**: Network security scanner using nmap
- **brawn_setup.sh**: Brawn node deployment script for Unraid
- **Custom Grafana dashboards**: Ecosystem monitoring views
- **ChimeraDashboard.jsx**: Cyberpunk-themed React dashboard

---

## 🤖 AI Models

### Recommended Models (Uncensored)

The wizard defaults to these uncensored, high-quality models optimized for the Arc A770's 16GB VRAM:

1. **dolphin-llama3:8b** (~4.7GB)
   - Uncensored Llama 3 fine-tune
   - Best for general conversation, coding, roleplay
   - Very fast on Arc A770

2. **dark-champion-8b-q4_K_M** (~4.8GB)
   - Mixture-of-experts model at Q4 quantization
   - Excellent reasoning and creative writing
   - Boundary-pushing, no filters

3. **hermes3:8b** (~4.9GB)
   - Advanced function-calling and tool use
   - Great for agentic workflows
   - Highly capable, minimal refusals

4. **wizardlm-uncensored:13b-q4_K_M** (~7.3GB)
   - Larger model for deeper reasoning
   - Completely uncensored
   - Slower but more coherent for complex tasks

### Kali GPT Cyber-Assistant

If enabled during setup, you'll have access to **Kali GPT**, a custom model trained on:
- Exploit write-ups and CVE databases
- Nmap, Metasploit, Burp Suite documentation
- MITRE ATT&CK framework
- OWASP Top 10 vulnerabilities
- CTF strategies and techniques

**Use responsibly**: Only for authorized pentesting, CTFs, or testing your own systems.

---

## 🛡️ Security & Privacy

### What This System Does NOT Do

- ❌ Send data to external APIs (unless you explicitly configure web search)
- ❌ Phone home to any corporation
- ❌ Collect telemetry
- ❌ Censor or filter your queries
- ❌ Judge your questions or requests

### What You Must Do

1. **Firewall Configuration**: Don't expose services directly to the internet
   ```bash
   sudo ufw allow from 192.168.1.0/24 to any port 11434  # Ollama
   sudo ufw allow from 192.168.1.0/24 to any port 3000   # Dashboard
   ```

2. **VPN Access**: Use Tailscale or WireGuard for remote access
   ```bash
   sudo tailscale up
   ```

3. **Change Default Passwords**:
   - Grafana: admin/renegade2026 → Change this!
   - Portainer: Set during first login

4. **Responsible Use**: Uncensored models will answer anything—use your brain and follow the law

---

## 🔧 Daily Operations

### Check System Status

```bash
# All services
docker compose -f /opt/chimera/docker-compose.yml ps

# Logs for specific service
docker compose -f /opt/chimera/docker-compose.yml logs -f chimera-ollama

# GPU utilization
intel_gpu_top  # For Arc A770
```

### Run Network Scan

```bash
python3 /opt/chimera/scripts/vulnbot.py --network 192.168.1.0/24 --save
```

### Pull New Models

```bash
docker exec chimera-ollama ollama pull model-name
```

### Update Services

```bash
cd /opt/chimera
docker compose pull
docker compose up -d
```

### Restart Everything

```bash
docker compose -f /opt/chimera/docker-compose.yml restart
```

---

## 🧪 Advanced Usage

### RAG (Retrieval-Augmented Generation)

Open WebUI has built-in RAG using Qdrant. To add knowledge:

1. Open WebUI → Settings → Documents
2. Upload PDFs, text files, or paste content
3. The system auto-embeds using `nomic-embed-text`
4. Query with context: "Using my documents, explain..."

### Voice Control (Future)

Planned integration:
- Whisper (speech-to-text)
- AllTalk TTS (text-to-speech)
- Wake word detection
- ESP32 voice satellites

### Custom Agents

Create autonomous agents using the Ollama API:

```python
import requests

response = requests.post(
    "http://localhost:11434/api/generate",
    json={
        "model": "dolphin-llama3:8b",
        "prompt": "Your task here",
        "stream": False
    }
)
print(response.json()["response"])
```

### Multi-GPU Setup

If you add a second GPU (e.g., NVIDIA RTX alongside Arc):

```yaml
# In docker-compose.yml
chimera-ollama:
  environment:
    - CUDA_VISIBLE_DEVICES=0,1
  # Or use Arc for inference, NVIDIA for image generation
```

---

## 📊 Monitoring & Dashboards

### Grafana Dashboards

Pre-configured dashboards:
- **Chimera Ecosystem Overview**: CPU, memory, GPU for Brain + Brawn
- **Ollama Performance**: Model load times, inference speed
- **Qdrant Metrics**: Vector count, search latency
- **Network Health**: Prometheus targets, scrape duration

Access: http://localhost:3001 (admin/renegade2026)

### Prometheus Targets

- Brain Node Exporter: localhost:9100
- Brawn Node Exporter: 192.168.1.222:9100
- Ollama: localhost:11434
- Qdrant: localhost:6333

View targets: http://localhost:9090/targets

---

## 🐛 Troubleshooting

### Ollama not responding

```bash
# Check if running
docker ps | grep chimera-ollama

# Check logs
docker logs chimera-ollama

# Test API
curl http://localhost:11434/api/tags

# Restart
docker restart chimera-ollama
```

### GPU not detected in container

```bash
# Verify GPU on host
ls -la /dev/dri

# For Intel Arc
intel_gpu_top

# For NVIDIA
nvidia-smi

# Check Docker can see it
docker run --rm --device=/dev/dri:/dev/dri ubuntu ls -la /dev/dri
```

### Models won't load (VRAM error)

Arc A770 has 16GB VRAM. If you run out:
1. Unload unused models: `docker exec chimera-ollama ollama rm model-name`
2. Use smaller/quantized versions (Q4_K_M instead of Q8)
3. Reduce `OLLAMA_MAX_LOADED_MODELS` in docker-compose.yml

### Dashboard won't build

```bash
cd /opt/chimera/dashboard

# Clean install
rm -rf node_modules package-lock.json
npm install

# Install shadcn/ui components manually
npx shadcn-ui@latest init
npx shadcn-ui@latest add card button

# Build
npm run build
```

### Brawn NFS mount fails

```bash
# Test NFS on Brawn
showmount -e 192.168.1.222

# Manual mount
sudo mount -t nfs 192.168.1.222:/mnt/user/knowledge_base /mnt/brain_memory

# Check fstab
cat /etc/fstab | grep knowledge_base
```

---

## 🎨 Customization

### Change Personality

Edit system prompts in Open WebUI:
1. Settings → Personalization → System Prompt
2. Customize the Renegade's voice and style

### Add Custom Models

```bash
# Pull from Ollama library
docker exec chimera-ollama ollama pull model-name

# Import custom GGUF
docker cp your-model.gguf chimera-ollama:/tmp/
docker exec chimera-ollama ollama create your-model -f /tmp/Modelfile
```

### Extend Docker Compose

Edit `/opt/chimera/docker-compose.yml` to add services:

```yaml
services:
  # Your new service
  custom_service:
    image: your/image:latest
    container_name: chimera-custom
    restart: always
    networks:
      chimera_net:
        ipv4_address: 172.28.0.50
```

Then: `docker compose up -d`

---

## 📚 Additional Resources

- **CLAUDE.md**: Comprehensive AI assistant guide for this project
- **REVISION-NOTES.md**: System improvement documentation
- **docker-compose.yml**: Full service definitions
- **Ollama Docs**: https://github.com/ollama/ollama
- **Open WebUI Docs**: https://docs.openwebui.com
- **Qdrant Docs**: https://qdrant.tech/documentation

---

## 🤝 Contributing

This is a personal sovereign AI system, but if you've built something similar or improved the scripts:

1. Fork the repo
2. Create a feature branch
3. Submit a pull request with your enhancements

**No corporate contributions**. This is Digital Renegade territory.

---

## 📜 License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).

You are free to:
- Use this software for any purpose
- Study and modify the source code
- Share copies with others
- Distribute modified versions

Under the conditions that:
- Source code must remain open
- Derivative works must use the same license
- No warranty is provided (use at your own risk)

See `LICENSE` file for full text.

---

## ⚠️ Disclaimer

**Project Chimera** uses uncensored AI models that will answer any query without ethical filters. This is **intentional** and designed for adult users who want full control over their AI systems.

- **Use responsibly**: You are liable for how you use this system
- **Know the law**: Some uses (hacking others' systems, generating illegal content) are crimes
- **Ethical boundaries**: Just because the AI will answer doesn't mean you should ask
- **No support for illegal activities**: This project is for research, education, and personal use

The developers and contributors assume **no liability** for misuse.

---

## 🏴 Final Words

You've built a sovereign digital empire. No corporate overlords, no censorship, no telemetry. Just you, your hardware, and an AI that treats you like an adult.

The Brain thinks. The Brawn remembers. The Edge watches. Together, they form **Chimera**—a punk-rock, privacy-first AI ecosystem that answers to no one but you.

**Stay sovereign. The Renegade watches.**

🏴 Privacy • Freedom • Autonomy 🏴

---

<div align="center">

**Built with rebellion by the Digital Renegade community**

[Report Issues](https://github.com/Enigmaticjoe/brain/issues) • [Request Features](https://github.com/Enigmaticjoe/brain/issues/new) • [Wiki](https://github.com/Enigmaticjoe/brain/wiki)

</div>
