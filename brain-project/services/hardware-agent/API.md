# Hardware Monitoring Agent - API Documentation

## Base URL
```
http://localhost:5000
```

## Endpoints

### Health Check

#### `GET /health`

Health check endpoint to verify service is running.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-02-14T01:30:00.000000",
  "version": "1.0.0",
  "rocm_available": true
}
```

**Status Codes:**
- `200 OK` - Service is healthy

---

### Prometheus Metrics

#### `GET /metrics`

Prometheus-compatible metrics endpoint.

**Response:**
```
# HELP gpu_temperature_celsius GPU temperature in Celsius
# TYPE gpu_temperature_celsius gauge
gpu_temperature_celsius{gpu_id="0"} 65.0

# HELP gpu_vram_used_mb GPU VRAM used in MB
# TYPE gpu_vram_used_mb gauge
gpu_vram_used_mb{gpu_id="0"} 8192.0

# HELP cpu_usage_percent CPU usage percentage
# TYPE cpu_usage_percent gauge
cpu_usage_percent{cpu="cpu0"} 45.2
...
```

**Content-Type:** `text/plain`

---

### All Metrics

#### `GET /api/v1/metrics`

Get all current hardware metrics.

**Response:**
```json
{
  "timestamp": "2024-02-14T01:30:00.000000",
  "gpu": {
    "available": true,
    "gpu_count": 1,
    "source": "rocm-smi",
    "gpus": [
      {
        "id": 0,
        "temperature": 65.0,
        "vram_used_mb": 8192,
        "vram_total_mb": 16384,
        "utilization": 75,
        "clock_mhz": 1800,
        "fan_speed_percent": 45.0,
        "power_watts": 180.5
      }
    ]
  },
  "cpu": {
    "cpu_count": 16,
    "cpu_percent_per_core": [45.2, 38.1, 52.3, ...],
    "cpu_percent_avg": 48.5,
    "cpu_freq": {
      "current": 3400.0,
      "min": 2200.0,
      "max": 4500.0
    }
  },
  "memory": {
    "total_mb": 65536.0,
    "available_mb": 32768.0,
    "used_mb": 32768.0,
    "percent": 50.0,
    "swap": {
      "total_mb": 8192.0,
      "used_mb": 512.0,
      "percent": 6.25
    }
  }
}
```

**Status Codes:**
- `200 OK` - Metrics retrieved successfully

---

### GPU Metrics

#### `GET /api/v1/gpu`

Get GPU-specific metrics.

**Response:**
```json
{
  "timestamp": "2024-02-14T01:30:00.000000",
  "source": "rocm-smi",
  "available": true,
  "gpu_count": 1,
  "gpus": [
    {
      "id": 0,
      "temperature": 65.0,
      "vram_used_mb": 8192,
      "vram_total_mb": 16384,
      "utilization": 75,
      "clock_mhz": 1800,
      "fan_speed_percent": 45.0,
      "power_watts": 180.5
    }
  ]
}
```

**Status Codes:**
- `200 OK` - GPU metrics retrieved successfully

---

### CPU Metrics

#### `GET /api/v1/cpu`

Get CPU-specific metrics.

**Response:**
```json
{
  "timestamp": "2024-02-14T01:30:00.000000",
  "cpu_count": 16,
  "cpu_percent_per_core": [45.2, 38.1, 52.3, 41.7, ...],
  "cpu_percent_avg": 48.5,
  "cpu_freq": {
    "current": 3400.0,
    "min": 2200.0,
    "max": 4500.0
  }
}
```

**Status Codes:**
- `200 OK` - CPU metrics retrieved successfully

---

### Memory Metrics

#### `GET /api/v1/memory`

Get memory-specific metrics.

**Response:**
```json
{
  "timestamp": "2024-02-14T01:30:00.000000",
  "total_mb": 65536.0,
  "available_mb": 32768.0,
  "used_mb": 32768.0,
  "percent": 50.0,
  "swap": {
    "total_mb": 8192.0,
    "used_mb": 512.0,
    "percent": 6.25
  }
}
```

**Status Codes:**
- `200 OK` - Memory metrics retrieved successfully

---

### Optimization Recommendations

#### `GET /api/v1/optimizer/recommendations`

Get hardware optimization recommendations based on recent metrics.

**Response:**
```json
{
  "recommendations": [
    {
      "type": "thermal",
      "severity": "warning",
      "title": "High GPU Temperature",
      "message": "GPU temperature averaging 78.5°C (max 82°C). Consider improving cooling or reducing power limits.",
      "metric": 82.0
    },
    {
      "type": "vram",
      "severity": "info",
      "title": "VRAM Underutilized",
      "message": "VRAM usage at 45.2%. You have 8960MB available - consider larger batch sizes or models.",
      "metric": 45.2
    },
    {
      "type": "gpu_utilization",
      "severity": "success",
      "title": "Optimal GPU Utilization",
      "message": "GPU utilization is at optimal level (68.3%).",
      "metric": 68.3
    }
  ],
  "recommendation_count": 3,
  "critical_count": 0,
  "warning_count": 1,
  "performance_score": {
    "score": 85,
    "rating": "good",
    "factors": ["High temperature: -15"],
    "timestamp": "2024-02-14T01:30:00.000000"
  },
  "analysis_period_minutes": 30,
  "timestamp": "2024-02-14T01:30:00.000000"
}
```

**Severity Levels:**
- `critical` - Immediate action required
- `warning` - Attention needed
- `info` - Informational
- `success` - Optimal performance

**Performance Ratings:**
- `excellent` - 90-100 score
- `good` - 75-89 score
- `fair` - 60-74 score
- `poor` - 40-59 score
- `critical` - 0-39 score

**Status Codes:**
- `200 OK` - Recommendations retrieved successfully
- `500 Internal Server Error` - Optimizer not initialized

---

### Metrics History

#### `GET /api/v1/metrics/history?hours=<hours>`

Get historical metrics with aggregations.

**Query Parameters:**
- `hours` (optional, default: 1) - Number of hours to look back (1-24)

**Example Request:**
```
GET /api/v1/metrics/history?hours=2
```

**Response:**
```json
{
  "period_hours": 2,
  "data_points": 240,
  "start_time": "2024-02-13T23:30:00.000000",
  "end_time": "2024-02-14T01:30:00.000000",
  "metrics": [
    {
      "timestamp": "2024-02-13T23:30:00.000000",
      "cpu": {...},
      "memory": {...},
      "gpu": {...}
    },
    ...
  ],
  "aggregations": {
    "cpu": {
      "avg": 48.5,
      "min": 32.1,
      "max": 78.9
    },
    "memory": {
      "percent_avg": 52.3,
      "percent_min": 48.1,
      "percent_max": 58.7
    },
    "gpu": {
      "temperature": {
        "avg": 68.2,
        "min": 55.0,
        "max": 82.0
      },
      "vram_percent": {
        "avg": 45.8,
        "min": 38.2,
        "max": 56.3
      }
    }
  }
}
```

**Status Codes:**
- `200 OK` - History retrieved successfully
- `500 Internal Server Error` - Metrics collector not initialized

---

## Error Responses

All endpoints may return error responses in the following format:

```json
{
  "error": "Description of the error",
  "timestamp": "2024-02-14T01:30:00.000000"
}
```

**Common Status Codes:**
- `200 OK` - Request successful
- `400 Bad Request` - Invalid request parameters
- `500 Internal Server Error` - Server error

---

## Rate Limiting

No rate limiting is currently implemented. For production use, consider implementing rate limiting based on your requirements.

---

## CORS

CORS is enabled if `flask-cors` is installed. All origins are allowed by default. Configure in `monitor.py` for production use.

---

## Examples

### cURL

**Get all metrics:**
```bash
curl http://localhost:5000/api/v1/metrics
```

**Get GPU metrics:**
```bash
curl http://localhost:5000/api/v1/gpu
```

**Get recommendations:**
```bash
curl http://localhost:5000/api/v1/optimizer/recommendations
```

**Get 6-hour history:**
```bash
curl 'http://localhost:5000/api/v1/metrics/history?hours=6'
```

### Python

```python
import requests

