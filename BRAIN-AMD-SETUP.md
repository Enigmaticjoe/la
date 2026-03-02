# 🔥 AMD ROCm Setup Guide for Brain Node
## Dolphin 2.9.3 Llama 3.1 8B AWQ on RX 7900 XT

This guide provides complete setup instructions for running AWQ-quantized LLM models on AMD Radeon RX 7900 XT using ROCm and vLLM.

---

## 📋 System Specifications

- **GPU**: AMD Radeon RX 7900 XT (20GB VRAM, gfx1100 architecture)
- **CPU**: Intel Core i9-285K or similar high-end processor
- **RAM**: 128GB DDR5
- **OS**: Fedora 44 COSMIC (recommended) / Ubuntu 24.04 LTS / Ubuntu 22.04 LTS (or Ubuntu-based Linux)
- **Target Model**: Dolphin 2.9.3 Llama 3.1 8B AWQ (~5-6GB quantized)

---

## 🚀 Quick Start

```bash
# 1. Install ROCm (if not already installed)
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main" | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-hip-sdk rocm-libs rocm-smi-lib

# 2. Set environment variables
sudo tee -a /etc/environment <<EOF
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCM_PATH=/opt/rocm
HIP_VISIBLE_DEVICES=0
EOF

# 3. Reboot to apply changes
sudo reboot

# 4. Verify ROCm installation
rocm-smi
rocminfo | grep gfx1100

# 5. Run brain setup
bash brain-setup.sh

# 6. Download models
bash brain-model-downloader.sh

# 7. Deploy stack
docker compose -f brain-stack.yml up -d
```

---

## 📦 Prerequisites Installation

### 1. ROCm Installation (Detailed)

**For Fedora 44 COSMIC (DNF/RPM):**

```bash
# Add ROCm repository (Fedora 44 COSMIC)
sudo dnf install -y https://repo.radeon.com/rocm/rhel/6.x/main/rocm.repo || \
  sudo dnf config-manager add-repo https://repo.radeon.com/amdgpu/latest/rhel/9.4/amdgpu.repo
sudo dnf install -y rocm-hip-sdk rocm-dev rocm-smi-lib rocm-opencl
```

**For Ubuntu 22.04 / Ubuntu 24.04:**

```bash
# Add ROCm repository (Ubuntu 24.04 Noble / 22.04 Jammy)
sudo mkdir --parents --mode=0755 /etc/apt/keyrings
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/rocm.gpg > /dev/null

# For Ubuntu 24.04 (Noble):
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest noble main" | \
    sudo tee /etc/apt/sources.list.d/rocm.list

# OR for Ubuntu 22.04 (Jammy):
# echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/latest jammy main" | \
#     sudo tee /etc/apt/sources.list.d/rocm.list

# Update and install ROCm
sudo apt update
sudo apt install -y rocm-hip-sdk rocm-libs rocm-smi-lib

# Add user to render and video groups
sudo usermod -aG render,video $USER

# Verify installation
ls /opt/rocm
ls /dev/dri
ls /dev/kfd
```

**Expected Output:**
- `/opt/rocm` should contain ROCm installation
- `/dev/dri/renderD128` (or similar) should exist
- `/dev/kfd` should exist (Kernel Fusion Driver)

### 2. Environment Variables

**Critical ROCm Environment Variables for RX 7900 XT (gfx1100):**

```bash
# Add to /etc/environment (system-wide, recommended)
sudo tee -a /etc/environment <<EOF
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCM_PATH=/opt/rocm
HIP_VISIBLE_DEVICES=0
PYTORCH_ROCM_ARCH=gfx1100
HIP_FORCE_DEV_KERNARG=1
EOF
```

**OR add to ~/.bashrc (user-specific):**

```bash
cat >> ~/.bashrc <<EOF

# ROCm for AMD RX 7900 XT
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export PYTORCH_ROCM_ARCH=gfx1100
export HIP_FORCE_DEV_KERNARG=1
EOF

source ~/.bashrc
```

