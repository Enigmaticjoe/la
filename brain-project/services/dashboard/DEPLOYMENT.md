# 🚀 Brain AI Dashboard - Deployment Checklist

## Pre-Deployment ✓

- [x] All files created and committed
- [x] Docker build tested successfully
- [x] Documentation complete
- [x] Design specification documented
- [ ] Service endpoints configured in config.js
- [ ] Network access verified

## Files Created (10 total)

```
✅ Dockerfile                     - Container definition
✅ nginx.conf                     - Web server config
✅ index.html (180 lines)         - Dashboard UI
✅ config.js (100 lines)          - Configuration
✅ styles.css (450 lines)         - Cyberpunk styling
✅ app.js (550 lines)             - Dashboard logic
✅ README.md (200 lines)          - Documentation
✅ QUICKSTART.md (250 lines)      - Deployment guide
✅ DESIGN.md (350 lines)          - Design specs
✅ docker-compose.example.yml     - Integration example
```

**Total: 2,388 lines of code**

## Configuration Steps

### 1. Update Service Endpoints
Edit `/home/runner/work/la/la/brain-project/services/dashboard/config.js`:

```javascript
services: [
  {
    endpoint: 'http://YOUR_IP:8000/health',  // ← Change this
    url: 'http://YOUR_IP:8000',              // ← Change this
  },
  // ... repeat for all 7 services
]
```

**Services to configure:**
- [ ] vLLM (port 8000)
- [ ] Qdrant (port 6333)
- [ ] Embeddings (port 11434)
- [ ] SearXNG (port 8080)
- [ ] Open WebUI (port 3000)
- [ ] Coding Agent (port 8001)
- [ ] Hardware Agent (port 8002)

### 2. Update Metrics Endpoints (if using Hardware Agent)
```javascript
metrics: {
  gpu: 'http://YOUR_IP:8002/api/gpu',
  system: 'http://YOUR_IP:8002/api/system',
  stats: 'http://YOUR_IP:8002/api/stats'
}
```

### 3. Adjust Settings (Optional)
```javascript
// Refresh rates (milliseconds)
refreshIntervals: {
  services: 5000,    // 5 seconds
  metrics: 5000,     // 5 seconds
  systemInfo: 30000  // 30 seconds
}

// Alert thresholds
thresholds: {
  gpuTemp: { warning: 75, critical: 85 },
  vramUsage: { warning: 80, critical: 95 },
  cpuUsage: { warning: 80, critical: 95 },
  ramUsage: { warning: 85, critical: 95 }
}

// Development mode
useMockData: false  // Set to true for testing
```

## Deployment Steps

### Option 1: Standalone Docker

```bash
# 1. Navigate to dashboard directory
cd /home/runner/work/la/la/brain-project/services/dashboard

# 2. Build the image
docker build -t brain-dashboard:latest .

# 3. Run the container
docker run -d \
  --name brain-dashboard \
  -p 8080:80 \
  --restart unless-stopped \
  brain-dashboard:latest

# 4. Verify it's running
docker ps | grep brain-dashboard

# 5. Check logs
docker logs brain-dashboard

# 6. Test access
curl http://localhost:8080/health
```

### Option 2: Docker Compose

```bash
# 1. Add to your docker-compose.yml (see docker-compose.example.yml)

# 2. Start the dashboard
docker compose up -d dashboard

# 3. Check status
docker compose ps dashboard

# 4. View logs
docker compose logs -f dashboard
```

### Option 3: Portainer

1. Navigate to Portainer UI
2. Go to Stacks → Add Stack
3. Name: `brain-dashboard`
4. Use docker-compose.example.yml content
5. Deploy the stack
6. Verify in Containers list

## Post-Deployment Verification

### 1. Container Health
```bash
# Check container status
docker ps | grep brain-dashboard

# Expected: STATUS shows "Up X seconds/minutes (healthy)"
```

### 2. Web Access
```bash
# Local test
curl http://localhost:8080

# Network test (from another machine)
curl http://YOUR_SERVER_IP:8080

# Health endpoint
curl http://YOUR_SERVER_IP:8080/health
# Expected: OK
```

### 3. Browser Access
- [ ] Open http://localhost:8080 (or YOUR_IP:8080)
- [ ] Dashboard loads with dark theme
- [ ] Header shows "BRAIN AI SYSTEM"
- [ ] Clock updates every second
- [ ] Metric cards visible
- [ ] Service cards visible (may show offline initially)

### 4. Functionality Check
- [ ] Metrics update (GPU, VRAM, CPU, RAM)
- [ ] Service status updates every 5 seconds
- [ ] Refresh button works
- [ ] Service links open correctly
- [ ] Alerts appear when services offline
- [ ] No JavaScript errors in console (F12)