# Get all metrics
response = requests.get('http://localhost:5000/api/v1/metrics')
metrics = response.json()

print(f"GPU Temp: {metrics['gpu']['gpus'][0]['temperature']}°C")
print(f"CPU Usage: {metrics['cpu']['cpu_percent_avg']:.1f}%")
print(f"Memory: {metrics['memory']['percent']:.1f}%")

# Get recommendations
response = requests.get('http://localhost:5000/api/v1/optimizer/recommendations')
recs = response.json()

for rec in recs['recommendations']:
    print(f"[{rec['severity'].upper()}] {rec['title']}: {rec['message']}")
```

### JavaScript

```javascript
// Fetch all metrics
fetch('http://localhost:5000/api/v1/metrics')
  .then(response => response.json())
  .then(data => {
    console.log('GPU Temperature:', data.gpu.gpus[0].temperature, '°C');
    console.log('CPU Usage:', data.cpu.cpu_percent_avg, '%');
    console.log('Memory:', data.memory.percent, '%');
  });

// Fetch recommendations
fetch('http://localhost:5000/api/v1/optimizer/recommendations')
  .then(response => response.json())
  .then(data => {
    data.recommendations.forEach(rec => {
      console.log(`[${rec.severity}] ${rec.title}: ${rec.message}`);
    });
  });
```

---

## Prometheus Integration

Add to `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'hardware-agent'
    scrape_interval: 30s
    static_configs:
      - targets: ['localhost:5000']
        labels:
          service: 'hardware-agent'
```

Query examples:
```promql
# GPU temperature
gpu_temperature_celsius{gpu_id="0"}

# Average CPU usage
avg(cpu_usage_percent)

# Memory usage percentage
memory_percent

# GPU VRAM usage percentage
(gpu_vram_used_mb / gpu_vram_total_mb) * 100
```

---

## Grafana Dashboard

Example dashboard queries:

**GPU Temperature Panel:**
- Query: `gpu_temperature_celsius{gpu_id="0"}`
- Visualization: Time series graph

**VRAM Usage Panel:**
- Query: `(gpu_vram_used_mb / gpu_vram_total_mb) * 100`
- Visualization: Gauge (0-100%)

**CPU Usage Panel:**
- Query: `avg(cpu_usage_percent)`
- Visualization: Time series graph

**Memory Usage Panel:**
- Query: `memory_percent`
- Visualization: Gauge (0-100%)
