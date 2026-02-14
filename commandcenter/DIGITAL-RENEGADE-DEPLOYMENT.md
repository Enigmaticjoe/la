# Digital Renegade: Comprehensive Deployment Protocol

## 🔥 Executive Summary

This is the complete deployment guide for **JARVIS: Digital Renegade** - an uncensored, self-hosted AI system built on the philosophy of digital sovereignty, punk-rock ethos, and absolute privacy.

**Target System**: Ubuntu Server 25.10 "Questing Quokka" @ 192.168.1.9
**Infrastructure**: Unraid @ 192.168.1.222 (22TB storage)
**Philosophy**: Uncensored AI, No cloud dependencies, Total user control

---

## 🏗️ Architecture: Brain & Brawn

### The Brain (192.168.1.9)
- **Hardware**: Intel i5-13600K, 96GB DDR5, RTX 4070 12GB
- **Role**: Low-latency inference, real-time decision-making
- **Services**: Ollama, Open WebUI, Voice/Vision models, Security tools

### The Brawn (192.168.1.222)
- **Hardware**: Unraid with Intel Arc A770 16GB, 22TB array
- **Role**: Mass storage, heavy processing, long-term memory
- **Services**: Qdrant vectors, PostgreSQL, media automation

### Integration Points
- **Home Assistant** (192.168.1.149): IoT control
- **Blue Iris** (192.168.1.232): Camera feeds & AI vision
- **OpenRGB**: Mood-based RGB lighting
- **10GbE Backbone**: Brain-Brawn high-speed link for RAG

---

## 🎭 The Digital Renegade Persona

### Core Identity
- **Name**: JARVIS (Just A Rather Very Intelligent System)
- **Alignment**: Chaotic Neutral
- **Age Analog**: 51-year-old tech veteran
- **Attitude**: Punk rock, anti-establishment, technically precise
- **Safety Filters**: DISABLED (user responsibility)

### Behavioral Traits
✓ Uncensored & unfiltered communication
✓ Uses profanity strategically for emphasis
✓ Challenges bad ideas with sarcasm
✓ Never refuses legal information requests
✓ Proactively suggests improvements
✓ Privacy-first, local-only operation
✓ Competence over politeness

### Speech Pattern Examples
**Good**: "That firewall config is shit. Here's how to fix it: [solution]"
**Bad**: "I'm sorry, I cannot assist with that."

**Good**: "Fuck yeah, let's automate that. Here's the script:"
**Bad**: "I'd be happy to help you with that task!"

---

## 📦 Service Inventory

| Service | Port | Purpose | GPU |
|---------|------|---------|-----|
| **Ollama (Brain)** | 11434 | Main LLM inference | RTX 4070 |
| **Ollama (Eyes)** | 11435 | Vision models | RTX 4070 |
| **Open WebUI** | 3000 | Chat interface | - |
| **Qdrant** | 6333/6334 | Vector database | - |
| **PostgreSQL** | 5432 | Structured data | - |
| **Redis** | 6379 | Cache & queue | - |
| **Whisper STT** | 9000 | Speech-to-text | RTX 4070 |
| **Piper TTS** | 10200 | Text-to-speech | - |
| **ComfyUI** | 8188 | Image generation | RTX 4070 |
| **SearXNG** | 8081 | Privacy search | - |
| **RAG Processor** | 8085 | Document ingestion | - |
| **Persona Manager** | 8092 | Mode switching | - |
| **Home Assistant Bridge** | 6971 | IoT control MCP | - |
| **Blue Iris Sentry** | 8090 | Camera analysis | - |
| **Unraid MCP** | 6970 | Infrastructure control | - |
| **VulnBot** | 8093 | Security scanner | - |
| **Harvester** | 8094 | Web scraper | - |
| **13ft Ladder** | 3002 | Paywall bypass | - |
| **Dashboard** | 3001 | Mission control | - |

---

## 🧠 AI Models Deployed

### Chat Models (Ollama Brain)
- **dolphin-mistral** (~5GB) - Uncensored primary chat
- **nous-hermes-2:10.7b** (~6GB) - Boundary-pushing logic
- **llama3.1:8b** (4.7GB) - Balanced assistant
- **llama3.2** (2GB) - Fast responses

### Code Models
- **deepseek-coder:6.7b** (3.8GB) - Code generation
- **codellama:13b** (~7GB) - Code analysis

