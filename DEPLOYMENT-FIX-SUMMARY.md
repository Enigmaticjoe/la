# Brain Stack Deployment - Fix Summary

## Issue Fixed
**Error**: "Failed to deploy a stack: compose up operation failed: dependency failed to start: container brain-embeddings is unhealthy"

## Root Cause
The `brain-embeddings` container was being marked as unhealthy during Portainer deployment because:

1. **Model Download Time**: The TEI (Text Embeddings Inference) service downloads the Qwen3-Embedding-0.6B model (~1.2GB) on first startup
2. **Insufficient Grace Period**: The healthcheck `start_period` was set to 120 seconds (2 minutes), but model download + initialization takes 3-5 minutes on typical networks
3. **Healthcheck Failure**: Docker marked the container as unhealthy before the model finished downloading, causing dependent services (OpenWebUI) to fail

## Changes Made

### 1. brain-stack.yml Healthcheck Fixes

#### Embeddings Service
- **Changed**: `start_period: 120s` → `start_period: 300s` (5 minutes)
- **Reason**: Allows sufficient time for the 1.2GB model to download and load into memory
- **Location**: Line 228

#### OpenWebUI Service  
- **Changed**: `test: ["CMD", "curl", "-f", "http://localhost:8080/"]` → `test: ["CMD", "curl", "-f", "http://localhost:8080/health"]`
- **Reason**: Use proper health endpoint instead of home page
- **Changed**: `start_period: 30s` → `start_period: 60s`
- **Reason**: More reliable startup, especially when waiting for dependencies
- **Location**: Lines 293, 297

#### Documentation in brain-stack.yml
- Added comprehensive header explaining deployment methods (Docker Compose vs Portainer)
- Added healthcheck timing information for all services
- Added warnings about prerequisites (brain-setup.sh must run first)

### 2. New Documentation Files

#### PORTAINER-DEPLOY.md (450+ lines)
Complete step-by-step guide covering:
- ✅ System and software prerequisites
- ✅ Pre-deployment setup (directories, configs, models)
- ✅ Three methods for Portainer deployment
- ✅ Service verification steps
- ✅ Detailed troubleshooting for 6 common issues
- ✅ Security hardening recommendations
- ✅ Resource monitoring guidance
- ✅ Next steps and production readiness

#### BRAIN-TROUBLESHOOTING.md (200+ lines)
Quick reference card with:
- ✅ Expected startup times for each service
- ✅ Health check commands
- ✅ 7 common issues with step-by-step fixes
- ✅ Complete restart procedures
- ✅ Log access commands
- ✅ Resource monitoring commands

#### README.md Updates
- ✅ Reorganized files section to separate Brawn and Brain stacks
- ✅ Added references to new documentation
- ✅ Highlighted brain-stack deployment guides

## Expected Behavior After Fix

### Startup Timeline (First Deployment)

| Time | Service | Status | What's Happening |
|------|---------|--------|------------------|
| 0:00 | All | Starting | Portainer creates network, pulls images |
| 0:15 | SearXNG | Healthy | Lightweight service, quick start |
| 0:30 | Qdrant | Healthy | Database initialized |
| 0:30-4:00 | vLLM | Starting | Loading 8B model to GPU (~16GB VRAM) |
| 0:30-5:00 | Embeddings | Starting | Downloading Qwen3-Embedding-0.6B (~1.2GB) |
| 4:00 | vLLM | Healthy | Model loaded, API ready |
| 5:00 | Embeddings | Healthy | Model downloaded and loaded |
| 5:00-6:00 | OpenWebUI | Starting | Waiting for all dependencies |
| 6:00 | OpenWebUI | Healthy | Full stack operational |

**Total First Deployment**: ~5-10 minutes (includes model downloads)

### Subsequent Deployments

| Service | Start Time | Notes |
|---------|------------|-------|
| SearXNG | 15s | Config already exists |
| Qdrant | 20s | Database already initialized |
| vLLM | 2-3 min | Model cached, only needs GPU loading |
| Embeddings | 30-60s | Model cached, quick load |
| OpenWebUI | 30-60s | Dependencies ready quickly |

**Total Subsequent Deployments**: ~3-4 minutes

## Verification Steps

### 1. Check Container Health Status
```bash
docker ps --filter name=brain- --format "table {{.Names}}\t{{.Status}}"
```

All should show `(healthy)` after startup period.

