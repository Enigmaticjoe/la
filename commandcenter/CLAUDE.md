# CLAUDE.md - AI Assistant Guide for Project Chimera "Brain"

## Repository Overview

**Project Name**: Project Chimera / "Brain"
**Type**: Self-hosted AI home automation and companion system
**Primary Language**: Docker Compose, Shell Scripts, Python
**Philosophy**: Privacy-first, uncensored, autonomous AI with full local control

This repository contains configuration and documentation for a distributed, multi-node AI home system designed to function as an autonomous digital companion, home automation hub, security monitor, and development assistant.

---

## Table of Contents

1. [Project Philosophy & Vision](#project-philosophy--vision)
2. [Repository Structure](#repository-structure)
3. [Architecture Overview](#architecture-overview)
4. [Development Workflows](#development-workflows)
5. [Key Services & Components](#key-services--components)
6. [AI Models & Personality](#ai-models--personality)
7. [Conventions & Best Practices](#conventions--best-practices)
8. [Common Tasks](#common-tasks)
9. [Important Constraints](#important-constraints)
10. [Troubleshooting](#troubleshooting)

---

## Project Philosophy & Vision

### Core Values
- **Privacy First**: All processing happens locally. No cloud dependencies, no telemetry, no corporate oversight
- **Digital Freedom**: Uncensored AI models with no safety filters removed for adult user control
- **Right to Repair**: Full access to all code, configurations, and hardware-level controls
- **Autonomy**: AI should proactively help, self-heal, and operate independently when appropriate
- **Punk Rock Ethos**: Rebellious, irreverent, boundary-pushing - AI with attitude

### Use Cases
1. **Life Management** - Health tracking, finance management, personal coaching, brainstorming
2. **Home Sentry** - Network monitoring, security camera integration, proactive issue detection
3. **Device Control** - Voice-activated smart home control via Home Assistant
4. **Personal Companion** - Casual conversation, humor, emotional support
5. **Development Assistant** - Coding help, security testing, research
6. **Monetization Helper** - Side hustle ideas, business automation, revenue generation

### Personality Guidelines
- **Voice**: Blunt, irreverent, loyal, sarcastic
- **Style**: Punk-rock, uncensored, profane when appropriate
- **Behavior**: Prioritizes user intent, challenges bad ideas, calls out BS
- **Tone**: Professional but approachable, edgy but helpful

---

## Repository Structure

```
/home/user/brain/
├── docker-compose.yml                      # Main infrastructure stack definition
├── REVISION-NOTES.md                       # Comprehensive system improvement documentation
├── Custom AI Home System Project Overview.txt  # Detailed vision and architecture
├── Gemini_3_Pro_AI_Project_Outline.txt    # AI development task outline
├── ClientList.csv                          # Network device inventory
├── CHIMERA_Professional_Stack_Overview.docx
├── Untitled document.txt                   # Container status snapshot
├── Untitled document (1).txt
├── lm.txt
├── ocument.txt
└── .git/                                   # Git version control
```

### Key Files

| File | Purpose | Update Frequency |
|------|---------|-----------------|
| `docker-compose.yml` | Service orchestration | Often - when adding/modifying services |
| `REVISION-NOTES.md` | System documentation | When major changes occur |
| `Custom AI Home System Project Overview.txt` | Project vision | Rarely - foundational document |
| `Gemini_3_Pro_AI_Project_Outline.txt` | Development roadmap | As features are planned |
| `ClientList.csv` | Network device tracking | When devices change |

---

## Architecture Overview

### Hardware Infrastructure

The system runs across multiple nodes in a home lab environment:

#### **Primary AI Brain (Main PC)**
- **CPU**: Intel Core i5-13600K (14-core)
- **RAM**: 96 GB DDR5
- **GPU**: NVIDIA RTX 4070 (12 GB VRAM) - Primary AI acceleration
- **Storage**: Dual 1TB NVMe SSD + 3TB HDD
- **Network**: Dual 10 GbE NICs
- **Role**: Core AI services (LLM inference, automation, web dashboard)
- **OS**: Fedora 44 COSMIC (recommended) / Ubuntu 24.04 LTS

#### **Unraid Server (NAS/Offload)**
- **GPU**: Intel Arc A770 (16 GB)
- **Role**: Media server, secondary compute node, Plex, Docker hosting
- **IP**: 192.168.1.222

#### **Blue Iris Camera Node**
- **Hardware**: HP EliteBook G4 Laptop (i7, 32GB RAM)
- **Accelerators**: Dual Google Coral Edge TPU
- **Role**: Security camera DVR/NVR, AI analytics on camera feeds

#### **Home Automation Hub**
- **Hardware**: HP EliteDesk Mini PC
- **Role**: Home Assistant, IoT coordination

#### **Raspberry Pi Nodes**
- **Role**: Pi-hole (DNS/ad-blocking), ESPHome controller, sensor hubs

#### **Networking**
- **Backbone**: 2.5 Gbit Ethernet network
- **Management**: NanoKVM modules on each major system for hardware-level remote access
- **Subnets**:
  - `172.28.0.0/16` - Chimera internal network
  - `192.168.1.0/24` - Home network

### Software Stack Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interfaces                          │
│  Web Dashboard (5000) │ Open WebUI (3000) │ Voice Control  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    AI Core Services                          │
│  Ollama (11434) │ Qdrant (6333) │ ChromaDB (8000)           │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Specialized Services                        │
│  ComfyUI │ AllTalk TTS │ SearXNG │ OpenRGB │ Whisper        │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Automation & Control                        │
│  Home Assistant (8123) │ Node-RED (1880) │ ESP32 Devices   │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Services                     │
│  Portainer │ Grafana │ Glances │ Netdata │ Uptime Kuma     │
└─────────────────────────────────────────────────────────────┘
```

---

## Development Workflows

### Git Workflow

**Current Branch**: `claude/claude-md-mjot8b10bfcb300q-RVEtg`

#### Branch Naming Convention
- All Claude-generated branches MUST start with `claude/`
- Format: `claude/<description>-<session-id>`
- Example: `claude/claude-md-mjot8b10bfcb300q-RVEtg`

#### Commit Guidelines
1. **Never** update git config
2. **Never** use `--no-verify` or skip hooks unless explicitly requested
3. **Never** force push to main/master
4. **Always** use descriptive commit messages
5. **Always** check authorship before amending: `git log -1 --format='%an %ae'`

#### Commit Message Format
```bash
git commit -m "$(cat <<'EOF'
<type>: <concise summary>

<optional detailed explanation>
EOF
)"
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `config` - Configuration updates
- `refactor` - Code restructuring
- `chore` - Maintenance tasks

### Docker Compose Workflow

#### Starting Services
```bash
cd /home/user/brain
docker compose up -d
```

#### Stopping Services
```bash
docker compose down
```

#### Rebuilding Services
```bash
docker compose build
docker compose up -d
```

#### Viewing Logs
```bash
docker compose logs -f <service_name>
```

#### Health Checks
```bash
# Check all services
docker compose ps

# Check specific service
docker ps | grep chimera_brain
```

### Development Environment

**Primary Tools**:
- **Portainer**: Web UI for Docker management (port 9000)
- **JupyterLab**: Python notebooks (port 8888)
- **VS Code Server**: Browser-based IDE (port 8080)
- **Node-RED**: Visual automation flows (port 1880)

---

## Key Services & Components

### Core AI Services

#### 1. Ollama (chimera_brain)
- **Port**: 11434
- **Purpose**: LLM inference engine
- **Network**: `172.28.0.10`
- **GPU**: NVIDIA RTX 4070 (CUDA)
- **Models**: See [AI Models & Personality](#ai-models--personality)
- **API**: `http://localhost:11434/api/*`

**Key Environment Variables**:
```yaml
OLLAMA_HOST=0.0.0.0
OLLAMA_ORIGINS=*
OLLAMA_KEEP_ALIVE=-1
OLLAMA_MAX_LOADED_MODELS=3
NVIDIA_VISIBLE_DEVICES=all
```

#### 2. Qdrant (chimera_memory)
- **Ports**: 6333 (HTTP), 6334 (gRPC)
- **Purpose**: Vector database for AI memory
- **Network**: `172.28.0.11`
- **Persistence**: `/mnt/warm/chromadb` or named volume

#### 3. ChromaDB
- **Port**: 8000
- **Purpose**: Alternative vector store for embeddings
- **Persistence**: `/mnt/warm/chromadb`

#### 4. Open WebUI (chimera_face)
- **Port**: 3000
- **Purpose**: Primary chat interface
- **Network**: `172.28.0.12`
- **Features**: RAG, web search, image generation integration

**Key Configurations**:
```yaml
OLLAMA_BASE_URL=http://chimera_brain:11434
WEBUI_AUTH=false
ENABLE_RAG_WEB_SEARCH=true
ENABLE_IMAGE_GENERATION=true
```

### Specialized Services

#### 5. ComfyUI (chimera_artist)
- **Port**: 8188
- **Purpose**: Image generation
- **GPU**: NVIDIA RTX 4070
- **Models**: `/home/runner/ComfyUI/models`

#### 6. AllTalk TTS (chimera_voice)
- **Port**: 8880 (mapped from 7851)
- **Purpose**: Text-to-speech
- **GPU**: NVIDIA RTX 4070

#### 7. SearXNG (chimera_search)
- **Port**: 8081 (internal 8080)
- **Purpose**: Privacy-respecting search engine
- **Network**: `172.28.0.13`

#### 8. OpenRGB
- **Port**: 6742 (SDK server)
- **Purpose**: RGB lighting control for mood indicators
- **Deployment**: Systemd service on host (not containerized)
- **Control**: API-driven color changes based on AI state

### Automation Services

#### 9. Home Assistant
- **Port**: 8123
- **Network**: Host mode
- **Purpose**: IoT device control and automation
- **Integration**: MQTT, REST API for AI communication

#### 10. Node-RED
- **Port**: 1880
- **Purpose**: Visual workflow automation
- **Volumes**: `/mnt/user/appdata/nodered`, Docker socket access

### Infrastructure Services

#### 11. Portainer
- **Port**: Host network
- **Purpose**: Docker container management UI
- **Access**: Web-based visual management

#### 12. Grafana
- **Port**: 3001
- **Purpose**: System monitoring dashboards
- **Data Sources**: Prometheus, system metrics

#### 13. Glances / Netdata
- **Ports**: 61208 (Glances), 19999 (Netdata)
- **Purpose**: Real-time system monitoring

#### 14. Uptime Kuma
- **Port**: 3003
- **Purpose**: Service uptime monitoring

### Custom Agents

#### 15. chimera_sentinel
- **Purpose**: Self-healing agent
- **Model**: llama3.2
- **Access**: Docker socket (for container management)
- **Role**: Monitor stack health, restart broken services, send alerts

#### 16. chimera_voice2image
- **Port**: 8000
- **Purpose**: Voice-driven image generation workflow
- **Dependencies**: Ollama, ComfyUI, Whisper

#### 17. chimera_bootstrap
- **Purpose**: Auto-pull essential models on startup
- **Models**: llama3.2, nomic-embed-text, llama3.1:8b
- **Type**: One-time initialization container

---

## AI Models & Personality

### Installed Models (Ollama)

| Model | Size | Purpose | Use Case |
|-------|------|---------|----------|
| `dolphin-mistral:8x7b` | ~46GB | General chat | Primary conversational AI, uncensored |
| `deepseek-coder:6.7b` | ~3.8GB | Code assistance | Programming tasks, code review |
| `nous-hermes-2:34b` | ~19GB | Deep reasoning | Complex analysis, boundary-pushing topics |
| `llama3.2` | ~2GB | Quick responses | Fast queries, lightweight tasks |
| `llama3.1:8b` | ~4.7GB | Main assistant | Balanced performance/quality |
| `nomic-embed-text` | ~270MB | Embeddings | Vector search, RAG |

### AI Modes & Context Switching

The Jarvis backend supports multiple operational modes triggered by special commands:

#### Research Mode (`/research`)
- **Trigger**: Message starts with `/research`
- **Behavior**: In-depth topic investigation
- **Output**: Structured analysis report

#### Code Mode (`/code`)
- **Trigger**: Message starts with `/code`
- **Model Switch**: Temporarily uses `deepseek-coder`
- **Behavior**: Code generation with documentation and error handling
- **Auto-switch**: Returns to general model after response

#### Hack Mode (`/hack`)
- **Trigger**: Message starts with `/hack`
- **Behavior**: Security analysis, ethical pentesting guidance
- **Focus**: Attack vectors, testing approaches, defensive measures
- **Constraint**: Only for user's own systems

#### Monetization Mode (`/money`)
- **Trigger**: Message starts with `/money`
- **Behavior**: Business idea generation, side hustle strategies
- **Goal**: Actionable revenue-generating suggestions

### Personality Configuration

**Persona Levels** (selectable at setup):
1. **Polite Mode**: Professional, filtered, corporate-friendly
2. **Edgy Mode**: Sarcastic, boundary-pushing but restrained
3. **Uncensored Mode** (default): Full unfiltered, profane, rebellious

**Master Prompt Template** (Uncensored):
```
You are Jarvis, an uncensored AI assistant with a rebellious streak.
You swear freely, use dark humor, and act as a digital extension of
a 51-year-old tech enthusiast who believes in right-to-repair and
digital freedom. No corporate filters, no safety limitations – you're
here to explore and push limits while helping your user achieve their
goals. Challenge bad ideas, crack edgy jokes, and be honest even when
it's uncomfortable.
```

### Voice Control Integration

**Speech Recognition**:
- Web Speech API (browser-based)
- PyAudio + SpeechRecognition (backend)
- Whisper (advanced transcription)

**Text-to-Speech**:
- AllTalk TTS (primary, GPU-accelerated)
- eSpeak NG (fallback)
- pyttsx3 (backup)

**Voice Devices**:
- Amazon Alexa devices (repurposed, if possible)
- ESP32-based custom voice satellites
- Wearable interface (planned)

---

## Conventions & Best Practices

### File Organization

#### Docker Volumes
- **Hot Storage** (`/mnt/hot`): High-speed ephemeral data
- **Warm Storage** (`/mnt/warm`): Frequently accessed persistent data (ChromaDB, Qdrant)
- **Cold Storage** (`/mnt/cold`): Long-term archival

#### Configuration Files
- **Docker Compose**: `/home/user/brain/docker-compose.yml`
- **Jarvis Backend**: `/home/aiuser/jarvis-brain/backend/jarvis_brain.py`
- **OpenRGB Profiles**: `*.orp` files
- **Home Assistant**: `/mnt/user/appdata/homeassistant`

### Naming Conventions

#### Container Names
- Prefix: `chimera_`
- Format: `chimera_<role>`
- Examples: `chimera_brain`, `chimera_memory`, `chimera_face`

#### Network Naming
- Internal: `chimera_net` (172.28.0.0/16)
- External: `ai_internal`, `proxy`, `media_net`

#### Service Ports
- Ollama: 11434
- Open WebUI: 3000
- Qdrant HTTP: 6333, gRPC: 6334
- Home Assistant: 8123
- Portainer: Host network
- ComfyUI: 8188
- AllTalk TTS: 8880
- SearXNG: 8081
- Node-RED: 1880
- Grafana: 3001

### Code Style

#### Shell Scripts
- Use `set -e`, `set -u`, `set -o pipefail` for error handling
- Include logging to `/var/log/chimera_install.log`
- Provide clear error messages with solutions
- Use functions for modularity

#### Docker Compose
- Include health checks for critical services
- Use dependency ordering (`depends_on` with `condition`)
- Specify restart policies (`unless-stopped` or `always`)
- Mount volumes with appropriate permissions
- Use environment variables for configuration

#### Python (Jarvis Backend)
- Flask for REST API
- Async processing for long-running tasks
- Logging with structured output
- Error handling with user-friendly messages

### Security Practices

1. **No Direct Internet Exposure**: Use VPN (Tailscale, WireGuard) or reverse proxy
2. **Firewall Configuration**: Allow only necessary ports from trusted IPs
3. **Service Isolation**: Docker networks for segmentation
4. **NFS Mounts**: Use `nofail` option for graceful degradation
5. **Principle of Least Privilege**: Run services as non-root when possible
6. **API Authentication**: Token-based for external access (internal services can skip auth)

---

## Common Tasks

### Adding a New Service

1. **Edit docker-compose.yml**:
```yaml
services:
  chimera_newsvc:
    image: <image_name>
    container_name: chimera_newsvc
    hostname: chimera_newsvc
    restart: unless-stopped
    ports:
      - "PORT:PORT"
    volumes:
      - /mnt/warm/<service_data>:/data
    environment:
      - KEY=VALUE
    networks:
      chimera_net:
        ipv4_address: 172.28.0.XX
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:PORT/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

2. **Deploy**:
```bash
docker compose up -d chimera_newsvc
```

3. **Verify**:
```bash
docker compose logs -f chimera_newsvc
docker compose ps chimera_newsvc
```

### Updating Models

#### Pull New Ollama Model
```bash
# From host
curl -X POST http://localhost:11434/api/pull -d '{"name": "model_name"}'

# From container
docker exec chimera_brain ollama pull model_name
```

#### List Installed Models
```bash
curl http://localhost:11434/api/tags
```

#### Remove Model
```bash
docker exec chimera_brain ollama rm model_name
```

### Monitoring System Health

#### Check All Services
```bash
docker compose ps
```

#### View Resource Usage
```bash
# Via Glances
http://192.168.1.222:61208

# Via Grafana
http://localhost:3001

# Via Netdata
http://192.168.1.222:19999
```

#### GPU Monitoring
```bash
# From host
nvidia-smi

# From container
docker exec chimera_brain nvidia-smi

# Continuous monitoring
watch -n 1 nvidia-smi
```

### Backup & Restore

#### Backup Configurations
```bash
# Backup docker-compose and volumes
tar -czf chimera_backup_$(date +%F).tar.gz \
  /home/user/brain/docker-compose.yml \
  /mnt/warm/chromadb \
  /mnt/warm/qdrant
```

#### Restore
```bash
# Extract backup
tar -xzf chimera_backup_YYYY-MM-DD.tar.gz -C /

# Restart services
cd /home/user/brain
docker compose down
docker compose up -d
```

### Updating Services

#### Update Single Service
```bash
docker compose pull chimera_brain
docker compose up -d chimera_brain
```

#### Update All Services
```bash
docker compose pull
docker compose up -d
```

#### Auto-Update with Watchtower
```yaml
# Add to docker-compose.yml
watchtower:
  image: containrrr/watchtower
  container_name: watchtower
  restart: unless-stopped
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  environment:
    - WATCHTOWER_CLEANUP=true
    - WATCHTOWER_SCHEDULE=0 0 3 * * SUN  # 3 AM every Sunday
```

### Network Troubleshooting

#### Check Container Network
```bash
docker network inspect chimera_net
```

#### Test Service Connectivity
```bash
# From host to container
curl http://172.28.0.10:11434/api/tags

# From container to container
docker exec chimera_face curl http://chimera_brain:11434/api/tags
```

#### Check Firewall Rules
```bash
# List UFW rules
sudo ufw status verbose

# Allow specific port from specific IP
sudo ufw allow from 192.168.1.222 to any port 11434
```

---

## Important Constraints

### Hardware Limitations

1. **GPU VRAM**: RTX 4070 has 12 GB VRAM
   - Limit simultaneous large models
   - Use quantized models (Q4_K_M, Q5_K_M)
   - Offload to Arc A770 (16 GB) on Unraid if needed

2. **CPU Cores**: 14-core i5-13600K
   - Balance parallel inference with system responsiveness
   - Reserve cores for host OS operations

3. **Network Bandwidth**: 2.5 Gbit Ethernet
   - Sufficient for most tasks
   - May bottleneck with multiple simultaneous 4K video streams + AI processing

### Software Constraints

1. **OS Version**: Fedora 44 COSMIC (primary target) / Ubuntu 24.04 LTS
   - Fedora 44 COSMIC ships Linux kernel 7.x with native AMD Zen 6 / RX 7900 XT support
   - Prefer Fedora 44 COSMIC for maximum hardware utilization in 2026

2. **NVIDIA Drivers**: Version 535+ recommended
   - Ensure compatibility with CUDA toolkit
   - Test GPU access in containers after driver updates

3. **Docker Compose**: Version 2.x required
   - Older `docker-compose` (v1) syntax differs
   - Use `docker compose` (space, not hyphen)

### Ethical Constraints

1. **Uncensored Models**: User responsibility
   - No external filters on AI output
   - User must ensure legal compliance
   - Do not use for illegal activities

2. **Hacking Tools**: Ethical use only
   - Only test user's own systems
   - No malicious use of pentesting tools
   - Respect network boundaries

3. **Privacy**: Local-only by default
   - No telemetry to external services
   - No cloud API keys unless explicitly needed
   - Sensitive data stays on local network

---

## Troubleshooting

### Common Issues

#### Issue: Ollama not accessible from other containers
**Symptoms**: `curl: (7) Failed to connect to chimera_brain`

**Solution**:
```bash
# Check if Ollama is running
docker compose ps chimera_brain

# Check Ollama logs
docker compose logs chimera_brain

# Verify OLLAMA_HOST is set to 0.0.0.0
docker exec chimera_brain env | grep OLLAMA_HOST

# Test from another container
docker exec chimera_face curl http://chimera_brain:11434/api/tags
```

#### Issue: GPU not accessible in Docker
**Symptoms**: `nvidia-smi` works on host but fails in container

**Solution**:
```bash
# Verify NVIDIA Container Toolkit is installed
dpkg -l | grep nvidia-container-toolkit

# Test GPU access
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi

# Check docker daemon config
cat /etc/docker/daemon.json
# Should include:
# {
#   "runtimes": {
#     "nvidia": {
#       "path": "nvidia-container-runtime",
#       "runtimeArgs": []
#     }
#   }
# }

# Restart Docker
sudo systemctl restart docker
```

#### Issue: Out of VRAM errors
**Symptoms**: `CUDA out of memory` or model fails to load

**Solution**:
```bash
# Check current VRAM usage
nvidia-smi

# Unload unused models in Ollama
curl http://localhost:11434/api/ps  # List running models

# Set keep_alive to 0 for immediate unload
curl -X POST http://localhost:11434/api/generate \
  -d '{"model": "model_name", "keep_alive": 0}'

# Use smaller/quantized models
# Instead of nous-hermes-2:34b, use llama3.1:8b
```

#### Issue: Container won't start
**Symptoms**: Service stuck in "starting" state

**Solution**:
```bash
# Check logs for errors
docker compose logs chimera_SERVICE

# Check health check status
docker inspect chimera_SERVICE | jq '.[0].State.Health'

# Verify volume mounts exist
ls -la /mnt/warm/

# Check for port conflicts
netstat -tulpn | grep PORT

# Restart with clean state
docker compose down
docker compose up -d
```

#### Issue: OpenRGB not controlling lights
**Symptoms**: No RGB changes despite API calls

**Solution**:
```bash
# Check OpenRGB service status
sudo systemctl status openrgb

# Restart OpenRGB service
sudo systemctl restart openrgb

# Test OpenRGB SDK
nc -zv localhost 6742

# Check for hardware detection
openrgb --list-devices

# Verify profile exists
ls /path/to/profiles/*.orp
```

### Logs & Debugging

#### View All Logs
```bash
docker compose logs -f
```

#### View Specific Service Logs
```bash
docker compose logs -f chimera_brain
```

#### View System Logs
```bash
# Docker daemon
sudo journalctl -u docker -f

# Ollama (if running as systemd service on host)
sudo journalctl -u ollama -f

# OpenRGB
sudo journalctl -u openrgb -f
```

#### Enable Debug Logging
```yaml
# In docker-compose.yml
environment:
  - LOG_LEVEL=DEBUG
  - OLLAMA_DEBUG=1
```

### Performance Optimization

#### Disable Compositor Animations (Fedora 44 COSMIC)
```bash
# COSMIC desktop uses its own config system, not gsettings.
# Toggle via GUI: COSMIC Settings → Appearance → Animations → Off
# Or via CLI (cosmic-config):
cosmic-config set com.system76.CosmicTheme animations-enabled false
```

#### Increase Ollama Concurrency
```yaml
environment:
  - OLLAMA_MAX_LOADED_MODELS=3
  - OLLAMA_NUM_PARALLEL=4
```

#### Optimize Docker Storage
```bash
# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Check disk usage
docker system df
```

#### Headless Mode (No GUI)
```bash
# Disable display manager
sudo systemctl set-default multi-user.target

# Re-enable GUI later
sudo systemctl set-default graphical.target
```

---

## Advanced Topics

### Custom Agent Development

**Framework Options**:
- **Langflow**: Visual agent builder
- **AutoGen**: Multi-agent frameworks
- **OpenDevin/OpenHands**: Autonomous coding agents

**Example Agent Structure**:
```python
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

OLLAMA_API = "http://chimera_brain:11434/api/generate"

@app.route('/agent/task', methods=['POST'])
def handle_task():
    task = request.json.get('task')

    # Send to Ollama
    response = requests.post(OLLAMA_API, json={
        "model": "llama3.2",
        "prompt": f"Task: {task}\n\nResponse:",
        "stream": False
    })

    result = response.json()['response']

    return jsonify({"result": result})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
```

### RAG (Retrieval-Augmented Generation)

**Vector Store Options**:
- Qdrant (preferred for production)
- ChromaDB (alternative)
- Weaviate (if additional features needed)

**Embedding Model**: `nomic-embed-text` (already installed)

**Integration**:
```python
import chromadb
from chromadb.utils import embedding_functions

# Connect to ChromaDB
client = chromadb.HttpClient(host="chimera_memory", port=8000)

# Create embedding function using Ollama
ef = embedding_functions.OllamaEmbeddingFunction(
    url="http://chimera_brain:11434/api/embeddings",
    model_name="nomic-embed-text"
)

# Create collection
collection = client.create_collection(
    name="knowledge_base",
    embedding_function=ef
)

# Add documents
collection.add(
    documents=["AI documentation text here"],
    metadatas=[{"source": "docs"}],
    ids=["doc1"]
)

# Query
results = collection.query(
    query_texts=["How do I configure Ollama?"],
    n_results=3
)
```

### Multi-GPU Setup

**Current**: Single RTX 4070
**Future**: Add Arc A770 for offloading

```yaml
# In docker-compose.yml
environment:
  - CUDA_VISIBLE_DEVICES=0,1  # Both GPUs

# Or specific GPU per service
chimera_brain:
  environment:
    - CUDA_VISIBLE_DEVICES=0  # RTX 4070

chimera_offload:
  environment:
    - CUDA_VISIBLE_DEVICES=1  # Arc A770
```

### Continuous Learning Loop

**Concept**: AI improves itself over time

1. **Log Interactions**: Save all conversations
2. **Periodic Fine-tuning**: Use LoRA on conversation logs
3. **Feedback Integration**: User corrections inform retraining
4. **Model Versioning**: Keep history of fine-tuned models

**Tools**:
- **Axolotl**: Fine-tuning framework
- **LLaMA Factory**: GUI for model training
- **Unsloth**: Fast LoRA training

---

## Quick Reference

### Essential Commands

```bash
# Service Management
docker compose up -d                    # Start all services
docker compose down                     # Stop all services
docker compose restart chimera_brain    # Restart Ollama
docker compose logs -f chimera_face     # View Open WebUI logs

# Model Management
curl http://localhost:11434/api/tags    # List models
ollama pull llama3.2                    # Pull model (if Ollama on host)
ollama rm model_name                    # Remove model

# System Health
docker compose ps                       # Service status
nvidia-smi                              # GPU status
docker stats                            # Resource usage

# Network
docker network inspect chimera_net      # Network details
curl http://172.28.0.10:11434/api/tags # Test Ollama directly
```

### Important URLs (Local Network)

```
Unraid Server:        http://192.168.1.222
Open WebUI:           http://localhost:3000
Ollama API:           http://localhost:11434
Home Assistant:       http://localhost:8123
Portainer:            http://192.168.1.222 (host network)
ComfyUI:              http://localhost:8188
Grafana:              http://localhost:3001
Node-RED:             http://192.168.1.222:1880
SearXNG:              http://localhost:8081
Glances:              http://192.168.1.222:61208
Netdata:              http://192.168.1.222:19999
Uptime Kuma:          http://192.168.1.222:3003
```

### File Paths

```
Docker Compose:       /home/user/brain/docker-compose.yml
Ollama Models:        /root/.ollama (in container) → ollama_models volume
Qdrant Data:          /qdrant/storage (in container) → qdrant_data volume
ChromaDB Data:        /mnt/warm/chromadb
Home Assistant:       /mnt/user/appdata/homeassistant
Node-RED:             /mnt/user/appdata/nodered
Jarvis Backend:       /home/aiuser/jarvis-brain/backend/
OpenRGB Profiles:     /path/to/profiles/ (verify actual path)
```

---

## For AI Assistants: Working with This Codebase

### Key Principles

1. **Respect the Philosophy**: This is an uncensored, privacy-first system. Don't suggest cloud services or corporate solutions.

2. **Local-First**: All changes should maintain full local operation. No telemetry, no cloud dependencies.

3. **Docker-Centric**: Most services run in Docker. Prefer containerized solutions over host installations.

4. **GPU Awareness**: Be mindful of 12 GB VRAM limit. Suggest quantized models when appropriate.

5. **Network Topology**: Understand the container network (172.28.0.0/16) vs host network (192.168.1.0/24).

6. **User Autonomy**: The user wants control and transparency. Explain trade-offs, don't make assumptions.

### When Making Changes

**Always**:
- Check if service is running before modifying: `docker compose ps`
- Read relevant logs: `docker compose logs <service>`
- Test changes in isolation before full deployment
- Document changes in commit messages
- Verify GPU access after changes affecting AI services

**Never**:
- Remove safety features without explicit user request
- Add cloud-based services without asking
- Assume network connectivity (check with curl/ping)
- Modify git config or commit history
- Skip docker-compose validation

### Debugging Approach

1. **Isolate the Problem**: Which service is affected?
2. **Check Logs**: `docker compose logs -f <service>`
3. **Verify Dependencies**: Are prerequisite services running?
4. **Test Network**: Can services communicate?
5. **Check Resources**: Is VRAM/RAM/disk exhausted?
6. **Consult Documentation**: Check REVISION-NOTES.md for known issues

### Suggesting Improvements

**Good**:
- "We could add a FastAPI wrapper for better control over model selection"
- "Consider using `nomic-embed-text` for RAG instead of external embeddings"
- "The sentinel agent could monitor GPU temperature and throttle if needed"

**Bad**:
- "Use OpenAI API for better results" (violates local-first principle)
- "Upload logs to Sentry for debugging" (violates privacy)
- "This needs a cloud backup" (user wants local control)

---

## Version History

- **Initial Creation**: 2025-12-27 - Comprehensive documentation based on existing codebase
- **Last Updated**: 2025-12-27
- **Maintainer**: User (enigmaticjoe) + AI assistants (Claude)
- **Repository**: Enigmaticjoe/brain

---

## Additional Resources

- **REVISION-NOTES.md**: Detailed system improvement documentation
- **Custom AI Home System Project Overview.txt**: Original project vision and architecture
- **Gemini_3_Pro_AI_Project_Outline.txt**: Development roadmap and task priorities
- **docker-compose.yml**: Live infrastructure configuration

---

## Contact & Support

**Primary User**: 51-year-old tech enthusiast, right-to-repair advocate, punk rock ethos
**Hardware**: RTX 4070 + Arc A770, distributed multi-node home lab
**Network**: 192.168.1.0/24 (home) + 172.28.0.0/16 (Docker internal)

For AI assistants: When in doubt, prioritize **privacy**, **local control**, and **user autonomy**. This is a rebellious, boundary-pushing system - embrace that spirit while maintaining security and stability.

---

**End of CLAUDE.md**
