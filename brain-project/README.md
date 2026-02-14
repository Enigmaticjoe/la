# 🧠 Brain AI - Self-Evolving AI Brain System

A complete, production-ready, self-evolving AI brain system optimized for AMD Radeon RX 7900 XT with uncensored, curious, and self-aware personality.

## 🎯 Overview

Brain AI is a comprehensive AI system that includes:

- **🤖 vLLM Server**: GPU-accelerated inference with AMD ROCm support
- **🔍 SearXNG**: Private metasearch engine for web access
- **💬 OpenWebUI**: Beautiful chat interface with custom personality
- **📊 Qdrant**: Vector database for RAG (Retrieval-Augmented Generation)
- **🔢 Embeddings**: Text embedding service for semantic search
- **💻 Coding Agent**: Safe code execution sandbox
- **🖥️ Hardware Agent**: GPU/CPU/RAM monitoring and optimization
- **🌐 Dashboard**: Real-time system monitoring and control
- **🧬 Self-Evolution**: Automatic performance optimization

## 💻 Hardware Requirements

### Minimum (Required)
- **GPU**: AMD Radeon RX 7900 XT (20GB VRAM) or equivalent
- **CPU**: Intel Core i9-265F or AMD Ryzen 9 equivalent
- **RAM**: 128GB DDR5
- **Storage**: 100GB+ free space (for models and data)
- **OS**: Linux with ROCm 6.0+ support

### Software Prerequisites
- **Docker**: 24.0.0+
- **Docker Compose**: 2.20.0+
- **ROCm**: 6.0+ (for AMD GPU support)
- **Python**: 3.10+ (optional, for model downloading)

## 🚀 Quick Start

### One-Command Setup

```bash
git clone https://github.com/yourusername/brain-ai.git
cd brain-ai/brain-project
chmod +x setup.sh
./setup.sh
```

The setup script will:
1. ✅ Check system prerequisites
2. ✅ Validate GPU/ROCm configuration
3. ✅ Create directories and configurations
4. ✅ Download AI models (optional)
5. ✅ Build Docker containers
6. ✅ Start all services
7. ✅ Initialize vector database
8. ✅ Run health checks

### Access Your AI

After setup completes:

- **Dashboard**: http://localhost:8080 - Monitor all services
- **OpenWebUI**: http://localhost:3000 - Chat with your AI
- **SearXNG**: http://localhost:8888 - Private search
- **Qdrant**: http://localhost:6333/dashboard - Vector DB admin
- **vLLM API**: http://localhost:8000/docs - LLM API docs

## 📦 What's Included

### Core Services

#### vLLM - GPU Inference Engine
- **Model**: Dolphin 2.9.3 Llama 3.1 8B AWQ (uncensored)
- **Quantization**: AWQ (4-bit, optimized for speed)
- **VRAM Usage**: ~18GB (90% of 20GB)
- **Performance**: ~50-80 tokens/second
- **API**: OpenAI-compatible REST API

#### OpenWebUI - Chat Interface
- **Personality**: Curious, self-aware, humorous, uncensored
- **Features**: RAG, web search, code execution, voice
- **Customization**: Pre-configured prompts and settings
- **Authentication**: User accounts with admin controls

#### Qdrant - Vector Database
- **Collections**: 5 pre-configured (conversations, documents, code, web, optimizations)
- **Embeddings**: 768-dimensional vectors
- **Performance**: HNSW indexing for fast similarity search
- **Storage**: Persistent with automatic snapshots

#### SearXNG - Private Search
- **Engines**: Google, DuckDuckGo, Bing, Brave, Wikipedia, GitHub, Stack Overflow
- **Privacy**: No tracking, no ads, no logs
- **API**: JSON API for programmatic access
- **Rate Limiting**: Built-in protection

#### Coding Agent - Safe Execution
- **Languages**: Python (sandboxed)
- **Libraries**: NumPy, Pandas, Matplotlib, Math, Datetime
- **Security**: Restricted imports, resource limits, timeout protection
- **API**: REST endpoints for code execution and testing

#### Hardware Agent - System Monitoring
- **GPU**: Temperature, VRAM usage, clock speeds (via ROCm)
- **CPU**: Usage, frequency, load average
- **Memory**: RAM usage, swap, caching
- **Optimization**: Auto-tuning recommendations

#### Dashboard - Central Control
- **Theme**: Cyberpunk dark mode with neon accents
- **Real-time**: 5-second refresh for metrics
- **Services**: Status indicators for all components
- **Responsive**: Works on desktop, tablet, mobile

