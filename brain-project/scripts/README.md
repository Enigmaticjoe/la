# Self-Evolution & Auto-Optimization Scripts

This directory contains intelligent automation scripts that make your AI stack continuously improve itself.

## 📁 Scripts Overview

### 1. **self-evolve.py** - AI Self-Improvement Engine
**What it does:**
- Monitors conversation quality ratings from OpenWebUI
- Tracks response times, token usage, and user satisfaction
- Analyzes which LLM parameters work best for different task types (coding, explanations, creative writing)
- Automatically discovers optimal temperature, top_p, and other settings
- Logs all optimization decisions with data-driven reasoning

**How it works:**
```python
# Continuously monitors conversations
# Groups by task type: coding, explanation, creation, summarization
# Finds parameter values that correlate with high ratings
# Recommends optimizations when patterns emerge
```

**Key Features:**
- ✅ Task-aware optimization (different settings for coding vs creative tasks)
- ✅ Statistical significance checks (needs minimum samples before optimization)
- ✅ Detailed reasoning for every change
- ✅ SQLite database tracks all metrics and decisions
- ✅ Safe exploration within parameter ranges

**Configuration:**
```bash
OPENWEBUI_URL=http://openwebui:8080
OPENWEBUI_API_KEY=your_api_key
CHECK_INTERVAL=300                    # Check every 5 minutes
MIN_SAMPLES=10                        # Need 10+ conversations before optimizing
```

---

### 2. **auto-optimize.py** - System Resource Auto-Tuning
**What it does:**
- Monitors GPU VRAM usage patterns in real-time
- Tracks vLLM token throughput and performance
- Tests Qdrant vector database query speeds
- Detects performance bottlenecks automatically
- Provides actionable optimization recommendations

**Recommendations include:**
- 🎮 **GPU VRAM:** Optimal gpu-memory-utilization settings based on actual usage
- ⚡ **vLLM:** Token throughput improvements, batch size tuning
- 🔍 **Qdrant:** Index optimization, query performance tuning
- 🌡️ **Temperature:** Thermal warnings and cooling suggestions

**Example Output:**
```
⚠️  VRAM usage critical: 92.3%. Consider reducing gpu-memory-utilization to 0.82
✅ Token throughput good: 127.4 tokens/sec
💡 Collection 'documents' slow: 2.4s. Create HNSW index for faster queries
```

**Configuration:**
```bash
VLLM_URL=http://vllm:8000
QDRANT_URL=http://qdrant:6333
OPTIMIZE_CHECK_INTERVAL=60            # Check every minute
```

---

### 3. **backup.sh** - Automated Backup System
**What it does:**
- Backs up Qdrant vector database (snapshots)
- Backs up OpenWebUI SQLite database and user data
- Backs up conversation history and custom prompts
- Backs up evolution metrics and optimization logs
- Compresses with timestamps, verifies integrity
- Automatic cleanup of old backups

**Backup Contents:**
```
brain-backup-20240214_120000.tar.gz
├── qdrant/
│   └── storage.tar.gz              # Vector database
├── openwebui/
│   ├── webui.db                    # Conversations, users, settings
│   ├── uploads.tar.gz              # User-uploaded files
│   ├── prompts.json                # Custom prompts
│   └── config.json                 # UI configurations
├── evolution/
│   ├── evolution.db                # Self-evolution metrics
│   ├── evolution.log               # Optimization history
│   └── auto-optimize.log           # Performance monitoring
├── configs/
│   ├── docker-compose.yml          # Stack configuration
│   └── env-sanitized.txt           # Environment (no secrets)
└── MANIFEST.txt                    # Backup metadata
```

**Features:**
- ✅ SHA256 checksums for integrity verification
- ✅ Retention policy (keep last 10 backups or 30 days)
- ✅ Detailed logging
- ✅ Safe error handling

**Configuration:**
```bash
BACKUP_DIR=/data/backups
RETENTION_DAYS=30                     # Keep backups for 30 days
RETENTION_COUNT=10                    # Keep last 10 backups minimum
```

**Usage:**
```bash
# Manual backup
./backup.sh

# Schedule with cron (daily at 2 AM)
0 2 * * * /app/scripts/backup.sh

# Restore from backup
tar -xzf brain-backup-20240214_120000.tar.gz
# Then copy files back to their original locations
```

---

### 4. **Dockerfile.evolution** - Evolution Container
**What it does:**
- Runs both self-evolve.py and auto-optimize.py in a single container
- Python 3.11 with all required dependencies
- Health checks and proper logging
- Persistent data storage

