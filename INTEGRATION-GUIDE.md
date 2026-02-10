# Brawn ↔ Brain Integration Guide
## vLLM Only — No Ollama

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     REQUEST ROUTING                           │
│                                                               │
│  OpenWebUI (Brawn :3000)                                     │
│    ├─ Endpoint 1 → vLLM Brawn (:8002) Qwen2.5-7B-AWQ       │
│    └─ Endpoint 2 → vLLM Brain (:8000) Dolphin 8B-AWQ        │
│                                                               │
│  AnythingLLM → vLLM Brawn (RAG + embeddings stay local)     │
│  n8n → vLLM Brawn or Brain (configurable per workflow)       │
│  HA Voice → Whisper → vLLM Brawn → Piper                    │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────┐   2.5Gb   ┌──────────────────────┐
│  BRAWN (NODE A)      │◄─────────►│  BRAIN (NODE B)      │
│  192.168.1.222       │           │  192.168.1.9       │
│  RTX 4070 12GB       │           │  RX 7900 XT 20GB     │
│                      │           │                      │
│  vLLM 80% = 9.6GB   │           │  vLLM 90% = 18GB     │
│  TEI Embed  = 1.5GB  │           │  (or 50%+40% split)  │
│  Total GPU  = 11.1GB │           │  Total GPU = 18GB    │
│                      │           │                      │
│  + Qdrant, OpenWebUI │           │  + OpenWebUI (local) │
│  + AnythingLLM, n8n  │           │                      │
│  + Whisper, Piper    │           │                      │
│  + Media/Core stacks │           │                      │
└──────────────────────┘           └──────────────────────┘
```

---

## Step 1: Find Brain IP (5 min)

```bash
# From Brawn
nmap -sn 192.168.1.0/24 | grep -B2 "brain\|Pop\|Intel"

# Or on Brain directly
ip -4 addr show | grep "inet " | grep -v 127.0.0.1
```

Write it down: `BRAIN_IP = 192.168.1.9`

---

## Step 2: Deploy Brain (30 min)

```bash
# Copy files to Brain
scp brain-stack.yml brain-setup.sh user@192.168.1.9:~/

# SSH in
ssh user@BRAIN_IP
bash brain-setup.sh

# Download a model (pick one)
mkdir -p ~/models/cognitivecomputations
huggingface-cli download cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
  --local-dir ~/models/cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ

# Deploy
docker compose -f brain-stack.yml up -d

# Wait ~3 min for model load, then verify
curl http://localhost:8000/v1/models
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ","messages":[{"role":"user","content":"Say hi"}],"max_tokens":10}'
```

---

## Step 3: Connect Brawn to Brain (5 min)

Edit `03-ai-stack.yml` in Portainer — find:
```yaml
- OPENAI_API_BASE_URLS=http://172.25.0.20:8000/v1;http://${BRAIN_IP:-192.168.1.9}:8000/v1
```
Replace `192.168.1.9` with actual Brain IP. Update stack.

---

## Step 4: Add Brain in OpenWebUI (2 min)

1. Open `http://192.168.1.222:3000`
2. Settings → Admin → Connections
3. Verify both endpoints appear:
   - Brawn: `http://172.25.0.20:8000/v1`
   - Brain: `http://192.168.1.9:8000/v1`
4. Models from both nodes show in the dropdown

---

## Step 5: Voice Pipeline in HA (10 min)

In Home Assistant (`192.168.1.149`):

1. Add Wyoming integrations:
   - Whisper: `192.168.1.222:10300`
   - Piper: `192.168.1.222:10200`
2. Add OpenAI Conversation integration:
   - Base URL: `http://192.168.1.222:8002/v1`
   - API Key: `sk-brawn`
   - Model: `Qwen/Qwen2.5-7B-Instruct-AWQ`
3. Create Voice Assistant → assign STT/TTS/Conversation agent

---

## Step 6: Verify (5 min)

```bash
bash brawn-validate.sh BRAIN_IP
```

---

## Model Switching on Brain

vLLM doesn't hot-swap models like Ollama. To change models:

```bash
# Edit brain-stack.yml — change the --model line
# Then:
docker compose -f brain-stack.yml down
docker compose -f brain-stack.yml up -d
```

**Or run two models simultaneously** (uncomment `vllm-secondary` in brain-stack.yml):
- Primary on :8000 at 50% VRAM (~10GB) — large model
- Secondary on :8001 at 40% VRAM (~8GB) — smaller model
- Add both endpoints in OpenWebUI

**Models that fit at 90% (18GB):**

| Model | Size | Context |
|-------|------|---------|
| Dolphin 8B AWQ | ~6GB | 16K |
| Qwen2.5-7B AWQ | ~5GB | 8K |
| Llama 3.1 8B AWQ | ~6GB | 8K |
| Mistral 7B AWQ | ~5GB | 8K |
| Dolphin 12B AWQ | ~9GB | 8K |
| Mixtral 8x7B GPTQ | ~16GB | 4K |
| Llama 70B Q4 GPTQ | ~18GB | 2K (tight) |

---

## Troubleshooting

**Brain ROCm issues:**
```bash
rocm-smi                          # GPU visible?
rocminfo | grep "Name:"           # Driver loaded?
ls -la /dev/kfd /dev/dri/render*  # Devices exist?
```

**Brawn VRAM overcommit:**
If vLLM + embeddings + Plex transcode cause OOM, lower vLLM to 75%:
```yaml
- --gpu-memory-utilization
- "0.75"
```

**Brain firewall:**
```bash
sudo ufw allow 8000/tcp
sudo ufw allow 3000/tcp
```
