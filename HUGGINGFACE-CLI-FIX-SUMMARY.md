# Hugging Face CLI Download Command Fix - Summary

## Overview

This document summarizes the changes made to fix and optimize the Hugging Face CLI download command for the Dolphin 2.9.3 Llama 3.1 8B AWQ model, specifically optimized for the Brain node's AMD Radeon RX 7900 XT GPU.

## System Specifications

- **GPU**: AMD Radeon RX 7900 XT (20GB VRAM, gfx1100 architecture)
- **CPU**: Intel Core i9-285K (or Ultra 9 285K)
- **RAM**: 128GB DDR5
- **OS**: Pop!_OS 22.04 LTS (Ubuntu-based)
- **Target Model**: cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ

## Changes Made

### 1. Fixed Hugging Face CLI Commands

**Corrected Command Format:**
```bash
huggingface-cli download cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
  --local-dir /home/brains/ai-models/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ \
  --local-dir-use-symlinks False \
  --resume-download
```

**Key Flags Explained:**
- `--local-dir`: Specifies exact download location (required for vLLM compatibility)
- `--local-dir-use-symlinks False`: Downloads actual files instead of symlinks
- `--resume-download`: Allows resuming interrupted downloads

**Files Updated:**
- ✅ `brain-setup.sh` (line 312)
- ✅ `PORTAINER-DEPLOY.md` (Step 3)
- ✅ `INTEGRATION-GUIDE.md` (Step 3)

### 2. Created New Files

#### a) `brain-model-downloader.sh` (Automated Download Script)

**Purpose**: Fully automated model download script with AMD GPU optimizations

**Features**:
- System validation (disk space, ROCm, huggingface-cli)
- Automated download with proper flags
- Progress tracking and logging
- Interactive prompts for optional components
- AMD GPU performance notes and optimization tips

**Usage**:
```bash
bash brain-model-downloader.sh
```

#### b) `BRAIN-AMD-SETUP.md` (Comprehensive Setup Guide)

**Purpose**: Complete AMD ROCm setup and optimization guide

**Contents**:
- ROCm installation instructions for Ubuntu/Pop!_OS
- Environment variable configuration for RX 7900 XT (gfx1100)
- Python environment setup
- Docker configuration for AMD GPU
- Model download procedures
- vLLM configuration and tuning
- Performance optimization tips
- Troubleshooting guide
- Testing and validation procedures

**Key Sections**:
- 🚀 Quick Start (one-command setup)
- 📦 Prerequisites Installation
- 🧠 Model Configuration
- ⚙️ vLLM Configuration for AMD
- 🧪 Testing & Validation
- 🎯 Optimization Tips
- 🐛 Troubleshooting

#### c) `brain-requirements.txt` (Python Dependencies)

**Purpose**: Python dependencies for AMD ROCm environment

**Includes**:
- HuggingFace Hub with fast transfer support
- Transformers library
- Installation notes for PyTorch ROCm
- Environment variable documentation
- System package dependencies
- Verification commands

**Key Dependencies**:
```
huggingface_hub[hf_transfer]>=0.20.0
transformers>=4.37.0
accelerate>=0.25.0
sentencepiece>=0.1.99
```

**Special Note**: PyTorch must be installed separately using ROCm-specific wheels:
```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0
```

#### d) `brain-vllm-example.py` (Usage Example)

**Purpose**: Python example demonstrating vLLM usage on AMD GPU

**Features**:
- Server health checking
- Model listing
- Text completion examples
- Chat completion examples
- Streaming completion examples
- Performance monitoring
- AMD GPU optimization notes

**Usage**:
```bash
python3 brain-vllm-example.py
```

**Examples Included**:
1. Simple text completion
2. Chat-style completion with system prompt
3. Streaming token-by-token output
4. Performance metrics and GPU monitoring

### 3. Updated Documentation

#### a) `README.md`

**Changes**:
- Added Brain node files to documentation table
- Added Brain-specific quick start section
- Referenced new AMD setup guide
- Updated file descriptions

**New Brain Node Section**:
```bash
# 1. Install ROCm
# 2. Run system setup
bash brain-setup.sh
# 3. Download AI models
bash brain-model-downloader.sh
# 4. Deploy stack
docker compose -f brain-stack.yml up -d
# 5. Verify services
```

#### b) `PORTAINER-DEPLOY.md`

**Changes**:
- Added automated download option (brain-model-downloader.sh)
- Updated manual download command with proper flags
- Improved installation instructions

#### c) `INTEGRATION-GUIDE.md`

**Changes**:
- Added automated download option
- Updated manual download command with proper flags
- Clarified deployment steps

## AMD ROCm Optimization Highlights

### Environment Variables (Critical for RX 7900 XT)

```bash
export HSA_OVERRIDE_GFX_VERSION=11.0.0
export ROCM_PATH=/opt/rocm
export HIP_VISIBLE_DEVICES=0
export PYTORCH_ROCM_ARCH=gfx1100
export HIP_FORCE_DEV_KERNARG=1
export HF_HUB_ENABLE_HF_TRANSFER=1
```

### vLLM Configuration

**Optimized for 20GB VRAM:**
```yaml
environment:
  - HSA_OVERRIDE_GFX_VERSION=11.0.0
  - ROCM_PATH=/opt/rocm
  - PYTORCH_ROCM_ARCH=gfx1100
  
command:
  - --gpu-memory-utilization
  - "0.90"  # Use 90% of 20GB
  - --max-model-len
  - "16384"  # 16K context
  - --max-num-seqs
  - "16"  # 16 concurrent requests
```

### Expected Performance

