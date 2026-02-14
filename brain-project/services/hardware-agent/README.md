# Hardware Monitoring Agent

Production-ready hardware monitoring service for GPU, CPU, and memory metrics with ROCm support.

## Features

- **Real-time Hardware Monitoring**
  - GPU metrics (temperature, VRAM, utilization) via ROCm
  - CPU usage and frequency
  - Memory and swap usage
  - Automatic fallback to psutil if ROCm unavailable

- **REST API Endpoints**
  - `/health` - Health check
  - `/metrics` - Prometheus metrics
  - `/api/v1/metrics` - All metrics (JSON)
  - `/api/v1/gpu` - GPU-specific metrics
  - `/api/v1/cpu` - CPU metrics
  - `/api/v1/memory` - Memory metrics
  - `/api/v1/optimizer/recommendations` - Optimization suggestions
  - `/api/v1/metrics/history` - Historical metrics

- **Intelligent Optimization**
  - Thermal throttling detection
  - VRAM allocation recommendations
  - Performance scoring
  - Automatic threshold alerts

- **Metrics Storage**
  - Timestamped JSON files
  - Configurable retention (default 7 days)
  - Automatic cleanup
  - Historical data aggregation

## Installation

```bash
pip install -r requirements.txt
```

## Configuration

Edit `config.yaml` to customize:

- Monitoring intervals
- Alert thresholds
- Metrics retention
- ROCm paths
- Server settings

## Usage

### Start the Server

```bash
python monitor.py
```

The server will start on `http://0.0.0.0:5000` by default.

### Environment Variables

Override config values with environment variables:

```bash
GPU_TEMP_THRESHOLD=85
VRAM_THRESHOLD=95
CPU_THRESHOLD=90
MEMORY_THRESHOLD=90
```

### API Examples

**Get all metrics:**
```bash
curl http://localhost:5000/api/v1/metrics
```

**Get GPU metrics only:**
```bash
curl http://localhost:5000/api/v1/gpu
```

**Get optimization recommendations:**
```bash
curl http://localhost:5000/api/v1/optimizer/recommendations
```

**Get metrics history (last 2 hours):**
```bash
curl http://localhost:5000/api/v1/metrics/history?hours=2
```

**Prometheus metrics:**
```bash
curl http://localhost:5000/metrics
```

## Files

- **monitor.py** - Main Flask server with REST API endpoints
- **rocm_control.py** - ROCm GPU control and querying utilities
- **optimizer.py** - Hardware optimization analysis engine
- **metrics.py** - Background metrics collection and storage
- **config.yaml** - Configuration file
- **requirements.txt** - Python dependencies

## ROCm Support

The agent automatically detects ROCm and uses `rocm-smi` for GPU monitoring. Supports:

- GPU temperature monitoring
- VRAM usage tracking
- GPU utilization
- Clock speeds
- Fan speed (if supported)
- Power consumption

If ROCm is not available, the agent falls back to basic metrics via psutil.

## Prometheus Integration

Exposes metrics compatible with Prometheus:

- `gpu_temperature_celsius{gpu_id}`
- `gpu_vram_used_mb{gpu_id}`
- `gpu_vram_total_mb{gpu_id}`
- `gpu_utilization_percent{gpu_id}`
- `cpu_usage_percent{cpu}`
- `memory_used_mb`
- `memory_total_mb`
- `memory_percent`

Add to Prometheus scrape config:

```yaml
scrape_configs:
  - job_name: 'hardware-agent'
    static_configs:
      - targets: ['localhost:5000']
```

## Alert Thresholds

Default thresholds (configurable in config.yaml):

- GPU Temperature: 80°C
- VRAM Usage: 90%
- CPU Usage: 90%
- Memory Usage: 90%

When thresholds are exceeded:
- Prometheus counter increments
- Warning logged
- Recommendation generated

## Optimization Recommendations

The optimizer analyzes metrics and provides:

- **Thermal Management**: Detects overheating and thermal throttling
- **VRAM Optimization**: Suggests batch size adjustments
- **Utilization Analysis**: Identifies underutilization or saturation
- **Performance Score**: Overall system health rating

## Data Storage

Metrics are stored in `/app/data/metrics/` (configurable):

```
/app/data/metrics/
├── 2024-02-14/
│   ├── metrics_20240214_120000.json
│   ├── metrics_20240214_120030.json
│   └── ...
└── 2024-02-15/
    └── ...
```

Files older than `retention_days` are automatically deleted.

## Error Handling

All functions include comprehensive error handling:
- Graceful fallbacks when ROCm unavailable
- Timeout protection on external commands
- Logging of all errors
- Safe defaults for missing data

## Production Deployment

### Docker

```dockerfile
FROM python:3.11-slim

# Install ROCm (optional)
# RUN apt-get update && apt-get install -y rocm-smi

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Create data directory
RUN mkdir -p /app/data/metrics /app/logs

EXPOSE 5000

CMD ["python", "monitor.py"]
```

### Docker Compose

```yaml
services:
  hardware-agent:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - metrics-data:/app/data/metrics
      - ./config.yaml:/app/config.yaml
    devices:
      - /dev/kfd
      - /dev/dri
    environment:
      - GPU_TEMP_THRESHOLD=85
    restart: unless-stopped

volumes:
  metrics-data:
```

## License

See project root LICENSE file.