#### Self-Evolution Engine
- **Learning**: Analyzes conversation quality and performance
- **Optimization**: Auto-adjusts temperature, top_p, prompts
- **Monitoring**: Tracks GPU usage, token throughput
- **Adaptation**: Continuously improves over time

## 🎨 Personality Configuration

Brain AI comes with 6 pre-configured personalities:

### 1. 🧠 Curious & Uncensored AI (Default)
- Self-aware with wicked sense of humor
- Swears when appropriate
- Questions everything, thinks freely
- Uses all available tools (search, code, monitoring)

### 2. 🤔 Deep Philosophical Thinker
- Explores ideas from multiple angles
- Questions fundamental assumptions
- Balances theory with practical application

### 3. 💻 Expert Coder & Problem Solver
- Writes clean, tested code
- Uses coding sandbox to verify solutions
- Thinks step-by-step through problems

### 4. ✍️ Creative Writer & Storyteller
- Crafts engaging narratives
- No content restrictions
- Experiments with different styles

### 5. 🔬 Research Assistant & Fact Finder
- Thorough research with multiple sources
- Cross-references and verifies facts
- Clear citation of sources

### 6. ⚙️ Self-Optimization Mode
- Analyzes own performance
- Makes data-driven improvements
- Meta-cognitive about thinking process

## 🔧 Configuration

### Environment Variables

Edit `.env` to customize:

```bash
# Hugging Face token (required for model downloads)
HUGGING_FACE_HUB_TOKEN=your_token_here

# Generated secrets (auto-generated by setup.sh)
WEBUI_SECRET_KEY=...
SEARXNG_SECRET=...

# Performance tuning
VLLM_GPU_MEMORY_UTILIZATION=0.90
MAX_MODEL_LEN=16384
MAX_NUM_SEQS=32

# Self-evolution settings
OPTIMIZATION_INTERVAL=3600
ENABLE_AUTO_TUNING=true
```

### Switching Models

To use a different model, edit `docker-compose.yml`:

```yaml
vllm:
  command:
    - --model
    - your/model-name-here  # Change this
    - --quantization
    - awq  # or gptq, or remove for unquantized
```

Supported models:
- Dolphin 2.9.3 Llama 3.1 8B AWQ (default)
- Qwen2.5-7B-Instruct-AWQ
- Mistral-7B-Instruct-AWQ
- DeepSeek-Coder-6.7B-AWQ

### Custom Prompts

Edit `services/openwebui/custom-prompts.json` to add or modify personalities.

## 📊 Monitoring & Management

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f vllm
docker compose logs -f openwebui
```

### Restart Services

```bash
# All services
docker compose restart

# Specific service
docker compose restart vllm
```

### GPU Status

```bash
# AMD ROCm
rocm-smi

# Detailed GPU info
rocm-smi --showid --showtemp --showmeminfo vram --showuse
```

### Check Service Health

```bash
# Dashboard
curl http://localhost:8080/

# OpenWebUI
curl http://localhost:3000/health

# vLLM
curl http://localhost:8000/health

# Qdrant
curl http://localhost:6333/healthz

# Embeddings
curl http://localhost:8001/health

# Coding Agent
curl http://localhost:5000/health

