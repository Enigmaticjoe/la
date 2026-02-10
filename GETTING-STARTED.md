# 🚀 Getting Started - Updated Brain-Brawn Ecosystem

## What Changed?

Your stack files have been updated to match your current running Unraid deployment:

### Major Updates Applied ✅

- **vLLM**: Updated from v0.6.5 → **v0.15.1** (significant upgrade)
- **Qdrant**: Updated to **latest** version
- **TEI Embeddings**: Updated to **89-1.8**
- **Overseerr**: Changed to **develop** tag
- **Redis & MariaDB**: Updated to latest versions

### New Capabilities 🎯

1. **Brain-Brawn Integration**: Your Brawn (Unraid) server now properly integrates with Brain (primary AI server)
2. **Dual vLLM Setup**: OpenWebUI connects to both Brain and Brawn for load balancing
3. **Automated Image Sync**: New script keeps your stack files in sync with running containers
4. **Interactive Deployment**: Step-by-step guide for deploying updated stacks

## Next Steps

### Option 1: Quick Start (Recommended)

```bash
# 1. SSH into your Brawn server
ssh root@192.168.1.222

# 2. Navigate to your stacks directory
cd /mnt/user/appdata/brawn-stacks

# 3. Pull latest changes
git pull

# 4. Run the interactive deployment guide
bash scripts/automation/deploy-updated-stacks.sh
```

The interactive guide will walk you through:
- Reviewing updated images
- Configuring Brain connectivity
- Deploying each stack via Portainer
- Verifying everything works

### Option 2: Manual Deployment

1. **Access Portainer**: http://192.168.1.222:8008

2. **Update Environment File**:
   ```bash
   ssh root@192.168.1.222
   nano /mnt/user/appdata/brawn-stacks/brawn-stacks.env
   ```
   
   Add these lines:
   ```bash
   BRAIN_IP=192.168.1.9
   BRAIN_VLLM_PORT=8000
   BRAIN_OLLAMA_PORT=11434
   VLLM_API_KEY=sk-brain-primary
   BRAWN_VLLM_API_KEY=sk-brawn-local
   ```

3. **Deploy Stacks** in this order:
   - `01-core-infrastructure.yml`
   - `04-storage-stack.yml`
   - `02-media-stack.yml`
   - `03-ai-stack.yml`

4. **Verify Deployment**:
   ```bash
   bash brawn-validate.sh
   ```

## What to Expect

### After Deployment

✅ All existing services continue running
✅ Updated to latest stable versions
✅ OpenWebUI can access both Brain and Brawn vLLM
✅ Improved performance and security
✅ Better resource allocation

### Potential Issues

⚠️ **vLLM v0.15.1**: This is a major update. Models may need to reload.
- First startup may take 2-3 minutes
- VRAM usage pattern might change slightly

⚠️ **Qdrant Update**: Vector database update is generally safe
- Existing vectors are preserved
- New features available

⚠️ **Redis/MariaDB**: Update should be seamless
- Data is preserved
- Check logs for any migration notes

## Testing Your Setup

### 1. Test Individual Services

```bash
# Homepage
curl http://192.168.1.222:8010

# OpenWebUI
curl http://192.168.1.222:3000

# Plex
curl http://192.168.1.222:32400/web

# vLLM (Brawn)
curl http://192.168.1.222:8002/health
```

### 2. Test Brain Connectivity

```bash
# From Brawn, reach Brain vLLM
docker exec openwebui curl -f http://192.168.1.9:8000/health

# Should return: {"status":"ok"} or similar
```

### 3. Test AI Inference

1. Open OpenWebUI: http://192.168.1.222:3000
2. Go to Settings → Connections
3. Verify you see both:
   - Brain vLLM (192.168.1.9:8000)
   - Brawn vLLM (172.25.0.20:8000)
4. Start a chat and test inference

## Documentation

| Document | Purpose |
|----------|---------|
| **QUICK-REFERENCE.md** | Commands and quick troubleshooting |
| **BRAIN-BRAWN-INTEGRATION.md** | Complete integration guide |
| **README.md** | Overview and setup instructions |
| This file | Getting started checklist |

## Backup & Safety

✅ **Automatic Backups Created**
- Original stack files backed up to `.stack-backups/`
- Timestamped for easy rollback if needed

✅ **No Data Loss**
- All volume data preserved
- Existing configurations maintained
- Only image versions updated

## Rollback (If Needed)

If you encounter issues:

```bash
# Find your backup
ls -la .stack-backups/

# Restore a specific stack
cp .stack-backups/[timestamp]/03-ai-stack.yml ./03-ai-stack.yml

# Redeploy via Portainer
```

## Support & Help

### Get Help

1. **Check Logs**: `docker logs <service-name>`
2. **Run Validation**: `bash brawn-validate.sh`
3. **Review Docs**: Check `BRAIN-BRAWN-INTEGRATION.md`
4. **Check Quick Ref**: See `QUICK-REFERENCE.md`

### Common Commands

```bash
# Full system validation
bash brawn-validate.sh

# System maintenance
bash brawn-maintenance.sh

# View all running containers
docker ps

# Check resource usage
docker stats

# View logs for a service
docker logs -f vllm
```

## What's Next?

After successful deployment:

1. ✅ **Configure Homepage**: Add Brain services to your dashboard
2. ✅ **Set Up Monitoring**: Add Brain endpoints to Uptime Kuma
3. ✅ **Test Load Balancing**: Try AI inference and verify it uses both systems
4. ✅ **Optimize Performance**: Adjust GPU memory allocation if needed
5. ✅ **Schedule Backups**: Use the maintenance script weekly

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                    YOUR ECOSYSTEM                             │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌────────────────┐              ┌─────────────────┐        │
│  │ BRAIN          │◄────────────►│ BRAWN (Unraid)  │        │
│  │ 192.168.1.9    │   Network    │ 192.168.1.222   │        │
│  ├────────────────┤              ├─────────────────┤        │
│  │ • vLLM Primary │              │ • vLLM Aux      │        │
│  │ • Ollama       │              │ • OpenWebUI     │        │
│  │ • Training     │              │ • Plex/Jellyfin │        │
│  │                │              │ • Storage       │        │
│  └────────────────┘              │ • Monitoring    │        │
│         ▲                         │ • *arr Stack    │        │
│         │                         └─────────────────┘        │
│         │                                  ▲                  │
│         │     OpenWebUI uses both        │                  │
│         └──────────────────────────────────┘                  │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Success Checklist

- [ ] Pulled latest code from git
- [ ] Reviewed updated image versions
- [ ] Updated brawn-stacks.env with Brain IP
- [ ] Deployed all stacks via Portainer
- [ ] Ran brawn-validate.sh successfully
- [ ] Tested Brain connectivity
- [ ] Verified OpenWebUI sees both vLLM endpoints
- [ ] Tested AI inference
- [ ] All media services working
- [ ] Monitoring services operational

---

**Ready to Deploy?**

Run: `bash scripts/automation/deploy-updated-stacks.sh`

**Questions?**

See: `BRAIN-BRAWN-INTEGRATION.md` for detailed documentation

---

*Last Updated: 2026-02-10*  
*Stack Version: vLLM v0.15.1 | Qdrant latest | TEI 89-1.8*