- **VRAM Usage**: ~8-9GB for 8B AWQ model
- **Throughput**: 30-50 tokens/second on RX 7900 XT
- **Context Length**: 16K tokens (configurable up to 32K)
- **Concurrent Requests**: 16 (configurable)
- **First Token Latency**: ~100-200ms

## Model Details

### Dolphin 2.9.3 Llama 3.1 8B AWQ

- **Repository**: cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ
- **Quantization**: AWQ 4-bit (Auto-Weight Quantization)
- **Original Size**: ~16GB (FP16)
- **Quantized Size**: ~5-6GB (AWQ)
- **Parameters**: 8 billion
- **Architecture**: Llama 3.1
- **Context Length**: 8K default, 16K configured

### Why AWQ for AMD?

- ✅ **Efficient**: 4-bit quantization → ~70% VRAM reduction
- ✅ **Fast**: Optimized kernels for inference speed
- ✅ **Quality**: Minimal accuracy loss vs FP16
- ✅ **Compatible**: Works with vLLM on ROCm

## Installation Workflow

### Complete Setup from Scratch

```bash
# 1. Install ROCm (Ubuntu/Pop!_OS 22.04)
wget -qO - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/6.0/ ubuntu main' | \
    sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-hip-sdk rocm-libs rocm-smi-lib

# 2. Set environment variables
sudo tee -a /etc/environment <<EOF
HSA_OVERRIDE_GFX_VERSION=11.0.0
ROCM_PATH=/opt/rocm
HIP_VISIBLE_DEVICES=0
EOF

# 3. Reboot
sudo reboot

# 4. Install HuggingFace CLI
pip install -U huggingface_hub[hf_transfer]

# 5. Run brain setup
bash brain-setup.sh

# 6. Download models
bash brain-model-downloader.sh

# 7. Deploy stack
docker compose -f brain-stack.yml up -d

# 8. Verify
curl http://localhost:8000/v1/models
```

## Testing & Validation

### Verify ROCm Installation

```bash
rocm-smi --showproductname
rocminfo | grep gfx1100
ls /dev/kfd /dev/dri/render*
```

### Test vLLM Inference

```bash
# List models
curl http://localhost:8000/v1/models

# Test completion
curl http://localhost:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ",
    "prompt": "Hello, how are you?",
    "max_tokens": 50
  }'

# Or use Python example
python3 brain-vllm-example.py
```

### Monitor GPU Usage

```bash
# Real-time monitoring
watch -n 1 rocm-smi

# Detailed VRAM info
rocm-smi --showmeminfo vram --showuse
```

## Troubleshooting

### Common Issues

1. **HSA_STATUS_ERROR_INCOMPATIBLE_ARGUMENTS**
   - Solution: Set `HSA_OVERRIDE_GFX_VERSION=11.0.0`

2. **vLLM doesn't detect GPU**
   - Check `/dev/kfd` and `/dev/dri` exist
   - Verify `devices:` in brain-stack.yml

3. **Out of Memory**
   - Reduce `--gpu-memory-utilization` to 0.80
   - Reduce `--max-model-len` to 8192
   - Reduce `--max-num-seqs` to 8

4. **Model download fails**
   - Check disk space: `df -h /home/brains`
   - Use `--resume-download` flag
   - Enable hf_transfer: `export HF_HUB_ENABLE_HF_TRANSFER=1`

See `BRAIN-AMD-SETUP.md` for detailed troubleshooting.

## Files Reference

| File | Purpose | Size |
|------|---------|------|
| `brain-model-downloader.sh` | Automated model download script | 11KB |
| `BRAIN-AMD-SETUP.md` | Complete AMD ROCm setup guide | 13KB |
| `brain-requirements.txt` | Python dependencies documentation | 6.5KB |
| `brain-vllm-example.py` | Usage example for vLLM on AMD | 7.8KB |
| `brain-setup.sh` | System setup and validation | Updated |
| `PORTAINER-DEPLOY.md` | Portainer deployment guide | Updated |
| `INTEGRATION-GUIDE.md` | Brain-Brawn integration | Updated |
| `README.md` | Project overview | Updated |

## Success Criteria Met

- ✅ Valid huggingface-cli download command with correct flags
- ✅ `--local-dir` specifies exact download path
- ✅ `--local-dir-use-symlinks False` for actual file downloads
- ✅ `--resume-download` for interrupted downloads
- ✅ Setup script compatible with AMD RX 7900 XT
- ✅ Complete ROCm installation and configuration guide
- ✅ Documentation for running AWQ models on AMD hardware
- ✅ Configuration optimized for 20GB VRAM and 128GB RAM
- ✅ Python dependencies documented
- ✅ Example code for model loading and inference
- ✅ Performance optimization tips included
- ✅ Comprehensive troubleshooting guide

## Next Steps for Users

1. **Review** `BRAIN-AMD-SETUP.md` for complete setup instructions
2. **Run** `bash brain-setup.sh` to validate system
3. **Download** models using `bash brain-model-downloader.sh`
4. **Deploy** stack with `docker compose -f brain-stack.yml up -d`
5. **Test** inference with `python3 brain-vllm-example.py`
6. **Monitor** GPU usage with `rocm-smi`
7. **Optimize** settings based on workload requirements

## Additional Resources

- [ROCm Documentation](https://rocm.docs.amd.com/)
- [vLLM Documentation](https://docs.vllm.ai/)
- [HuggingFace Hub CLI](https://huggingface.co/docs/huggingface_hub/guides/cli)
- [AWQ Quantization Paper](https://arxiv.org/abs/2306.00978)
- [Dolphin Model Card](https://huggingface.co/cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ)

---

**Created**: 2026-02-14  
**For**: Brain Node (Pop!_OS 192.168.1.9) - AMD RX 7900 XT Setup  
**Status**: Complete and tested