### 2. Test Individual Services
```bash
# Replace with your Brain IP
BRAIN_IP="192.168.1.9"

# Test each service
curl http://$BRAIN_IP:6333/healthz    # Qdrant
curl http://$BRAIN_IP:8000/v1/models  # vLLM
curl http://$BRAIN_IP:8001/health     # Embeddings
curl http://$BRAIN_IP:8888/healthz    # SearXNG
curl http://$BRAIN_IP:3000/health     # OpenWebUI
```

### 3. Access OpenWebUI
Open browser: `http://BRAIN_IP:3000`
- Create admin account
- Verify LLM connection in settings
- Test document upload and RAG

## Files Changed

```
brain-stack.yml              ← Fixed healthchecks, added documentation
PORTAINER-DEPLOY.md          ← NEW: Complete deployment guide
BRAIN-TROUBLESHOOTING.md     ← NEW: Quick troubleshooting reference
README.md                    ← Updated file organization
```

## Deployment Instructions

### For First-Time Deployment

1. **Run Setup Script**:
   ```bash
   bash brain-setup.sh
   ```
   This creates directories, generates configs, validates prerequisites.

2. **Deploy via Portainer**:
   - Open Portainer: http://YOUR_IP:9000
   - Stacks → Add Stack → Upload `brain-stack.yml`
   - Deploy and wait 5-10 minutes

3. **Monitor Startup**:
   ```bash
   watch -n 2 "docker ps --filter name=brain- --format 'table {{.Names}}\t{{.Status}}'"
   ```

4. **Verify Health**:
   All containers should show `(healthy)` status after startup period.

### For Existing Deployments

If you've already deployed and are experiencing the "unhealthy" error:

1. **Update the Stack**:
   - In Portainer: Stacks → brain-stack → Editor
   - Replace with updated brain-stack.yml
   - Click "Update the stack"
   - Enable "Re-pull images and redeploy"

2. **Wait for Startup**:
   - Monitor logs in Portainer
   - Wait full 5 minutes for embeddings
   - Don't restart if status shows `(health: starting)`

3. **Verify**:
   - Check all containers are healthy
   - Test services with curl commands
   - Access OpenWebUI at port 3000

## Troubleshooting

### If Embeddings Still Unhealthy After 5 Minutes

1. **Check Logs**:
   ```bash
   docker logs brain-embeddings
   ```

2. **Look For**:
   - "Downloading model" → Normal, be patient
   - "Model loaded" → Success
   - "Error downloading" → Network or disk issue

3. **Common Fixes**:
   ```bash
   # Ensure directory exists
   mkdir -p /home/brains/embeddings-cache
   chmod 755 /home/brains/embeddings-cache
   
   # Restart container
   docker restart brain-embeddings
   
   # Wait 5 minutes and check again
   ```

### If vLLM Unhealthy

1. **Check GPU**:
   ```bash
   rocm-smi
   ls /dev/kfd /dev/dri/render*
   ```

2. **Check Logs**:
   ```bash
   docker logs brain-vllm | tail -50
   ```

3. **Look For**:
   - GPU errors → ROCm issue
   - Out of memory → Reduce gpu-memory-utilization
   - Model loading → Normal, be patient

## References

- **Full Deployment Guide**: See `PORTAINER-DEPLOY.md`
- **Quick Troubleshooting**: See `BRAIN-TROUBLESHOOTING.md`
- **Integration Guide**: See `BRAIN-BRAWN-INTEGRATION.md`
- **Setup Script**: Run `bash brain-setup.sh`

## Testing Checklist

- [ ] brain-stack.yml is valid YAML
- [ ] All healthcheck start_period values are adequate
- [ ] All healthcheck endpoints are correct
- [ ] Documentation is comprehensive
- [ ] Troubleshooting covers common issues
- [ ] Deployment instructions are clear
- [ ] Prerequisites are documented

## Next Steps

1. **Test the Fix**: Deploy brain-stack via Portainer and verify all containers become healthy
2. **Document Results**: Note actual startup times on your hardware
3. **Share Knowledge**: Update team on the healthcheck timing requirements
4. **Monitor**: Watch for any other deployment issues
5. **Iterate**: Adjust healthcheck timings if needed based on real-world performance

---

**Fix Date**: 2026-02-10  
**Issue**: Brain-embeddings unhealthy during Portainer deployment  
**Resolution**: Increased healthcheck start_period from 120s to 300s  
**Status**: ✅ Ready for deployment testing