**Explanation:**
- `HSA_OVERRIDE_GFX_VERSION=11.0.0`: Maps gfx1100 (RX 7900 XT) to supported architecture
- `ROCM_PATH=/opt/rocm`: Points to ROCm installation directory
- `HIP_VISIBLE_DEVICES=0`: Uses first AMD GPU (if multiple GPUs)
- `PYTORCH_ROCM_ARCH=gfx1100`: Specifies RX 7900 XT architecture
- `HIP_FORCE_DEV_KERNARG=1`: Performance optimization for kernel arguments

### 3. Python Environment Setup

**Install Python dependencies:**

```bash
# Install pip if not present
sudo apt install python3-pip python3-venv

# Create virtual environment (optional but recommended)
python3 -m venv ~/venv-brain
source ~/venv-brain/bin/activate

# Install HuggingFace CLI with fast transfer support
pip install -U huggingface_hub[hf_transfer]

# Optional: Install additional tools
pip install -U transformers torch accelerate bitsandbytes
```

**For faster model downloads:**

```bash
# Enable hf_transfer (already in brain-model-downloader.sh)
export HF_HUB_ENABLE_HF_TRANSFER=1
```

### 4. Docker Configuration for ROCm

**Ensure Docker can access AMD GPU:**

```bash
# Verify Docker sees GPU devices
ls -la /dev/kfd /dev/dri/render*

# Test ROCm in Docker
docker run --rm -it \
    --device=/dev/kfd --device=/dev/dri \
    rocm/pytorch:latest \
    rocm-smi

# Should display your RX 7900 XT
```

---

## 🧠 Model Configuration

### Dolphin 2.9.3 Llama 3.1 8B AWQ

**Model Details:**
- **Repository**: `cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ`
- **Quantization**: AWQ 4-bit (Auto-Weight Quantization)
- **Original Size**: ~16GB (FP16)
- **Quantized Size**: ~5-6GB (AWQ)
- **Parameters**: 8 billion
- **Context Length**: 8K default, 16K configured in brain-stack.yml

**Why AWQ for AMD?**
- ✅ **Efficient**: 4-bit quantization → ~70% VRAM reduction
- ✅ **Fast**: Optimized kernels for inference speed
- ✅ **Quality**: Minimal accuracy loss vs FP16
- ✅ **Compatible**: Works with vLLM on ROCm

### Download the Model

**Option 1: Using brain-model-downloader.sh (Recommended)**

```bash
bash brain-model-downloader.sh
```

This script:
- Validates system prerequisites
- Downloads model with proper flags
- Optimizes for AMD GPU
- Provides detailed progress output

**Option 2: Manual huggingface-cli**

```bash
# Install HuggingFace CLI
pip install -U huggingface_hub[hf_transfer]

# Download model
huggingface-cli download \
    cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
    --local-dir /home/brains/ai-models/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ \
    --local-dir-use-symlinks False \
    --resume-download
```

**Flags Explained:**
- `--local-dir`: Specifies exact download location (vLLM compatible)
- `--local-dir-use-symlinks False`: Downloads actual files instead of symlinks
- `--resume-download`: Resumes if interrupted

---

## ⚙️ vLLM Configuration for AMD

### GPU Memory Configuration

**brain-stack.yml vLLM settings:**

```yaml
environment:
  - HSA_OVERRIDE_GFX_VERSION=11.0.0
  - ROCM_PATH=/opt/rocm
  - PYTORCH_ROCM_ARCH=gfx1100
  - HIP_VISIBLE_DEVICES=0
  
command:
  - --model
  - cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ
  - --quantization
  - awq
  - --gpu-memory-utilization
  - "0.90"  # Use 90% of 20GB = ~18GB
  - --max-model-len
  - "16384"  # 16K context window
  - --max-num-seqs
  - "16"  # Handle 16 concurrent requests
```

### Memory Breakdown

**RX 7900 XT (20GB VRAM) Usage:**