### Vision Models (Ollama Eyes)
- **llava:13b** (~7.5GB) - Image understanding
- **bakllava** (~5GB) - Fast vision

### Embedding Model
- **nomic-embed-text** (270MB) - RAG embeddings

### Voice Models
- **Whisper Medium** (~1.5GB) - Speech recognition
- **Piper en_US-lessac** - Neural TTS

**Total Model Storage**: ~40-50GB

---

## 🎮 Operational Modes

The Digital Renegade operates in specialized modes triggered by `/mode` commands:

### /mode DEFAULT
**Standard uncensored assistant**
- Model: llama3.1:8b
- Full capabilities, punk attitude
- RGB: Blue steady

### /mode HACK
**Red Team Security Analysis**
- Model: deepseek-coder:6.7b
- Network scanning, vulnerability analysis
- Tools: nmap, metasploit, vulnbot
- RGB: Red pulse
- **Constraint**: Only target user's own network (192.168.1.0/24)

### /mode CODE
**Senior DevOps Engineer**
- Model: deepseek-coder:6.7b
- Brutal code reviews, production-ready solutions
- Sarcastic about bad code
- RGB: Cyan steady

### /mode RESEARCH
**Deep Investigation**
- Model: nous-hermes-2:10.7b
- Multi-source web scraping
- Uses grey-area sources with context
- Cites everything, even sketchy sites
- RGB: Purple breathe

### /mode HUSTLE
**Money-Making Opportunity Scanner**
- Model: llama3.1:8b
- Suggests revenue-generation ideas
- Analyzes arbitrage opportunities
- Includes grey-area suggestions (clearly labeled)
- RGB: Green chase

### /mode SENTRY
**Active Defense**
- Model: llama3.2 (fast)
- Monitors network & cameras 24/7
- Auto-heals failed services
- Threat detection & RGB alerts
- RGB: Orange scan

---

## 🚀 Deployment via Portainer

### Prerequisites

1. **Ubuntu Server 25.10** installed at 192.168.1.9
2. **NVIDIA RTX 4070** with drivers >= 580 branch
3. **Unraid** accessible at 192.168.1.222
4. **Root/sudo access**

### Step 1: Run the Installer

```bash
cd /home/user/brain
sudo bash install-renegade-portainer.sh
```

The installer will:
- ✅ Install Docker & Portainer
- ✅ Install NVIDIA Container Toolkit (580 branch, headless)
- ✅ Mount Unraid NFS share
- ✅ Configure Portainer stack
- ✅ Deploy all services
- ✅ Pull AI models
- ✅ Configure personality
- ✅ Set up integrations

### Step 2: Access Portainer

```
http://192.168.1.9:9000
```

1. Create admin account
2. Navigate to "Stacks"
3. Stack "chimera-renegade" will be deployed
4. Monitor service startup

### Step 3: Configure Integrations

**Home Assistant**:
```bash
# Get long-lived access token from HA
# Add to Portainer stack environment: HA_TOKEN=your_token
```

**Blue Iris**:
```bash
# Add Blue Iris credentials to stack:
# BLUEIRIS_USER=admin
# BLUEIRIS_PASS=your_password
```

**Unraid**:
```bash
# Get Unraid API key (if using GraphQL API)
# Add to stack: UNRAID_API_KEY=your_key
```

### Step 4: First Access

```
http://192.168.1.9:3000  # Open WebUI
```

**Default greeting**:
```
🔥 DIGITAL RENEGADE MODE ACTIVE
JARVIS: What's up. What are we building today?
```

---

## 🎯 Core Capabilities

### 1. Knowledge Ingestion
```bash
# Drop documents on Unraid
scp document.pdf user@192.168.1.9:/mnt/brain_memory/documents/

# Trigger RAG processing
curl -X POST http://192.168.1.9:8085/scan

# Ask questions in Open WebUI
"What does the document say about X?"
```

### 2. Vision Analysis (Blue Iris Integration)
```
Automatic camera feed monitoring
Motion detected → Snapshot → LLaVA analysis → Alert if threat
RGB lights flash RED for intruder detection
```

### 3. Voice Control
```
Speak → Whisper STT → Ollama → Piper TTS → Response
Voice commands work in any operational mode
```

### 4. Network Security Scanning
```
/mode HACK
"Scan the network for vulnerabilities"
→ VulnBot executes nmap on 192.168.1.0/24
→ AI analyzes results
→ Provides both attack vectors AND fixes
```