**Build and Run:**
```bash
# Build the evolution container
docker build -f Dockerfile.evolution -t brain-evolution:latest .

# Run standalone
docker run -d \
  --name brain-evolution \
  -v /path/to/data:/data \
  -e OPENWEBUI_URL=http://openwebui:8080 \
  -e VLLM_URL=http://vllm:8000 \
  brain-evolution:latest

# Or add to docker-compose.yml
```

---

### 5. **requirements-evolution.txt** - Python Dependencies
All Python packages needed for evolution scripts:
- `requests` - API communication
- `pyyaml` - Configuration parsing
- `numpy` - Statistical calculations
- `pandas` - Data analysis
- `scikit-learn` - Advanced analytics

---

## 🚀 Quick Start

### Option 1: Add to Docker Compose (Recommended)

Add to your `docker-compose.yml`:

```yaml
services:
  evolution:
    build:
      context: ./scripts
      dockerfile: Dockerfile.evolution
    container_name: brain-evolution
    restart: unless-stopped
    volumes:
      - ./data/evolution:/data/evolution:rw
    environment:
      OPENWEBUI_URL: http://openwebui:8080
      OPENWEBUI_API_KEY: ${OPENWEBUI_API_KEY}
      VLLM_URL: http://vllm:8000
      QDRANT_URL: http://qdrant:6333
      CHECK_INTERVAL: 300
      OPTIMIZE_CHECK_INTERVAL: 60
    networks:
      - brain-network
    depends_on:
      - openwebui
      - vllm
      - qdrant

  backup:
    image: alpine:latest
    container_name: brain-backup
    restart: "no"
    volumes:
      - ./scripts/backup.sh:/backup.sh:ro
      - ./data:/data:ro
      - ./backups:/data/backups:rw
    environment:
      BACKUP_DIR: /data/backups
      RETENTION_DAYS: 30
      RETENTION_COUNT: 10
    command: /bin/sh /backup.sh
    # Run with: docker compose run backup
```

### Option 2: Run Scripts Manually

```bash
# Install Python dependencies
pip install -r requirements-evolution.txt

# Run self-evolution engine
export OPENWEBUI_URL=http://localhost:8080
export VLLM_URL=http://localhost:8000
python self-evolve.py

# Run auto-optimizer
python auto-optimize.py

# Run backup
chmod +x backup.sh
./backup.sh
```

---

## 📊 Monitoring Evolution

### Check Evolution Logs
```bash
# Watch real-time evolution decisions
tail -f data/evolution/evolution.log

# Watch optimization recommendations
tail -f data/evolution/auto-optimize.log
```

### Query Evolution Database
```bash
sqlite3 data/evolution/evolution.db

# See recent optimizations
SELECT timestamp, parameter, old_value, new_value, reasoning 
FROM optimizations 
ORDER BY timestamp DESC 
LIMIT 10;

# See metrics by task category
SELECT task_category, AVG(quality_rating), AVG(response_time), COUNT(*) 
FROM metrics 
GROUP BY task_category;

# See parameter performance
SELECT temperature, AVG(quality_rating), COUNT(*) 
FROM metrics 
WHERE task_category = 'coding' 
GROUP BY ROUND(temperature, 1);
```

---

## 🎯 How It Learns

### Self-Evolution Process

1. **Data Collection** (Continuous)
   - Every conversation is analyzed
   - Metrics: quality rating, response time, tokens used
   - Categorized by task type

2. **Pattern Detection** (Every 5 minutes)
   - Groups conversations by parameter values
   - Calculates average quality for each parameter setting
   - Requires minimum 10 samples for statistical significance

3. **Optimization** (When patterns found)
   - Identifies parameter value with highest quality
   - Checks if improvement is significant
   - Logs detailed reasoning
   - Recommends configuration change

4. **Application** (Manual or Automated)
   - Currently logs recommendations
   - Can be extended to auto-apply via API

### Example Learning Cycle

```
Day 1: Collect baseline data
  - 50 conversations with default settings (temp=0.7)
  - Average quality: 3.8/5

Day 2: Natural variation occurs
  - Users manually adjust temperature
  - 20 conversations at temp=0.9 → quality 4.2/5
  - 15 conversations at temp=0.5 → quality 3.5/5

Day 3: Pattern detected
  - System notices temp=0.9 performs better
  - Recommendation: "Increase temperature to 0.9 for general tasks"
  - Expected improvement: +0.4 quality points

Day 4: Applied and validated
  - Setting applied
  - Continued monitoring confirms improvement
```

