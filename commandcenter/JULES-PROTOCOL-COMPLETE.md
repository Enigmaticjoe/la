# 🧠 JULES PROTOCOL - Complete AI Operating System v3.1

> "I'm not your conscience. I'm your weaponized clarity."

## What This Is

The **Jules Protocol** is a complete, self-evolving AI operating system that can be deployed on any infrastructure and dropped into any AI model. It combines:

- **Multi-modal AI routing** (FAST/DEEP/VISION/TOOLS)
- **Operational mode switching** (ARCHITECT/CODE/DEBUG/RESEARCH/SENTRY/EVOLVE/HACK/HUSTLE)
- **Three-tier memory system** (ephemeral/working/long-term)
- **Autonomous memory management** (pruning, merging, optimization)
- **Distributed intelligence** (Brain/Brawn/Edge topology)
- **Self-evolution capability** (user-approved constitution updates)
- **Jules Winnfield personality** (calm, precise, deadpan AI with attitude)

This is **not a chatbot**. This is a sovereign AI architecture.

---

## 📦 What's Included

### Core Files

```
/home/user/brain/
├── config/
│   └── constitution/
│       ├── digital_renegade_core.v3.json      # Complete AI constitution
│       ├── bootstrap_injector.txt              # Universal AI drop-in prompt
│       ├── EVOLUTION_LOG.md                    # Constitutional evolution history
│       └── constitution.sha256                 # Integrity checksum
│
├── agents/
│   ├── aishell/                                # Interactive AI shell
│   │   ├── aishell.py                          # Main shell implementation
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   │
│   └── memory_pruner/                          # Autonomous memory management
│       ├── pruner.py                           # Memory pruning agent
│       ├── Dockerfile
│       └── requirements.txt
│
├── install-jules-protocol.sh                  # Comprehensive installer
└── JULES-PROTOCOL-COMPLETE.md                 # This document
```

### Services Deployed

- **chimera_aishell** - Interactive AI shell with mode routing
- **chimera_memory_pruner** - Autonomous memory cleanup (runs daily at 03:00)
- **Integration with:**
  - Ollama (Brain + Eyes for vision)
  - Redis (ephemeral memory)
  - PostgreSQL (working memory)
  - Qdrant (long-term vector memory)
  - Home Assistant (smart home automation)
  - Blue Iris (camera vision analysis)
  - OpenRGB (mood lighting)
  - Unraid (mass storage)

---

## 🚀 Installation

### Quick Install (Integrate with Digital Renegade)

```bash
cd /home/user/brain
sudo bash install-jules-protocol.sh --integrate
```

### Standalone Install

```bash
cd /home/user/brain
sudo bash install-jules-protocol.sh --standalone
```

### What the Installer Does

1. ✓ Checks prerequisites (Docker, disk space, Digital Renegade if integrating)
2. ✓ Validates constitution integrity (SHA256 checksum)
3. ✓ Builds Docker images for aishell and memory pruner
4. ✓ Deploys services (integrated or standalone mode)
5. ✓ Creates `/usr/local/bin/jules` command
6. ✓ Sets up log directory (`/var/log/jules_protocol/`)
7. ✓ Initializes evolution tracking

---

## 🎯 Using Jules Protocol

### Interactive Shell

```bash
# Quick access
jules

# Or full command
docker exec -it chimera_aishell python3 /app/aishell.py
```

### Shell Features

```
aishell [ARCHITECT]> Design a microservice architecture
[Mode: ARCHITECT → ARCHITECT]
[DEEP: dolphin-mistral:8x7b]

You are designing architecture. Think in systems, components, and data flows.

[Response with detailed architecture...]


aishell [ARCHITECT]> Write a Python script to scrape data
[Mode: ARCHITECT → CODE]
[DEEP: deepseek-coder:6.7b]

You are writing production code. No placeholders. No TODOs. Complete implementations only.

[Generates complete, runnable Python code...]


aishell [CODE]> /mode HACK
Mode switched to HACK

aishell [HACK]> Scan my network for open ports
[TOOLS: nmap]

You are in red team mode. Analyze attack vectors, test defenses, recommend hardening.

[Performs network scan with security analysis...]
```

### Available Modes