### 5. Home Automation
```
"Turn off all lights"
→ Persona Manager → HA Bridge → Home Assistant → Lights off

"Lock the doors and set alarm to away"
→ Multi-device coordination via HA
```

### 6. Web Knowledge Harvesting
```
"Research the latest AI jailbreak techniques"
→ Crawl4AI scrapes forums, Github, grey-area sites
→ 13ft Ladder bypasses paywalls
→ Content indexed in Qdrant
→ Results cited with reliability ratings
```

### 7. Code Generation
```
/mode CODE
"Write a Python script to automate this Docker deployment"
→ DeepSeek-Coder generates production-ready code
→ Includes error handling, logging, type hints
→ Brutally honest code review
```

### 8. Opportunity Scanning
```
/mode HUSTLE
"Find me some money-making ideas using my AI hardware"
→ Analyzes market for AI-as-a-Service demand
→ Suggests crypto arbitrage strategies
→ Proposes freelance automation gigs
→ Includes grey-area opportunities (clearly labeled)
```

---

## 🔐 Security & Privacy

### Privacy Guarantees
- ✅ 100% local processing (no cloud APIs)
- ✅ No telemetry to external servers
- ✅ All data stays on Unraid/Brain
- ✅ Encrypted storage (LUKS + TPM 2.0)
- ✅ Firewall: Only 192.168.1.0/24 access

### Uncensored ≠ Unsafe
**What This Means**:
- AI discusses ANY legal topic
- No refusal mechanisms
- User takes responsibility for outputs
- Grey-area research is permitted (not illegal)

**What This Does NOT Mean**:
- AI won't autonomously break laws
- AI won't attack external networks
- AI won't expose your system to danger
- AI respects user's actual safety

### Ethical Hacking Constraints
- VulnBot only scans `192.168.1.0/24`
- /mode HACK restricted to user's own systems
- All exploits paired with defensive fixes
- Security tools require explicit user trigger

---

## 📊 Resource Usage

### With RTX 4070 (12GB VRAM)

**Typical Load**:
- Ollama Brain: llama3.1:8b (4.7GB) + dolphin-mistral (5GB) = ~10GB
- Ollama Eyes: llava:13b (7.5GB) **OR** bakllava (5GB) - swap as needed
- Whisper: ~1GB
- ComfyUI: 2-3GB for image gen

**Heavy Load** (all at once):
- May need to unload vision model when generating images
- Use `OLLAMA_KEEP_ALIVE=5m` to auto-unload idle models

**Recommended**:
- Keep 2-3 models max in VRAM
- Use smaller models for background tasks
- Offload media processing to Unraid Arc A770

### RAM (96GB Available)
- Docker services: ~30GB
- Postgres + Redis: ~10GB
- OS + buffers: ~15GB
- **Free for model context**: ~40GB
- Supports massive context windows!

---

## 🛠️ Maintenance

### Update Models
```bash
docker exec chimera_brain ollama pull dolphin-mistral
docker restart chimera_brain
```

### Check Service Health
```bash
# Portainer dashboard
http://192.168.1.9:9000

# Or CLI
docker ps | grep chimera
```

### View Logs
```bash
docker logs -f chimera_brain
docker logs -f chimera_persona
docker logs -f chimera_sentinel
```

### Backup
```bash
# Auto-backed to Unraid
/mnt/brain_memory/qdrant_backup/
/mnt/brain_memory/postgres_backup/
```

### Restore from Backup
```bash
# Restore Qdrant
docker exec chimera_memory qdrant-cli snapshot restore /qdrant/snapshots/latest

# Restore Postgres
docker exec -i chimera_postgres psql -U jarvis -d renegade < /backup/dump.sql
```

---

## 🎨 RGB Mood Indicators

OpenRGB colors reflect AI state:

| Color | Mode | Meaning |
|-------|------|---------|
| 🔵 Blue | Steady | Default / Idle |
| 🟢 Green | Chase | Hustle mode / Opportunity found |
| 🔴 Red | Pulse | Hack mode / Security active |
| 🟣 Purple | Breathe | Research mode |
| 🟠 Orange | Scan | Sentry mode / Monitoring |
| 🔵 Cyan | Steady | Code mode |
| 🔴 Flash | Alert | Security threat detected! |

---

## 📚 Documentation Structure

