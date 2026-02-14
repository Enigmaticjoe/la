# 🚀 Brain AI Dashboard - Quick Start Guide

## Step 1: Navigate to Dashboard Directory
```bash
cd /home/runner/work/la/la/brain-project/services/dashboard
```

## Step 2: Build the Docker Image
```bash
docker build -t brain-dashboard:latest .
```

Expected output:
```
Successfully built [image-id]
Successfully tagged brain-dashboard:latest
```

## Step 3: Run the Dashboard
```bash
docker run -d \
  --name brain-dashboard \
  -p 8080:80 \
  --restart unless-stopped \
  brain-dashboard:latest
```

## Step 4: Access the Dashboard
Open your browser and go to:
- **Local:** http://localhost:8080
- **Network:** http://10.111.222.41:8080 (replace with your server IP)

## Step 5: Configure Service Endpoints
Edit `config.js` and update the service IPs to match your setup:

```javascript
services: [
  {
    id: 'vllm',
    endpoint: 'http://YOUR_SERVER_IP:8000/health',
    url: 'http://YOUR_SERVER_IP:8000',
    // ...
  },
  // ... other services
]
```

After editing, rebuild and restart:
```bash
docker stop brain-dashboard
docker rm brain-dashboard
docker build -t brain-dashboard:latest .
docker run -d --name brain-dashboard -p 8080:80 --restart unless-stopped brain-dashboard:latest
```

## Alternative: Docker Compose Integration

### Option A: Standalone
```bash
# Use the example compose file
cd brain-project/services/dashboard
docker compose -f docker-compose.example.yml up -d
```

### Option B: Add to Existing Compose
Add this to your main `docker-compose.yml`:

```yaml
services:
  dashboard:
    build: ./services/dashboard
    container_name: brain-dashboard
    ports:
      - "8080:80"
    networks:
      - brain-network
    restart: unless-stopped
```

Then run:
```bash
docker compose up -d dashboard
```

## Verify Installation

### Check Container Status
```bash
docker ps | grep brain-dashboard
```

Expected output:
```
CONTAINER ID   IMAGE                    ...   STATUS         PORTS                  NAMES
abc123def456   brain-dashboard:latest   ...   Up 30 seconds  0.0.0.0:8080->80/tcp  brain-dashboard
```

### Check Logs
```bash
docker logs brain-dashboard
```

Expected output (Nginx logs):
```
/docker-entrypoint.sh: Configuration complete; ready for start up
```

### Test Health Endpoint
```bash
curl http://localhost:8080/health
```

Expected output:
```
OK
```

## What You Should See

When you open the dashboard in your browser:

### ✅ Working Dashboard
- Dark cyberpunk-themed interface
- "BRAIN AI SYSTEM" header with glowing text
- Current time displayed
- 4 metric cards (GPU, VRAM, CPU, RAM)
- 7 service cards showing status
- Footer with refresh controls

### ⚠️ Initial State
Since services aren't configured yet, you'll see:
- Services showing "OFFLINE" status (red badges)
- Metrics showing "--" or mock data
- Alert: "vLLM Inference is offline" (etc.)

**This is normal!** The dashboard is working, it's just waiting for you to:
1. Update service endpoints in `config.js`
2. Ensure services are running
3. Rebuild the container

## Troubleshooting

### Dashboard Not Loading
```bash
# Check if container is running
docker ps -a | grep brain-dashboard

# Check logs for errors
docker logs brain-dashboard

# Verify port isn't in use
netstat -an | grep 8080

# Restart container
docker restart brain-dashboard
```

### Services Show Offline
1. **Check service endpoints** - Edit `config.js` with correct IPs
2. **Verify services are running** - `docker ps` or check service logs
3. **Test connectivity** - `curl http://SERVICE_IP:PORT/health`
4. **Check CORS** - Services must allow CORS requests
5. **Rebuild after config changes** - Dashboard uses static files

### Metrics Not Updating
1. **Enable mock data** - Set `useMockData: true` in `config.js` for testing
2. **Check hardware agent** - Metrics require hardware agent API
3. **Verify endpoints** - Check `config.metrics` endpoints are correct
4. **Browser console** - Open DevTools (F12) and check for errors

### Can't Access from Network
```bash
# Check if port is exposed
docker port brain-dashboard

# Test from server
curl http://localhost:8080

# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp

# Verify network binding
netstat -an | grep 8080
```

## Common Commands

### View Logs
```bash
docker logs -f brain-dashboard
```

### Restart Dashboard
```bash
docker restart brain-dashboard
```

### Update Configuration
```bash
# 1. Edit config
nano config.js

# 2. Rebuild
docker build -t brain-dashboard:latest .

# 3. Stop old container
docker stop brain-dashboard && docker rm brain-dashboard

# 4. Start new container
docker run -d --name brain-dashboard -p 8080:80 --restart unless-stopped brain-dashboard:latest
```

### Stop and Remove
```bash
docker stop brain-dashboard
docker rm brain-dashboard
```

### Remove Image
```bash
docker rmi brain-dashboard:latest
```

## Performance Tips

1. **Enable Caching** - Already enabled in nginx.conf
2. **Use HTTP/2** - Add SSL certificate for better performance
3. **Optimize Refresh** - Increase intervals in config.js if needed
4. **Disable Mock Data** - Set `useMockData: false` in production

## Next Steps

1. ✅ Dashboard is running
2. 📝 Update `config.js` with your service IPs
3. 🔧 Ensure all AI services are running
4. 🔄 Rebuild and restart dashboard
5. 📊 Monitor your AI system in real-time!

## Support

For issues or questions:
- Check the main README.md
- Review nginx logs: `docker logs brain-dashboard`
- Check browser console for JavaScript errors
- Verify service health endpoints manually with `curl`

---

**Enjoy your beautiful Brain AI Dashboard! 🧠✨**