## Troubleshooting

### Dashboard Not Loading
```bash
# Check if container is running
docker ps -a | grep brain-dashboard

# Check logs for errors
docker logs brain-dashboard

# Verify port mapping
docker port brain-dashboard
# Should show: 80/tcp -> 0.0.0.0:8080

# Restart container
docker restart brain-dashboard
```

### Services Show Offline
1. **Verify service IPs in config.js**
2. **Check if services are running:**
   ```bash
   docker ps | grep -E "vllm|qdrant|ollama|searxng"
   ```
3. **Test service endpoints manually:**
   ```bash
   curl http://YOUR_IP:8000/health  # vLLM
   curl http://YOUR_IP:6333/health  # Qdrant
   curl http://YOUR_IP:11434/api/tags  # Embeddings
   ```
4. **Enable mock data for testing:**
   - Set `useMockData: true` in config.js
   - Rebuild container

### Metrics Not Updating
1. **Check Hardware Agent:**
   ```bash
   curl http://YOUR_IP:8002/api/gpu
   curl http://YOUR_IP:8002/api/system
   ```
2. **Enable mock data:**
   - Set `useMockData: true` in config.js
3. **Check browser console (F12)** for errors

### Port Already in Use
```bash
# Check what's using port 8080
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep 8080

# Use different port
docker run -d -p 8081:80 --name brain-dashboard brain-dashboard:latest
```

## Firewall Configuration

If accessing from network:

```bash
# Allow port 8080
sudo ufw allow 8080/tcp

# Or for specific IP
sudo ufw allow from YOUR_CLIENT_IP to any port 8080

# Check firewall status
sudo ufw status
```

## Updating the Dashboard

### Update Configuration Only
```bash
# 1. Edit config.js
nano config.js

# 2. Rebuild and restart
docker stop brain-dashboard
docker rm brain-dashboard
docker build -t brain-dashboard:latest .
docker run -d --name brain-dashboard -p 8080:80 --restart unless-stopped brain-dashboard:latest
```

### Update Code/Styling
```bash
# 1. Edit files (index.html, styles.css, app.js)
# 2. Rebuild container (same as above)
```

## Monitoring

### View Real-Time Logs
```bash
docker logs -f brain-dashboard
```

### Monitor Container Resources
```bash
docker stats brain-dashboard
```

### Check Health Status
```bash
docker inspect brain-dashboard | grep -A 5 Health
```

## Backup

```bash
# Backup configuration
cp config.js config.js.backup

# Export container
docker export brain-dashboard > brain-dashboard-backup.tar
```

## Uninstall

```bash
# Stop and remove container
docker stop brain-dashboard
docker rm brain-dashboard

# Remove image
docker rmi brain-dashboard:latest

# Remove files (careful!)
# rm -rf /home/runner/work/la/la/brain-project/services/dashboard
```

## Integration with Brain AI System

### Required Services
For full functionality, ensure these are running:
- [x] vLLM Inference Engine
- [x] Qdrant Vector Database
- [x] Embeddings Service (Ollama)
- [x] SearXNG Search Engine
- [x] Open WebUI
- [ ] Coding Agent (optional)
- [ ] Hardware Agent (optional, for metrics)

### Network Configuration
All services should be on the same Docker network:
```yaml
networks:
  brain-network:
    driver: bridge
```

## Success Criteria

✅ Dashboard accessible at http://YOUR_IP:8080
✅ Container status shows "healthy"
✅ All configured services show status (online/offline)
✅ Metrics update every 5 seconds
✅ No errors in browser console
✅ Manual refresh button works
✅ Service links open correctly

## Production Considerations

### SSL/HTTPS (Recommended)
1. Add SSL certificate to nginx
2. Redirect HTTP to HTTPS
3. Update service links to HTTPS

### Authentication (Optional)
1. Add nginx basic auth
2. Or use reverse proxy (Traefik, Nginx Proxy Manager)

### Performance
- Monitor container resources
- Adjust refresh intervals if needed
- Enable caching (already configured)

### Security
- Keep container updated
- Use private network only
- Enable firewall rules
- Regular security audits

## Next Steps

1. [x] Deploy dashboard
2. [ ] Configure all service endpoints
3. [ ] Verify all services are reachable
4. [ ] Monitor for a day
5. [ ] Adjust thresholds as needed
6. [ ] Add SSL if external access needed
7. [ ] Set up alerts/notifications (future)

---

**Deployment Date:** _______________
**Deployed By:** _______________
**Server IP:** _______________
**Dashboard URL:** http://_______:8080

---

🎉 **Happy Monitoring!** 🧠✨