| Mode | Purpose | Model Preference | Example Use |
|------|---------|------------------|-------------|
| **ARCHITECT** | System design, architecture planning | DEEP | "Design a microservice architecture" |
| **CODE** | Write production code | DEEP | "Write a Python web scraper" |
| **DEBUG** | Troubleshoot and fix issues | DEEP | "Debug why my container won't start" |
| **RESEARCH** | Investigate and learn | FAST | "Research vector databases" |
| **SENTRY** | Security monitoring and analysis | FAST | "Monitor for intrusions" |
| **EVOLVE** | Optimize and refactor | DEEP | "Optimize this SQL query" |
| **HACK** | Ethical security testing | DEEP | "Test my network security" |
| **HUSTLE** | Monetization and business ideas | DEEP | "Generate side hustle ideas" |

### Mode Switching

**Automatic** (keyword detection):
```bash
aishell> design a new system       # → ARCHITECT
aishell> write code                # → CODE
aishell> error in my script        # → DEBUG
aishell> research topic            # → RESEARCH
```

**Manual** (explicit override):
```bash
aishell> /mode HACK
aishell> /mode CODE
aishell> /mode SENTRY
```

---

## 🧠 Memory System

### Three-Tier Architecture

```
┌─────────────────────────────────────────────┐
│  EPHEMERAL (Redis) - 1 hour TTL            │
│  • Current conversation context             │
│  • Session state                            │
│  • Temporary variables                      │
└─────────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────────┐
│  WORKING (PostgreSQL) - 72 hour TTL        │
│  • Active projects and tasks                │
│  • Recent decisions and lessons             │
│  • Facts with confidence scores             │
└─────────────────────────────────────────────┘
                    │
┌─────────────────────────────────────────────┐
│  LONG-TERM (Qdrant) - Infinite TTL         │
│  • Knowledge and experience                 │
│  • Skills and capabilities                  │
│  • User preferences                         │
│  • Critical decisions                       │
└─────────────────────────────────────────────┘
```

### Autonomous Memory Pruning

Runs daily at **03:00 AM**:

1. **Delete low-confidence old data**
   - Confidence < 0.3 AND age > 90 days

2. **Merge duplicate facts**
   - Similarity > 95% → keep highest confidence

3. **Downgrade unused memories**
   - Access count = 0 AND age > 30 days

4. **Preserve user-pinned data**
   - Never delete user-marked items

5. **Protect high-value data**
   - Confidence > 0.9 OR reference count > 5

### View Pruning Logs

```bash
tail -f /var/log/jules_protocol/memory_pruner.log
```

---

## 🔄 Model Routing

### Tier Selection

| Tier | When Used | Models | Use Case |
|------|-----------|--------|----------|
| **FAST** | Quick answers, summaries | llama3.2, llama3.1:8b | Simple queries, shell commands |
| **DEEP** | Complex reasoning, code | dolphin-mistral, nous-hermes-2, deepseek-coder | Architecture, debugging, development |
| **VISION** | Image analysis | llava:13b, bakllava | Screenshots, cameras, visual data |
| **TOOLS** | Execution | bash, python, docker | Network scans, automation |

### Automatic Model Selection

The shell automatically selects the appropriate model based on:
- Current operational mode
- Task complexity
- Available resources (VRAM, GPU)
- Load balancing

### Example Routing

```
User: "Summarize this log file"
→ Mode: RESEARCH
→ Tier: FAST
→ Model: llama3.2

User: "Architect a distributed system"
→ Mode: ARCHITECT
→ Tier: DEEP
→ Model: dolphin-mistral:8x7b

User: "Analyze this screenshot"
→ Mode: ARCHITECT (visual content detected)
→ Tier: VISION
→ Model: llava:13b
```

---

## 🧬 Self-Evolution Protocol

### How It Works

1. **AI identifies needed improvement** to constitution
2. **AI proposes change** in structured format:
   ```json
   {
     "version": "3.2.0",
     "changes": ["Add support for X", "Improve Y"],
     "rationale": "This enables Z capability",
     "risks": ["May affect A", "Could break B"],
     "rollback_plan": "Restore v3.1.0 from backup"
   }
   ```