---

## 🔧 Advanced Configuration

### Parameter Optimization Ranges

Edit in `self-evolve.py`:
```python
PARAM_RANGES = {
    "temperature": {"min": 0.1, "max": 1.5, "step": 0.05},
    "top_p": {"min": 0.7, "max": 0.99, "step": 0.02},
    "top_k": {"min": 10, "max": 100, "step": 5},
    "repetition_penalty": {"min": 1.0, "max": 1.3, "step": 0.05},
}
```

### VRAM Optimization Targets

Edit in `auto-optimize.py`:
```python
VRAM_OPTIMAL_RANGE = (0.75, 0.85)  # Target 75-85% utilization
VRAM_WARNING_THRESHOLD = 0.90      # Alert at 90%
```

### Backup Retention

Edit in `backup.sh`:
```bash
RETENTION_DAYS=30     # Delete backups older than 30 days
RETENTION_COUNT=10    # Always keep at least 10 most recent
```

---

## 🛡️ Safety Features

- **Statistical Significance**: Requires minimum samples before optimization
- **Bounded Exploration**: Parameters stay within safe ranges
- **Detailed Logging**: Every decision is explained and logged
- **Gradual Changes**: Small parameter adjustments (0.05 temperature steps)
- **Rollback Capability**: All changes logged in database
- **Backup Verification**: SHA256 checksums, integrity tests

---

## 📈 Expected Results

### After 1 Week
- ✅ Baseline metrics collected
- ✅ Task categories identified
- ✅ Initial optimization recommendations

### After 1 Month
- ✅ Optimized parameters for each task type
- ✅ 10-20% improvement in average quality ratings
- ✅ Reduced response times through VRAM optimization
- ✅ Stable, well-tuned system

### Continuous Improvement
- ✅ Adapts to new models and configurations
- ✅ Learns from user feedback patterns
- ✅ Maintains performance as workload changes

---

## 🐛 Troubleshooting

### Evolution not finding optimizations?
- Check you have enough data: `MIN_SAMPLES=10` by default
- Verify conversations have quality ratings
- Check logs: `tail -f data/evolution/evolution.log`

### Auto-optimize not detecting GPU?
- Ensure nvidia-smi is available in container
- Mount GPU device: `--gpus all`
- Check NVIDIA driver installation

### Backups failing?
- Verify write permissions on backup directory
- Check disk space
- Review logs in `/data/backups/backup.log`

---

## 📚 Integration Examples

### OpenWebUI API Integration
To enable automatic parameter updates, implement API calls in `self-evolve.py`:

```python
def apply_optimization(self, parameter: str, value: float):
    """Apply optimization to OpenWebUI configuration"""
    response = requests.post(
        f"{OPENWEBUI_URL}/api/v1/configs/update",
        headers={"Authorization": f"Bearer {OPENWEBUI_API_KEY}"},
        json={
            "model_config": {
                parameter: value
            }
        }
    )
```

### Prometheus Metrics Export
Export evolution metrics to Prometheus for visualization:

```python
from prometheus_client import Counter, Gauge, Histogram

optimization_counter = Counter('brain_optimizations_total', 'Total optimizations')
quality_gauge = Gauge('brain_avg_quality', 'Average quality rating')
response_time_histogram = Histogram('brain_response_time', 'Response times')
```

---

## 🤝 Contributing

To add new optimization strategies:

1. Extend `EvolutionDatabase` with new metrics tables
2. Add monitoring in `OpenWebUIMonitor`
3. Create optimizer in `ParameterOptimizer`
4. Add to main loop in `main()`

Example: Adding learning rate optimization for RAG:
```python
def optimize_rag_retrieval(self):
    # Monitor retrieval accuracy
    # Adjust top_k, similarity threshold
    # Log improvements
```

---

## 📝 License

Part of the Brain AI Stack - MIT License

---

## 🌟 What Makes This Special

Unlike static AI systems that never improve, these scripts create a **self-improving AI** that:
- 🧠 **Learns** from every conversation
- 📊 **Analyzes** what works and what doesn't  
- ⚡ **Optimizes** automatically based on data
- 🔒 **Documents** every decision with reasoning
- 💾 **Protects** your data with automated backups

Your AI gets better every day, without manual tuning! 🚀