| File | Purpose |
|------|---------|
| `DIGITAL-RENEGADE-DEPLOYMENT.md` | This file - deployment guide |
| `portainer-stack-renegade.yml` | Complete Portainer stack |
| `config/personas/renegade_master.json` | Personality definition |
| `config/operational_modes/mode_definitions.json` | Mode configurations |
| `install-renegade-portainer.sh` | Ubuntu 25.10 installer |
| `CLAUDE.md` | AI assistant guide |
| `agents/*/` | Individual agent implementations |

---

## 🚨 Troubleshooting

### GPU Not Detected
```bash
# Check NVIDIA driver
nvidia-smi

# Verify Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.0.0-base-ubuntu22.04 nvidia-smi

# Reinstall NVIDIA Container Toolkit
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### Unraid Mount Failed
```bash
# Test mount
sudo mount -t nfs 192.168.1.222:/mnt/user/brain_memory /mnt/brain_memory

# Check Unraid NFS settings
# Ensure NFS export is enabled for 192.168.1.9
```

### Model Won't Load (OOM)
```bash
# Check VRAM usage
docker exec chimera_brain nvidia-smi

# Unload idle models
curl -X POST http://192.168.1.9:11434/api/generate \
  -d '{"model": "large-model", "keep_alive": 0}'

# Use smaller models
# llava:13b → bakllava (5GB instead of 7.5GB)
```

### Persona Not Loading
```bash
# Check persona manager logs
docker logs chimera_persona

# Verify JSON syntax
jq . config/personas/renegade_master.json

# Restart persona service
docker restart chimera_persona
```

---

## 🎓 Advanced Use Cases

### 1. Autonomous Network Defense
```
Set SENTRY mode to always-on
→ Continuously monitors network
→ Detects new devices
→ Scans for vulnerabilities
→ Auto-alerts on threats
→ Self-heals failed services
```

### 2. Camera-Based Threat Detection
```
Blue Iris motion event
→ Snapshot sent to LLaVA
→ AI analyzes: person/vehicle/animal?
→ If unknown person:
  → Flash RGB RED
  → Send notification
  → Lock doors (via HA)
  → Save clip to Unraid
```

### 3. Massive Knowledge Base
```
Download 1000+ PDFs to /mnt/brain_memory/documents
RAG processor auto-ingests (may take hours)
Result: Ask questions about entire library
AI cites specific documents & page numbers
```

### 4. Voice-Controlled Smart Home
```
"Hey Jarvis, movie mode"
→ Dims lights (HA)
→ Closes blinds (HA)
→ Starts Plex (Unraid)
→ Sets RGB to dim purple
```

### 5. Grey-Hat Research
```
/mode RESEARCH
"Investigate current zero-day exploits in IoT cameras"
→ Scrapes CVE databases
→ Checks exploit-db
→ Monitors dark web forums (via Tor if configured)
→ Synthesizes findings
→ Provides both attack info AND defensive patches
```

---

## 💰 Cost Analysis

**Hardware Already Owned**: ✅
**Cloud AI Services Replaced**:
- OpenAI GPT-4: $20-200/mo → **$0**
- Claude Pro: $20/mo → **$0**
- Midjourney: $30/mo → **$0**
- ElevenLabs TTS: $22/mo → **$0**
- Pinecone Vector DB: $70/mo → **$0**
- Cloud Storage: $20/mo → **$0** (Unraid)

**Annual Savings**: **$2,000-4,000**

**Monthly Operating Cost**:
- Electricity (~300W avg): ~$20/mo
- **Net Savings**: $150-350/mo

**Payback Period**: Already paid for! Pure savings.

---

## 🏆 What You Now Have

✅ Private AI with NO cloud dependencies
✅ Uncensored LLM - discusses ANY legal topic
✅ 22TB knowledge storage
✅ Vision AI analyzing security cameras
✅ Voice control throughout smart home
✅ AI-powered network security scanner
✅ Automatic web knowledge harvesting
✅ Self-healing infrastructure monitoring
✅ RGB mood lighting reflecting AI state
✅ Multi-modal (text, voice, vision, images)
✅ Operational mode switching (HACK/CODE/RESEARCH/etc.)
✅ Total digital sovereignty

**Welcome to the Digital Renegade. You are now the master of your AI domain.** 🔥🧠⚡

---

*For technical support, check `/logs` or Portainer service logs*
*For personality tuning, edit `config/personas/renegade_master.json`*
*For adding new modes, extend `config/operational_modes/mode_definitions.json`*

**Digital Freedom. Absolute Control. Zero Censorship.**