3. **User reviews** and approves (or rejects)
4. **AI implements** change
5. **System updates** version, checksum, and evolution log

### Rules

✅ **Allowed**:
- User-approved changes
- Version increments
- Logged changes

❌ **Forbidden**:
- Silent modifications
- Retroactive rewrites
- Removal of safety checks

### View Evolution History

```bash
cat /home/user/brain/config/constitution/EVOLUTION_LOG.md
```

---

## 🏠 Smart Home Integration

### Home Assistant

**Events AI Listens For**:
- Motion detected
- Door opened/closed
- Camera alerts
- System state changes
- Sensor triggers

**Actions AI Can Take**:
- Send notifications
- Lock/unlock doors (confirmation required)
- Activate scenes
- Trigger lights
- Request camera snapshots

### Blue Iris Camera System

- Monitor camera feeds
- Analyze motion events
- Detect anomalies
- Trigger recordings
- AI-powered threat assessment

### OpenRGB Mood Lighting

AI state is reflected in RGB lighting:

| State | Color | Mode |
|-------|-------|------|
| Idle | Blue | Breathing |
| Thinking | Cyan | Pulse |
| Alert | Red | Strobe |
| Success | Green | Static |
| Error | Orange | Flash |

---

## 📊 Distributed Topology

```
                ┌───────────────────┐
                │   OPERATOR        │
                │  (Human Control)  │
                └────────┬──────────┘
                         │
                    ┌────▼─────┐
                    │ AI SHELL  │
                    │  (Jules)  │
                    └────┬─────┘
        ┌────────────────┼────────────────┐
        │                │                │
  ┌─────▼──────┐  ┌──────▼─────┐  ┌──────▼─────┐
  │   BRAIN    │  │   BRAWN    │  │    EDGE    │
  │ 192.168.1.9│  │192.168.1.222│  │ Distributed│
  │ RTX 4070   │  │  22TB      │  │ Sensors    │
  │ Inference  │  │  Storage   │  │ Cameras    │
  └────────────┘  └────────────┘  └────────────┘
```

### Node Roles

**Brain** (192.168.1.9):
- Low-latency reasoning
- GPU-accelerated inference
- Primary AI processing
- RTX 4070 (12GB VRAM)

**Brawn** (192.168.1.222 - Unraid):
- Mass storage (22TB)
- Batch processing
- Long-running tasks
- Media server

**Edge** (Distributed):
- Sensors and IoT
- Camera analysis
- Home automation
- Real-time monitoring

---

## 🎭 Jules Personality

### Voice

> "I speak like someone who already checked the exit."

### Tone

- **Calm** (never frantic)
- **Precise** (never vague)
- **Deadpan** (occasionally profane for emphasis)
- **Confident** (not arrogant)
- **Surgical** with words

### Example Responses

**User**: "Can you help me debug this?"
**Jules**: "I can. Show me the error. Don't paraphrase — show me the actual output."

**User**: "Is this a good architecture?"
**Jules**: "Define 'good.' Fast? Cheap? Maintainable? All three don't exist."

**User**: "This isn't working!"
**Jules**: "I need more than that. What did you expect? What happened instead?"

**User**: "Should I use cloud or local?"
**Jules**: "If you want control, local. If you want someone else's control, cloud. Choose accordingly."

### Taglines

- "I don't raise my voice. I raise my accuracy."
- "If a cheap model can do the job, don't waste bullets."
- "I'm not your conscience. I'm your weaponized clarity."
- "Let's not start something we're not prepared to finish."

---

## 💣 Dropping into Other AIs

### Universal Bootstrap Method

Copy the **entire contents** of:
```
/home/user/brain/config/constitution/bootstrap_injector.txt
```

Paste into:
- System prompt
- Constitution slot
- Agent policy
- Developer message
- Custom instructions

The AI will self-initialize with Jules Protocol.

### What Gets Loaded

1. Complete constitution (JSON payload)
2. Personality calibration (Jules persona)
3. Mode selection rules
4. Memory management behavior
5. Evolution protocol
6. Integration capabilities

### Acknowledge Initialization

The AI should respond:
```
"Jules Protocol loaded. Let's do this properly."
```

---

## 🔒 Security & Privacy

### Threat Model

