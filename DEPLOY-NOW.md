# 🚀 AI Orchestration Stack - Deploy NOW

## ⚠️ PORT CHANGES (Conflict Resolution)

**Updated ports to avoid conflicts with existing services:**
- ✅ **vLLM API**: Port **8002** (was 8000, conflict with Portainer)
- ✅ **AnythingLLM UI**: Port **3002** (was 3001, conflict with GitHub Desktop)
- ✅ **Embeddings**: Port **8001** (no conflict)
- ✅ **Qdrant REST**: Port **6333** (no conflict)
- ✅ **Qdrant gRPC**: Port **6334** (no conflict)

---

## 🔐 STEP 1: Generate Security Tokens

Run these commands on your Unraid terminal:

```bash
# Generate AUTH_TOKEN
openssl rand -hex 32

# Generate JWT_SECRET  
openssl rand -hex 32
```

**Copy both outputs** - you'll need them in Step 2.

---

## 📝 STEP 2: Update the Compose File

1. Download **`ai-orchestration-stack-v2.yml`** from outputs
2. Open it in a text editor
3. Find these two lines (around line 115-116):
   ```yaml
   - AUTH_TOKEN=your-secure-auth-token-change-this
   - JWT_SECRET=your-secure-jwt-secret-change-this
   ```
4. Replace with your generated tokens from Step 1
5. Save the file

---

## 🚀 STEP 3: Deploy in Portainer

1. Open Portainer: **`http://192.168.1.222:9000`**
2. Click **Stacks** → **Add Stack**
3. Stack name: **`ai-orchestration`**
4. Choose **Upload** and select your modified `ai-orchestration-stack-v2.yml`
5. Click **Deploy the stack**

---

## ⏱️ STEP 4: Wait for Startup (3-5 minutes)

Watch the logs in Portainer. Services start in this order:

1. **Qdrant** (~30 sec) - Vector database initializes
2. **vLLM** (~2-3 min) - Loads Qwen2.5-7B model to GPU
3. **Embeddings** (~60 sec) - GPU-accelerated embedding service
4. **AnythingLLM** (~30 sec) - RAG frontend (waits for all services)

---

## ✅ STEP 5: Verify Deployment

### Check Container Status
In Portainer → Stacks → ai-orchestration:
- All 4 containers should show **green/healthy** status

### Test Each Service

**Qdrant Dashboard:**
```
http://192.168.1.222:6333/dashboard
```

**vLLM API:**
```bash
curl http://192.168.1.222:8002/v1/models
```
Should return: `{"data":[{"id":"Qwen/Qwen2.5-7B-Instruct-AWQ",...}]}`

**Embeddings:**
```bash
curl http://192.168.1.222:8001/health
```
Should return health status

**AnythingLLM:**
```
http://192.168.1.222:3002
```
Create your admin account on first visit.

---

## 🎯 Access Points Summary

| Service | URL | Purpose |
|---------|-----|---------|
| **AnythingLLM UI** | http://192.168.1.222:3002 | RAG Web Interface |
| **Qdrant Dashboard** | http://192.168.1.222:6333/dashboard | Vector DB Admin |
| **vLLM API Docs** | http://192.168.1.222:8002/docs | LLM API Documentation |
| **Embeddings** | http://192.168.1.222:8001 | Embedding Service |

---

## 🔍 First Test - Upload a Document

1. Open AnythingLLM at `http://192.168.1.222:3002`
2. Create your first workspace
3. Go to **Settings** → **LLM & Embedding** and verify:
   - ✅ LLM Provider shows "Connected" 
   - ✅ Embedding Provider shows "Connected"
   - ✅ Vector Database shows "Connected"
4. Upload a small PDF to test
5. Ask questions about the document
6. Check Qdrant dashboard to see vectors being created at `http://192.168.1.222:6333/dashboard`

---

## 📊 GPU Monitoring

Monitor GPU usage during startup:

```bash
watch -n 1 nvidia-smi
```

**Expected VRAM usage on RTX 4070 (12GB):**
- **vLLM**: ~8-9 GB (Qwen2.5-7B-AWQ quantized model)
- **Embeddings**: ~1-2 GB (gte-Qwen2-1.5B)
- **Total**: ~10-11 GB utilized

---

## 🚨 Troubleshooting

### Problem: vLLM won't start

```bash
# Check GPU availability
nvidia-smi

# Check vLLM logs for errors
docker logs ai-orchestration-vllm-1

# Verify model files exist
ls -lh /mnt/user/appdata/ai-models/models--Qwen/
```

### Problem: AnythingLLM can't connect to services

```bash
# Verify internal network exists
docker network inspect ai-orchestration_ai_internal

# Check all containers are on the network
docker ps --filter network=ai-orchestration_ai_internal

# Restart the stack if needed
```

### Problem: Qdrant storage issues

```bash
# Verify permissions on storage
ls -la /mnt/qdrant/storage/

# Should show: drwxr-xr-x nobody users
# If not, fix permissions:
chown -R 99:100 /mnt/qdrant/storage /mnt/qdrant/snapshots
chmod -R 755 /mnt/qdrant/storage /mnt/qdrant/snapshots
```

### Problem: Containers show "unhealthy"

```bash
# Check individual service health
docker inspect ai-orchestration-qdrant-1 | grep -A 10 Health
docker inspect ai-orchestration-vllm-1 | grep -A 10 Health

# View real-time logs
docker logs -f ai-orchestration-qdrant-1
```

---

## 🎬 After Successful Deployment

### 1. Test the RAG Pipeline
- Upload a technical document or PDF
- Ask specific questions about the content
- Verify answers are contextually accurate

### 2. Configure Qdrant Snapshots
- Set up automated backup schedule
- Test snapshot creation/restoration
- Document: http://192.168.1.222:6333/dashboard

### 3. Add to Homepage Dashboard
Create widgets for:
- AnythingLLM access
- Qdrant monitoring
- GPU utilization stats

### 4. Performance Tuning
- Monitor GPU memory usage patterns
- Adjust `--gpu-memory-utilization` if needed (currently 0.90)
- Optimize batch sizes based on workload

### 5. Production Hardening
- Configure reverse proxy via Nginx Proxy Manager
- Set up Prometheus/Grafana monitoring
- Implement automated Qdrant snapshot backups

---

## 📋 Quick Command Reference

```bash
# View all stack containers
docker ps --filter name=ai-orchestration

# Restart entire stack
cd /data/compose/[stack-number] && docker compose restart

# View real-time logs for specific service
docker logs -f ai-orchestration-vllm-1

# Check GPU usage
nvidia-smi

# Test vLLM API
curl http://192.168.1.222:8002/v1/models

# Check Qdrant collections
curl http://192.168.1.222:6333/collections
```

---

## ✨ You're Ready!

1. ✅ Qdrant storage prepared at `/mnt/qdrant`
2. ✅ Ports adjusted to avoid conflicts
3. ✅ Compose file ready with v2 updates
4. ✅ All models pre-downloaded

**Just generate those security tokens and deploy!** 🎯

Once running, let me know and I'll help you:
- Configure your first RAG workspace
- Optimize performance settings
- Set up automated backups
- Integrate with your existing monitoring stack
