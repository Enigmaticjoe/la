# AI Orchestration Stack - Deployment Checklist

## ✅ Pre-Deployment Complete
- [x] Qdrant dedicated storage configured at `/mnt/qdrant`
- [x] Clean directory structure (storage/ and snapshots/)
- [x] Proper permissions set (99:100)
- [x] Models downloaded:
  - Qwen2.5-7B-Instruct-AWQ (inference)
  - gte-Qwen2-1.5B-instruct (embeddings)
  - Container images pulled

## ⚠️ BEFORE DEPLOYING - CRITICAL

### 1. Update Security Tokens
Edit `ai-orchestration-stack.yml` and change these two lines:

```yaml
- AUTH_TOKEN=your-secure-auth-token-change-this
- JWT_SECRET=your-secure-jwt-secret-change-this
```

Generate secure tokens with:
```bash
openssl rand -hex 32  # For AUTH_TOKEN
openssl rand -hex 32  # For JWT_SECRET
```

### 2. Deploy in Portainer
1. Navigate to Portainer: `http://your-unraid-ip:9000`
2. Click **Stacks** → **Add Stack**
3. Name: `ai-orchestration`
4. Upload the **modified** `ai-orchestration-stack.yml`
5. Click **Deploy the stack**

## 📊 Expected Startup Sequence

| Service | Expected Time | What to Watch |
|---------|---------------|---------------|
| Qdrant | ~30 seconds | Health check on port 6333 |
| vLLM | 2-3 minutes | GPU memory allocation, model loading |
| Embeddings | ~60 seconds | GPU initialization |
| AnythingLLM | ~30 seconds | Waits for all services healthy |

## 🎯 Access Points After Deployment

- **AnythingLLM Web UI**: `http://your-unraid-ip:3001`
- **vLLM API Docs**: `http://your-unraid-ip:8000/docs`
- **Qdrant Dashboard**: `http://your-unraid-ip:6333/dashboard`

## 🔍 First Boot Validation

### 1. Check Container Status
In Portainer, verify all 4 containers show "running" with green status

### 2. Test vLLM API
```bash
curl http://your-unraid-ip:8000/v1/models
```
Should return: `Qwen/Qwen2.5-7B-Instruct-AWQ`

### 3. Test Embeddings
```bash
curl http://your-unraid-ip:8001/health
```
Should return: `{"status":"ok"}`

### 4. Test Qdrant
```bash
curl http://your-unraid-ip:6333/health
```
Should return: `{"status":"ok"}`

### 5. Access AnythingLLM
- Open `http://your-unraid-ip:3001`
- Create your admin account
- Verify LLM and embedding connections show "Connected"

## 📈 GPU Memory Monitoring

Expected GPU allocation on RTX 4070:
- **vLLM**: ~8-9GB (Qwen2.5-7B-AWQ at 90% utilization)
- **Embeddings**: ~1-2GB (gte-Qwen2-1.5B-instruct)
- **Total**: ~10-11GB of your 12GB VRAM

Monitor with:
```bash
nvidia-smi
```

## 🚨 Troubleshooting Common Issues

### vLLM fails to start
- Check GPU is available: `nvidia-smi`
- Verify model exists: `ls -lh /mnt/user/appdata/ai-models`
- Check logs: Portainer → ai-orchestration → vllm → Logs

### AnythingLLM can't connect to services
- Verify all containers are on `ai_internal` network
- Check static IPs: `docker network inspect ai-orchestration_ai_internal`
- Restart stack if needed

### Qdrant storage issues
- Verify permissions: `ls -la /mnt/qdrant/storage`
- Should show `nobody:users` ownership
- Check disk space: `df -h /mnt/qdrant`

## 🎬 Next Steps After Deployment

1. **Test RAG Pipeline**
   - Upload a small PDF to AnythingLLM
   - Ask questions about the document
   - Verify embeddings are generated in Qdrant

2. **Configure Qdrant Snapshots**
   - Set up automated snapshot schedule
   - Test backup/restore workflow

3. **Performance Tuning**
   - Monitor GPU utilization
   - Adjust `--gpu-memory-utilization` if needed
   - Optimize batch sizes for your workload

4. **Production Hardening**
   - Configure reverse proxy (Nginx Proxy Manager)
   - Set up monitoring (Grafana/Prometheus)
   - Implement automated backups

---

**Ready to deploy?** Just update those security tokens and hit deploy in Portainer!