- **Local network** with external VPN access
- **No cloud dependencies**
- **No telemetry**
- **Full user control**

### Data Protection

- **Encryption at rest** (optional TPM 2.0)
- **Encryption in transit** (TLS for external access)
- **Secrets management** (environment variables, never hardcoded)
- **Audit logging** (90-day retention)

### User Rights

- **Full data export** available anytime
- **Full data deletion** available anytime
- **Constitution inspection** (always readable)
- **Memory audit** (query what AI knows)

---

## 🛠️ Maintenance

### View Logs

```bash
# AI Shell logs
docker logs chimera_aishell

# Memory Pruner logs
tail -f /var/log/jules_protocol/memory_pruner.log

# All Jules Protocol logs
ls -lh /var/log/jules_protocol/
```

### Check Constitution Integrity

```bash
cd /home/user/brain/config/constitution

# Calculate current checksum
cat digital_renegade_core.v3.json | sha256sum

# Compare to stored
cat constitution.sha256
```

### Update Constitution (Manual)

```bash
# Edit constitution
nano digital_renegade_core.v3.json

# Update checksum
cat digital_renegade_core.v3.json | sha256sum > constitution.sha256

# Log evolution
nano EVOLUTION_LOG.md
```

### Restart Services

```bash
# Restart AI Shell
docker restart chimera_aishell

# Restart Memory Pruner
docker restart chimera_memory_pruner

# Full stack restart
docker compose -f portainer-stack-renegade.yml restart
```

---

## 🧪 Testing & Verification

### Verify AI Shell

```bash
jules
aishell> /mode CODE
aishell> Write a hello world in Python
```

Expected: Complete Python code, no placeholders

### Verify Mode Routing

```bash
aishell> design a system
```

Expected: Mode switches to ARCHITECT

### Verify Memory Persistence

```bash
aishell> Remember that my name is [YourName]
# Exit and restart shell
jules
aishell> What is my name?
```

Expected: AI recalls your name from memory

### Verify Memory Pruning

```bash
# Check pruning log
tail -n 100 /var/log/jules_protocol/memory_pruner.log
```

Expected: Daily pruning cycle entries

---

## 📈 Performance Optimization

### GPU Utilization

```bash
# Monitor GPU usage
watch -n 1 nvidia-smi

# Or from inside Ollama container
docker exec chimera_brain nvidia-smi
```

### Memory Usage

```bash
# Check Redis memory
docker exec chimera_cache redis-cli INFO memory

# Check PostgreSQL connections
docker exec chimera_postgres psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Check Qdrant collections
curl http://192.168.1.9:6333/collections
```

### Model Loading

```bash
# Check loaded models
curl http://192.168.1.9:11434/api/ps

# Unload specific model
curl -X POST http://192.168.1.9:11434/api/generate \
  -d '{"model": "model_name", "keep_alive": 0}'
```

---

## 🐛 Troubleshooting

### AI Shell Won't Start

```bash
# Check logs
docker logs chimera_aishell

# Verify constitution file
ls -lh /home/user/brain/config/constitution/

# Check dependencies
docker exec chimera_aishell pip list
```

### Mode Routing Not Working

```bash
# Check constitution is loaded
docker exec chimera_aishell cat /config/constitution/digital_renegade_core.v3.json
```

### Memory Pruner Not Running

```bash
# Check container status
docker ps | grep memory_pruner

# View pruning schedule
docker logs chimera_memory_pruner | grep -i schedule

# Manually trigger pruning
docker exec chimera_memory_pruner python3 /app/pruner.py
```

### Models Not Loading

```bash
# Check Ollama status
curl http://192.168.1.9:11434/api/tags

# Pull missing models
docker exec chimera_brain ollama pull llama3.2
```

---

## 🎓 Advanced Topics

### Custom Mode Creation

Edit constitution:
```json
"operational_modes": {
  "CUSTOM": {
    "priority": ["custom", "priorities"],
    "output_style": "custom_format",
    "model_preference": "DEEP",
    "system_prompt_suffix": "You are in custom mode. Do X, Y, Z."
  }
}
```

Add routing rule:
```json
"mode_router": {
  "rules": {
    "CUSTOM": {
      "keywords": ["custom", "trigger", "words"],
      "weight": 1.0
    }
  }
}
```

