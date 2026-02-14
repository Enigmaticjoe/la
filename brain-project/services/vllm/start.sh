#!/bin/bash
###############################################################################
# vLLM Startup Script for AMD ROCm
# Configures environment and starts vLLM server
###############################################################################

set -euo pipefail

echo "======================================="
echo "Starting vLLM with AMD ROCm Support"
echo "GPU: AMD Radeon RX 7900 XT (20GB VRAM)"
echo "Model: Dolphin 2.9.3 Llama 3.1 8B AWQ"
echo "======================================="

# Display GPU info
if command -v rocm-smi &> /dev/null; then
    echo ""
    echo "GPU Information:"
    rocm-smi --showid --showtemp --showmeminfo vram
    echo ""
fi

# Set ROCm environment
export HSA_OVERRIDE_GFX_VERSION=${HSA_OVERRIDE_GFX_VERSION:-11.0.0}
export ROCM_PATH=${ROCM_PATH:-/opt/rocm}
export PYTORCH_ROCM_ARCH=${PYTORCH_ROCM_ARCH:-gfx1100}
export HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES:-0}

# Set vLLM optimizations
export VLLM_ROCM_USE_AITER=${VLLM_ROCM_USE_AITER:-1}
export VLLM_ROCM_USE_AITER_RMSNORM=${VLLM_ROCM_USE_AITER_RMSNORM:-1}
export VLLM_ROCM_USE_AITER_MOE=${VLLM_ROCM_USE_AITER_MOE:-1}
export VLLM_USE_TRITON_FLASH_ATTN=${VLLM_USE_TRITON_FLASH_ATTN:-0}
export HIP_FORCE_DEV_KERNARG=${HIP_FORCE_DEV_KERNARG:-1}
export VLLM_ATTENTION_BACKEND=${VLLM_ATTENTION_BACKEND:-ROCM_FLASH}

# Display configuration
echo "ROCm Configuration:"
echo "  ROCM_PATH: $ROCM_PATH"
echo "  HSA_OVERRIDE_GFX_VERSION: $HSA_OVERRIDE_GFX_VERSION"
echo "  PYTORCH_ROCM_ARCH: $PYTORCH_ROCM_ARCH"
echo "  HIP_VISIBLE_DEVICES: $HIP_VISIBLE_DEVICES"
echo ""

echo "vLLM Optimizations:"
echo "  VLLM_ATTENTION_BACKEND: $VLLM_ATTENTION_BACKEND"
echo "  VLLM_ROCM_USE_AITER: $VLLM_ROCM_USE_AITER"
echo ""

# Check if model is downloaded
MODEL_PATH="/root/.cache/huggingface/hub/models--${MODEL_NAME//\//_}"
if [ ! -d "$MODEL_PATH" ]; then
    echo "Model not found at $MODEL_PATH"
    echo "Downloading model (this may take a while)..."
fi

echo "Starting vLLM server..."
echo ""

# Start vLLM (command passed via docker-compose)
exec "$@"
