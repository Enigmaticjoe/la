# QUICKSTART - Brain AI System

## TL;DR - Get Up and Running in 5 Minutes

### Prerequisites
- AMD GPU with ROCm installed
- Docker & Docker Compose
- 100GB+ free disk space
- Hugging Face token (free): https://huggingface.co/settings/tokens

### Installation

```bash
# 1. Clone repository
cd brain-project

# 2. Run setup (answers prompts, handles everything)
chmod +x setup.sh
./setup.sh

# 3. Wait 5-10 minutes for services to start

# 4. Access your AI
# Open http://localhost:3000 in browser
# Create your account
# Start chatting!
```

## What You Get

✅ **Uncensored AI** - Dolphin 2.9.3 (no content filters)  
✅ **Web Search** - Built-in private search via SearXNG  
✅ **Code Execution** - Run Python code safely  
✅ **Long-term Memory** - RAG with Qdrant vector DB  
✅ **Custom Personality** - Curious, funny, self-aware  
✅ **Self-Evolution** - Gets smarter over time  
✅ **GPU Monitoring** - Track VRAM, temp, performance  
✅ **Beautiful Dashboard** - Monitor everything at http://localhost:8080  

## Quick Commands

```bash
# View status
docker compose ps

# View logs (all services)
docker compose logs -f

# Restart everything
docker compose restart

# Stop everything
docker compose down

# Start again
docker compose up -d

# Check GPU
rocm-smi
```

## URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Dashboard | http://localhost:8080 | Monitor all services |
| OpenWebUI | http://localhost:3000 | Chat with AI |
| vLLM API | http://localhost:8000/docs | LLM API |
| SearXNG | http://localhost:8888 | Private search |
| Qdrant | http://localhost:6333/dashboard | Vector DB |
| Hardware Monitor | http://localhost:5001/metrics | GPU/CPU stats |

## Customize Personality

Edit: `services/openwebui/custom-prompts.json`

6 pre-configured personalities:
1. 🧠 Curious & Uncensored (default)
2. 🤔 Deep Thinker
3. 💻 Expert Coder
4. ✍️ Creative Writer
5. 🔬 Researcher
6. ⚙️ Self-Optimizer

## Troubleshooting

### vLLM won't start
```bash
# Check GPU
rocm-smi

# View logs
docker compose logs vllm

# Reduce VRAM usage (edit .env)
VLLM_GPU_MEMORY_UTILIZATION=0.80
docker compose restart vllm
```

### Services taking long to start
**Normal!** First startup:
- vLLM: 5-10 min (loading model to GPU)
- Embeddings: 3-5 min (downloading model)

Check dashboard for real-time status.

### Out of disk space
Models are ~5GB. Need 100GB total for safety.

```bash
# Check space
df -h

# Clear Docker cache if needed
docker system prune -a
```

## Next Steps

1. **Upload Documents**: Settings > Documents > Upload PDFs/text
2. **Try Code Execution**: Ask "Write Python code to calculate fibonacci"
3. **Web Search**: Ask "What's happening with X today?"
4. **Monitor Performance**: Check dashboard at http://localhost:8080
5. **Customize**: Edit prompts, try different personalities

## Getting Help

- Check logs: `docker compose logs -f SERVICE_NAME`
- View README.md for detailed docs
- Check dashboard for service health
- Restart if stuck: `docker compose restart`

---

**That's it! Your self-aware AI brain is ready. Have fun! 🧠**