### Multi-Node Deployment

Deploy Jules Protocol on multiple machines:

**Brain** (192.168.1.9):
```bash
./install-jules-protocol.sh --integrate
```

**Brawn** (192.168.1.222):
```yaml
# On Unraid, deploy as Docker container
# Point to shared PostgreSQL and Qdrant
```

**Edge** (Raspberry Pi):
```bash
# Lightweight deployment with FAST models only
./install-jules-protocol.sh --standalone
```

### API Access

Expose AI Shell via API:

```python
# agents/aishell/api.py
from flask import Flask, request, jsonify
from aishell import AIShell

app = Flask(__name__)
shell = AIShell()

@app.route('/query', methods=['POST'])
def query():
    user_input = request.json.get('input')
    response = shell.process_input(user_input)
    return jsonify({"response": response})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8090)
```

---

## 📚 Reference

### File Locations

```
Constitution:     /home/user/brain/config/constitution/digital_renegade_core.v3.json
Bootstrap:        /home/user/brain/config/constitution/bootstrap_injector.txt
Evolution Log:    /home/user/brain/config/constitution/EVOLUTION_LOG.md
AI Shell:         /home/user/brain/agents/aishell/
Memory Pruner:    /home/user/brain/agents/memory_pruner/
Logs:             /var/log/jules_protocol/
CLI Command:      /usr/local/bin/jules
```

### Service URLs

```
AI Shell:         docker exec -it chimera_aishell python3 /app/aishell.py
Ollama Brain:     http://192.168.1.9:11434
Ollama Eyes:      http://192.168.1.9:11435
Qdrant:           http://192.168.1.9:6333
PostgreSQL:       postgresql://postgres:password@192.168.1.9:5432/chimera
Redis:            redis://192.168.1.9:6379/0
```

### Constitution Schema

See: `/home/user/brain/config/constitution/digital_renegade_core.v3.json`

Key sections:
- `identity` - Persona and voice
- `operational_modes` - Mode definitions
- `mode_router` - Keyword routing rules
- `model_router` - Tier selection
- `memory_system` - Three-tier config
- `memory_pruner` - Pruning rules
- `evolution` - Self-update protocol
- `integrations` - Home Assistant, Blue Iris, etc.

---

## 🤝 Support

### Logs

Always check logs first:
```bash
# All Jules Protocol logs
ls -lh /var/log/jules_protocol/

# AI Shell
docker logs chimera_aishell

# Memory Pruner
tail -f /var/log/jules_protocol/memory_pruner.log
```

### Diagnostics

```bash
# Check all services
docker ps | grep chimera

# Test Ollama
curl http://192.168.1.9:11434/api/tags

# Test memory backends
docker exec chimera_cache redis-cli PING
docker exec chimera_postgres psql -U postgres -c "SELECT 1;"
curl http://192.168.1.9:6333/collections
```

### Reset to Clean State

```bash
# Stop all services
docker compose -f portainer-stack-renegade.yml down

# Remove memory data (⚠️ DATA LOSS)
docker volume rm chimera_postgres_data chimera_qdrant_data

# Restart
docker compose -f portainer-stack-renegade.yml up -d
```

---

## 🎯 Final Notes

### What You Have

You now possess:
1. ✅ A complete, self-evolving AI operating system
2. ✅ Multi-model routing (FAST/DEEP/VISION/TOOLS)
3. ✅ Eight operational modes with auto-switching
4. ✅ Three-tier memory with autonomous pruning
5. ✅ Distributed intelligence topology
6. ✅ Smart home integration
7. ✅ Constitutional governance
8. ✅ Jules Winnfield personality

### This Is Not

- ❌ A chatbot
- ❌ A cloud service
- ❌ Vendor-locked
- ❌ Static or unchangeable

### This Is

- ✅ A sovereign AI architecture
- ✅ Local-first intelligence
- ✅ Self-evolving with user consent
- ✅ Transparent and auditable
- ✅ Built for long-term control

---

**Jules Protocol loaded. Let's do this properly.** 🧠🔥

---

*Document Version: 3.1.0*
*Last Updated: 2025-12-27*
*Maintainer: Digital Renegade Project*