| Component | VRAM Usage | Notes |
|-----------|------------|-------|
| Model Weights (AWQ) | ~5.5GB | 4-bit quantized |
| KV Cache | ~8-10GB | For 16K context @ 16 seqs |
| Activations | ~2GB | Forward pass memory |
| vLLM Overhead | ~0.5GB | Runtime overhead |
| **Total** | **~16-18GB** | Fits comfortably in 20GB |

**Available Headroom**: ~2-4GB for OS/Desktop

### Performance Tuning

**For Maximum Throughput:**

```yaml
- --gpu-memory-utilization
- "0.95"  # Use 95% instead of 90%
- --max-num-seqs
- "32"  # Increase concurrent requests
```

**For Longer Context (32K tokens):**

```yaml
- --max-model-len
- "32768"  # Double context length
- --max-num-seqs
- "8"  # Reduce concurrent to fit KV cache
```

**For Lower Latency (Single User):**

```yaml
- --gpu-memory-utilization
- "0.75"
- --max-num-seqs
- "4"
- --max-model-len
- "8192"  # Reduce context
```

---

## 🧪 Testing & Validation

### 1. Verify ROCm Installation

```bash
# Check ROCm version
/opt/rocm/bin/rocm-smi --version

# Display GPU info
rocm-smi --showproductname
rocm-smi --showmeminfo vram

# Verify gfx1100 architecture
rocminfo | grep -i "name\|gfx"
```

**Expected Output:**
```
GPU[0]      : GPU Name: AMD Radeon RX 7900 XT
GPU[0]      : Total VRAM: 20464 MB
Name: gfx1100
```

### 2. Test vLLM Container

```bash
# Start brain stack
docker compose -f brain-stack.yml up -d

# Watch vLLM startup (takes 2-3 minutes)
docker logs -f brain-vllm

# Look for:
# ✅ "Loading model weights..."
# ✅ "Using ROCm backend"
# ✅ "Model loaded successfully"
```

### 3. Test Inference

```bash
# List available models
curl http://localhost:8000/v1/models

# Test completion
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ",
    "prompt": "Explain quantum computing in simple terms:",
    "max_tokens": 100,
    "temperature": 0.7
  }'

# Test chat completion
curl http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ",
    "messages": [
      {"role": "system", "content": "You are a helpful AI assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ],
    "max_tokens": 50
  }'
```

**Expected Performance:**
- **First Token Latency**: ~100-200ms
- **Throughput**: 30-50 tokens/second
- **VRAM Usage**: ~8-9GB (check with `rocm-smi`)

### 4. Monitor GPU Usage

```bash
# Real-time GPU monitoring
watch -n 1 rocm-smi

# Or detailed view
rocm-smi --showmeminfo vram --showuse
```

---

## 🎯 Optimization Tips

### 1. Leverage 128GB RAM

**Benefits:**
- Large model caching without disk I/O
- Fast context switching between models
- Efficient batch processing

**Optimization:**

```bash
# Increase Docker memory limits (optional)
# Edit /etc/docker/daemon.json
{
  "default-shm-size": "64G"
}

# Restart Docker
sudo systemctl restart docker
```

### 2. Tensor Parallelism (Future: Multi-GPU)

If you add a second GPU:

```yaml
command:
  - --tensor-parallel-size
  - "2"  # Split model across 2 GPUs
```

### 3. AWQ Optimization Flags

**Already configured in brain-stack.yml:**

```yaml
environment:
  # Enable optimized ROCm kernels
  - VLLM_ROCM_USE_AITER=1
  - VLLM_ROCM_USE_AITER_RMSNORM=1
  - VLLM_ROCM_USE_AITER_MOE=1
  - VLLM_USE_TRITON_FLASH_ATTN=0  # Disable if unstable
  - HIP_FORCE_DEV_KERNARG=1
```

### 4. Context Window vs Throughput

**Tradeoff Table:**

| Context Length | Max Concurrent | VRAM Usage | Use Case |
|----------------|----------------|------------|----------|
| 4K | 32 | ~12GB | High throughput API |
| 8K | 16 | ~14GB | Balanced |
| 16K | 16 | ~16GB | Current config |
| 32K | 8 | ~18GB | Long documents |