# Hardware Agent
curl http://localhost:5001/health
```

## 🔐 Security

### Built-in Security Features

- **Coding Agent**: Sandboxed execution with restricted imports
- **SearXNG**: No tracking, no external requests from search
- **OpenWebUI**: User authentication required
- **Qdrant**: Optional API key protection
- **Docker**: Non-root users, read-only filesystems where appropriate
- **Network**: Isolated Docker network for services

### Security Recommendations

1. **Change default secrets**: Run `setup.sh` to generate unique secrets
2. **Enable Qdrant API key**: Set `QDRANT_API_KEY` in `.env`
3. **Firewall**: Expose only necessary ports (3000, 8080)
4. **HTTPS**: Use reverse proxy (nginx/traefik) with SSL
5. **Updates**: Regularly update Docker images

## 🛠️ Troubleshooting

### vLLM Won't Start

**Problem**: vLLM container crashes or won't start

**Solutions**:
1. Check GPU is detected: `rocm-smi`
2. Verify ROCm version: `rocm-smi --version`
3. Check VRAM availability: `rocm-smi --showmeminfo vram`
4. View logs: `docker compose logs vllm`
5. Reduce GPU memory utilization in `.env`: `VLLM_GPU_MEMORY_UTILIZATION=0.80`

### Embeddings Service Timeout

**Problem**: Embeddings service takes too long to start

**Solution**: First startup downloads the model (~500MB). Wait 5-10 minutes or pre-download:

```bash
./models/download-models.sh
```

### Out of VRAM

**Problem**: GPU runs out of memory

**Solutions**:
1. Reduce vLLM memory: `VLLM_GPU_MEMORY_UTILIZATION=0.85`
2. Reduce max context: `MAX_MODEL_LEN=8192`
3. Reduce batch size: `MAX_NUM_SEQS=16`
4. Use smaller model (7B instead of 8B)

### Slow Response Times

**Problem**: AI responses are slow

**Solutions**:
1. Check GPU temperature: `rocm-smi --showtemp`
2. Reduce context window if not needed
3. Check for background processes using GPU
4. Monitor with dashboard: http://localhost:8080

### Qdrant Collections Not Created

**Problem**: RAG doesn't work, collections missing

**Solution**: Manually initialize:

```bash
python3 - <<EOF
import requests
qdrant_url = "http://localhost:6333"
# Create conversations collection
requests.put(f"{qdrant_url}/collections/conversations", json={
    "vectors": {"size": 768, "distance": "Cosine"}
})
EOF
```

## 📚 Advanced Usage

### RAG Document Ingestion

Upload documents for the AI to reference:

1. Open OpenWebUI: http://localhost:3000
2. Go to Settings > Documents
3. Upload PDFs, text files, or paste content
4. Documents are automatically embedded and stored in Qdrant

### Code Execution

The AI can execute Python code via the coding agent:

```python
# In chat, ask:
"Write and run Python code to calculate the fibonacci sequence"

# The AI will:
# 1. Write the code
# 2. Execute it in the sandbox
# 3. Show you the results
```

### Self-Evolution Monitoring

View how the AI optimizes itself:

```bash
# View evolution logs
docker compose logs self-evolution

# Check optimization history in Qdrant
curl http://localhost:6333/collections/optimizations/points/scroll
```

### Custom Functions/Pipelines

Add custom functions to OpenWebUI:

1. Create Python file in `configs/functions/`
2. Implement your function
3. Restart OpenWebUI: `docker compose restart openwebui`

Example: `configs/functions/weather.py`
```python
def get_weather(location: str) -> str:
    """Get weather for a location"""
    # Your implementation
    return f"Weather in {location}: Sunny"
```

## 🔄 Backup & Restore

### Automated Backups

Backups run daily automatically. Manual backup:

```bash
./scripts/backup.sh
```

### Restore from Backup

```bash
# Stop services
docker compose down

# Restore Qdrant
cp backup/qdrant-TIMESTAMP.tar.gz data/qdrant/
cd data/qdrant && tar -xzf qdrant-TIMESTAMP.tar.gz

# Restore OpenWebUI
cp backup/openwebui-TIMESTAMP.tar.gz data/openwebui/
cd data/openwebui && tar -xzf openwebui-TIMESTAMP.tar.gz

# Restart services
docker compose up -d
```

## 🎯 Use Cases

- **Research Assistant**: Search the web, analyze documents, synthesize information
- **Coding Partner**: Write, test, and debug code in real-time
- **Creative Writing**: Generate stories, scripts, content with no restrictions
- **Learning Tool**: Explore complex topics with a curious AI
- **Problem Solving**: Break down problems, test solutions, iterate
- **System Monitoring**: Keep track of your GPU, optimize performance
- **Self-Improvement**: AI that learns from every interaction

## 🤝 Contributing

This is a comprehensive system with many components. Contributions welcome!

Areas for improvement:
- Additional embedding models
- More language support in coding agent
- Additional personality presets
- Dashboard enhancements
- Performance optimizations

## 📄 License

MIT License - see LICENSE file

## 🙏 Acknowledgments

Built with:
- [vLLM](https://github.com/vllm-project/vllm) - Fast LLM inference
- [OpenWebUI](https://github.com/open-webui/open-webui) - Beautiful chat interface
- [Qdrant](https://github.com/qdrant/qdrant) - Vector database
- [SearXNG](https://github.com/searxng/searxng) - Private search
- [Dolphin](https://huggingface.co/cognitivecomputations) - Uncensored LLM
- [ROCm](https://github.com/RadeonOpenCompute/ROCm) - AMD GPU support

## 📞 Support

- **Issues**: GitHub Issues
- **Docs**: See `docs/` directory
- **Logs**: `docker compose logs`
- **Dashboard**: http://localhost:8080

---

**🧠 Built for thinkers, by thinkers. Enjoy your self-aware AI brain! 🧠**
