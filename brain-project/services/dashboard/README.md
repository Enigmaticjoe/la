# 🧠 Brain AI System Dashboard

A beautiful, modern cyberpunk-themed web dashboard for monitoring the Brain AI System infrastructure.

## Features

### 🎨 Visual Design
- **Dark cyberpunk theme** with neon accents (cyan, green, purple)
- **Glassmorphism effects** with blur and transparency
- **Animated backgrounds** with twinkling stars
- **Smooth transitions** and hover effects
- **Responsive design** for all screen sizes

### 📊 Real-Time Monitoring
- **Service health checks** for all AI components
- **GPU metrics** (temperature, VRAM usage)
- **System metrics** (CPU, RAM usage)
- **Auto-refresh** every 5 seconds
- **Status indicators** (online/offline/degraded)

### 🚀 Services Tracked
1. **vLLM Inference** - Large Language Model engine
2. **Qdrant Vector DB** - Vector database for embeddings
3. **Embeddings Service** - Text embedding generation
4. **SearXNG Search** - Privacy-focused search
5. **Open WebUI** - Web interface
6. **Coding Agent** - AI code assistant
7. **Hardware Agent** - System monitoring

### ⚡ Features
- Service latency tracking
- Threshold-based alerts
- System uptime display
- Network I/O monitoring
- Manual refresh button
- Direct links to services

## Deployment

### Docker Build
```bash
cd /home/runner/work/la/la/brain-project/services/dashboard
docker build -t brain-dashboard:latest .
```

### Docker Run
```bash
docker run -d \
  --name brain-dashboard \
  -p 8080:80 \
  --restart unless-stopped \
  brain-dashboard:latest
```

### Docker Compose
Add to your `docker-compose.yml`:

```yaml
services:
  dashboard:
    build: ./services/dashboard
    container_name: brain-dashboard
    ports:
      - "8080:80"
    restart: unless-stopped
    networks:
      - brain-network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
```

## Configuration

Edit `config.js` to customize:

### Service Endpoints
Update the IP addresses and ports for your services:
```javascript
services: [
  {
    id: 'vllm',
    endpoint: 'http://YOUR_IP:8000/health',
    url: 'http://YOUR_IP:8000',
    // ...
  }
]
```

### Refresh Intervals
```javascript
refreshIntervals: {
  services: 5000,    // Service health checks
  metrics: 5000,     // GPU/System metrics
  systemInfo: 30000  // System information
}
```

### Alert Thresholds
```javascript
thresholds: {
  gpuTemp: { warning: 75, critical: 85 },
  vramUsage: { warning: 80, critical: 95 },
  cpuUsage: { warning: 80, critical: 95 },
  ramUsage: { warning: 85, critical: 95 }
}
```

### Theme Colors
```javascript
theme: {
  primaryColor: '#00ff9f',    // Neon green
  secondaryColor: '#00d4ff',  // Neon cyan
  dangerColor: '#ff006e',     // Neon pink
  warningColor: '#ffbe0b'     // Neon yellow
}
```

## Development

### Mock Data
For testing without backend services, enable mock data:
```javascript
useMockData: true
```

### Local Testing
```bash
# Serve files locally
python3 -m http.server 8080

# Or use Node.js
npx http-server -p 8080
```

## API Endpoints Expected

The dashboard expects these endpoints:

### Service Health
- `GET /health` - Returns 200 OK if service is healthy

### Metrics (Hardware Agent)
- `GET /api/gpu` - GPU metrics
  ```json
  {
    "temperature": 72,
    "vramUsed": 12,
    "vramTotal": 24
  }
  ```

- `GET /api/system` - System metrics
  ```json
  {
    "cpu": 45,
    "ramUsed": 24,
    "ramTotal": 64
  }
  ```

## Troubleshooting

### Services showing offline
1. Check service endpoints in `config.js`
2. Verify CORS is enabled on backend services
3. Check network connectivity
4. Enable mock data for testing

### Metrics not updating
1. Verify hardware agent is running
2. Check metric endpoints in `config.js`
3. Look for errors in browser console
4. Verify API timeout settings

### Dashboard not loading
1. Check Nginx logs: `docker logs brain-dashboard`
2. Verify port 8080 is not in use
3. Check file permissions
4. Rebuild container

## Browser Compatibility

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Opera 76+

## Performance

- **Lightweight**: ~50KB total assets
- **Fast loading**: < 1 second on modern connections
- **Optimized**: Gzip compression enabled
- **Cached**: Static assets cached for 1 day

## Security

- X-Frame-Options header
- X-Content-Type-Options header
- X-XSS-Protection header
- No sensitive data in frontend
- CORS-aware API calls

## License

Part of the Brain AI System project.

## Support

For issues or questions, check the main project documentation or create an issue.

---

**Made with 💚 for the Brain AI System**