---

## 🐛 Troubleshooting

### Issue 1: `HSA_STATUS_ERROR_INCOMPATIBLE_ARGUMENTS`

**Solution:**
```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0
echo 'HSA_OVERRIDE_GFX_VERSION=11.0.0' | sudo tee -a /etc/environment
```

Reboot and verify:
```bash
echo $HSA_OVERRIDE_GFX_VERSION  # Should output: 11.0.0
```

### Issue 2: vLLM doesn't detect GPU

**Check:**
```bash
# Verify devices exist
ls -la /dev/kfd /dev/dri/render*

# Check Docker has access
docker run --rm --device=/dev/kfd --device=/dev/dri rocm/pytorch:latest rocm-smi
```

**Solution:** Ensure `devices:` in brain-stack.yml:
```yaml
devices:
  - /dev/kfd:/dev/kfd
  - /dev/dri:/dev/dri
```

### Issue 3: Out of Memory (OOM)

**Symptoms:**
```
RuntimeError: HIP out of memory
```

**Solutions:**

1. Reduce GPU memory utilization:
```yaml
- --gpu-memory-utilization
- "0.80"  # Down from 0.90
```

2. Reduce context length:
```yaml
- --max-model-len
- "8192"  # Down from 16384
```

3. Reduce concurrent sequences:
```yaml
- --max-num-seqs
- "8"  # Down from 16
```

### Issue 4: Slow Inference

**Check VRAM usage:**
```bash
rocm-smi --showmeminfo vram
```

If VRAM usage is low (<50%), you're CPU-bound:

**Solutions:**
1. Use larger batch sizes
2. Increase `--max-num-seqs`
3. Check CPU isn't thermal throttling: `sensors`

### Issue 5: Model Download Fails

**Common causes:**
- Disk space
- Network timeout
- HuggingFace authentication (for gated models)

**Solutions:**
```bash
# Check disk space
df -h /home/brains

# Resume interrupted download
huggingface-cli download \
    cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
    --local-dir /home/brains/ai-models/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ \
    --resume-download

# For gated models, login first
huggingface-cli login
```

---

## 📚 Additional Resources

### Documentation
- [ROCm Documentation](https://rocm.docs.amd.com/)
- [vLLM Documentation](https://docs.vllm.ai/)
- [AWQ Quantization Paper](https://arxiv.org/abs/2306.00978)

### Community
- [ROCm GitHub](https://github.com/RadeonOpenCompute/ROCm)
- [vLLM GitHub](https://github.com/vllm-project/vllm)
- [HuggingFace Forums](https://discuss.huggingface.co/)

### Related Files
- `brain-setup.sh` - System validation and directory setup
- `brain-model-downloader.sh` - Model download automation
- `brain-stack.yml` - Docker Compose configuration
- `PORTAINER-DEPLOY.md` - Portainer deployment guide
- `BRAIN-TROUBLESHOOTING.md` - Quick troubleshooting reference

---

## 🎉 Success Checklist

- [ ] ROCm installed and `rocm-smi` shows RX 7900 XT
- [ ] Environment variables set (`HSA_OVERRIDE_GFX_VERSION=11.0.0`)
- [ ] Docker can access `/dev/kfd` and `/dev/dri`
- [ ] HuggingFace CLI installed (`pip install huggingface_hub`)
- [ ] Model downloaded (5-6GB in `/home/brains/ai-models`)
- [ ] brain-setup.sh executed successfully
- [ ] brain-stack.yml deployed via Docker Compose or Portainer
- [ ] vLLM container running: `docker ps | grep brain-vllm`
- [ ] API responding: `curl http://localhost:8000/v1/models`
- [ ] Inference working: Test with completion endpoint
- [ ] GPU utilized: `rocm-smi` shows VRAM usage ~8-9GB

---

**🚀 You're now ready to run cutting-edge LLM inference on AMD hardware!**

For questions or issues, see `BRAIN-TROUBLESHOOTING.md` or check container logs:
```bash
docker logs -f brain-vllm
```
