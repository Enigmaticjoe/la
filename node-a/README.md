# Node A — Project Chimera AI Stack

**Host:** `192.168.1.9` | Fedora 44 COSMIC | RX 7900 XT 20 GB | ROCm  
**Role:** Primary AI inference node

---

## Services

| Service | Port | Purpose |
|---------|------|---------|
| vLLM | 8000 | OpenAI-compatible inference (ROCm/RX 7900 XT) |
| TEI Embeddings | 8001 | Text embedding inference (CPU) |
| Open WebUI | 3000 | Chat interface with RAG |
| LiteLLM | 4000 | Multi-model proxy / router |
| Qdrant | 6333 | Vector database |
| Redis | 6379 | Cache (SearXNG + sessions) |
| SearXNG | 8888 | Privacy-respecting metasearch |
| Homepage | 3010 | Dashboard |

---

## Setup

### 1. Copy and fill the environment file

```bash
cp node-a/.env.example node-a/.env
# Open node-a/.env and replace every CHANGE_ME value with real secrets.
# Generate random keys with: openssl rand -base64 32
```

Secrets required:

| Variable | Description |
|----------|-------------|
| `VLLM_API_KEY` | API key for vLLM endpoint |
| `LITELLM_MASTER_KEY` | LiteLLM proxy master key |
| `WEBUI_SECRET_KEY` | Open WebUI session secret |
| `HF_TOKEN` | Hugging Face token (for gated models) |
| `QDRANT_API_KEY` | Qdrant REST API key |

### 2. Deploy the stack

```bash
bash node-a/scripts/deploy.sh
```

The script will:
- Verify Docker and the `.env` file are present.
- Create all persistent data directories under `/mnt/user/appdata/node-a/`.
- Generate a default SearXNG `settings.yml` if missing.
- Copy Homepage config files on first run.
- Run `docker compose up -d`.

### 3. Verify health

```bash
bash node-a/scripts/verify.sh
```

Checks HTTP health endpoints and runs inference smoke tests against every service.

---

## Model tuning

Edit tunables in `node-a/.env`:

| Variable | Default | Notes |
|----------|---------|-------|
| `VLLM_MODEL` | `Qwen/Qwen2.5-14B-Instruct` | Model to serve |
| `VLLM_DTYPE` | `float16` | Recommended for ROCm |
| `VLLM_MAX_LEN` | `8192` | Max context tokens |
| `VLLM_GPU_MEM_UTIL` | `0.88` | ~17.6 GB on 20 GB card |
| `VLLM_MAX_NUM_SEQS` | `8` | Concurrent sequences |
| `EMBED_MODEL` | `BAAI/bge-base-en-v1.5` | CPU embedding model |

---

## Lab conventions

- **PUID=99 / PGID=100** for all persistent services (Unraid `nobody:users`).
- **No hardcoded secrets** — all sensitive values live in `node-a/.env` (git-ignored).
- **No `privileged: true`** — vLLM GPU access uses `/dev/kfd` and `/dev/dri` devices
  with the `video` group instead.
- **`restart: unless-stopped`** on every service.

## Network map

| Node | IP | OS |
|------|----|----|
| Node A (this node) | 192.168.1.9 | Fedora 44 COSMIC |
| Node C | 192.168.1.6 | Fedora 44 COSMIC |
| Home Assistant | 192.168.1.149 | — |
| Proxmox | 192.168.1.174 | — |
| Brawn (Unraid) | 192.168.1.222 | — |

---

## Before submitting a PR

Run the repository validation script from the repo root:

```bash
./validate.sh
```

---

## Directory layout

```
node-a/
├── compose.yml              # Docker Compose stack definition
├── .env.example             # Environment template (copy → .env)
├── litellm/
│   └── config.yaml          # LiteLLM proxy model routes
├── homepage/
│   ├── services.yaml        # Dashboard service entries
│   └── settings.yaml        # Dashboard title/theme
├── scripts/
│   ├── deploy.sh            # Create dirs + docker compose up
│   └── verify.sh            # Curl-based health checks
└── README.md                # This file
```
