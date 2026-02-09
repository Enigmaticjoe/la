#!/bin/bash
# ==============================================================================
# AI Model Downloader for Unraid
# ==============================================================================
# Purpose: Downloads HuggingFace models for vLLM + TEI inference stack
# Usage:   Run as Unraid User Script or via SSH as root
# Target:  RTX 4070 (12GB VRAM) - AWQ quantized models for vLLM
#
# This script runs downloads inside a disposable Docker container to avoid
# the "pip not found" issue on Unraid's immutable Slackware host OS.
# ==============================================================================

set -euo pipefail

# ==============================================================================
# CONFIGURATION
# ==============================================================================
BASE_DIR="/mnt/user/appdata/huggingface"
VLLM_MODELS="${BASE_DIR}/vllm-models"
TEI_EMBED_DATA="${BASE_DIR}/tei-embed-data"
TEI_RERANK_DATA="${BASE_DIR}/tei-rerank-data"
HF_CACHE="${BASE_DIR}/hub"
DOCKER_IMAGE="python:3.11-slim"
LOG_FILE="/tmp/ai-model-download.log"

# --- LLM Models (AWQ for vLLM with Marlin kernels) ---
# Verified repo IDs on HuggingFace as of Feb 2026
VLLM_MODELS_LIST=(
    "solidrust/dolphin-2.9.4-llama3.1-8b-AWQ"
    # Uncomment additional models as needed:
    # "Qwen/Qwen2.5-7B-Instruct-AWQ"
    # "solidrust/Llama-3.1-8B-Lexi-Uncensored-V2-AWQ"
    # "Orion-zhen/Qwen3-8B-AWQ"
)

# --- Embedding Model (for TEI / RAG pipeline) ---
TEI_EMBED_MODEL="Qwen/Qwen3-Embedding-0.6B"

# --- Reranker Model (for TEI reranking in RAG) ---
TEI_RERANK_MODEL="BAAI/bge-reranker-large"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

check_gpu() {
    if command -v nvidia-smi &>/dev/null; then
        log "GPU: $(nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>/dev/null || echo 'query failed')"
    else
        log "WARNING: nvidia-smi not found (normal if running from User Scripts)"
    fi
}

check_disk_space() {
    local available
    available=$(df -BG "${BASE_DIR}" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ -n "$available" ]] && (( available < 20 )); then
        log "WARNING: Only ${available}GB free. Models need ~15-20GB total."
    else
        log "Disk space: ${available:-unknown}GB available"
    fi
}

# ==============================================================================
# MAIN
# ==============================================================================
log "=========================================="
log "AI Model Downloader - Starting"
log "=========================================="
check_gpu
check_disk_space

# Create directory structure
log "Creating directories..."
mkdir -p "${VLLM_MODELS}"
mkdir -p "${TEI_EMBED_DATA}"
mkdir -p "${TEI_RERANK_DATA}"
mkdir -p "${HF_CACHE}"

# Set Unraid permissions (nobody:users = 99:100)
chown -R 99:100 "${BASE_DIR}"
chmod -R 755 "${BASE_DIR}"

# Pull the Python image
log "Pulling ${DOCKER_IMAGE}..."
docker pull "${DOCKER_IMAGE}" 2>&1 | tail -1

# ==============================================================================
# Download vLLM Models (LLM inference)
# ==============================================================================
for MODEL_ID in "${VLLM_MODELS_LIST[@]}"; do
    MODEL_NAME="${MODEL_ID##*/}"
    DEST="/data/${MODEL_ID}"

    if [ -d "${VLLM_MODELS}/${MODEL_ID}" ] && [ "$(ls -A "${VLLM_MODELS}/${MODEL_ID}" 2>/dev/null)" ]; then
        log "SKIP: ${MODEL_ID} already exists at ${VLLM_MODELS}/${MODEL_ID}"
        continue
    fi

    log "Downloading LLM: ${MODEL_ID} -> ${VLLM_MODELS}/${MODEL_ID}"

    docker run --rm \
        -v "${VLLM_MODELS}:/data" \
        -v "${HF_CACHE}:/root/.cache/huggingface" \
        -e HF_HUB_ENABLE_HF_TRANSFER=1 \
        "${DOCKER_IMAGE}" \
        /bin/bash -c '
            pip install -q huggingface_hub hf_transfer 2>/dev/null
            export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
            python3 <<PYEOF
import sys
from huggingface_hub import snapshot_download

model_id = "'"${MODEL_ID}"'"
dest = "'"${DEST}"'"
print(f"Downloading {model_id} to {dest}...")
try:
    snapshot_download(
        repo_id=model_id,
        local_dir=dest,
        local_dir_use_symlinks=False,
        resume_download=True
    )
    print(f"SUCCESS: {model_id}")
except Exception as e:
    print(f"FAILED: {model_id} - {e}", file=sys.stderr)
    sys.exit(1)
PYEOF
        ' 2>&1 | while IFS= read -r line; do log "  ${line}"; done

    if [ $? -eq 0 ]; then
        log "OK: ${MODEL_ID} downloaded"
    else
        log "ERROR: ${MODEL_ID} download failed - will retry on next run"
    fi
done

# ==============================================================================
# Download Embedding Model (for TEI)
# ==============================================================================
if [ -d "${TEI_EMBED_DATA}/${TEI_EMBED_MODEL}" ] && [ "$(ls -A "${TEI_EMBED_DATA}/${TEI_EMBED_MODEL}" 2>/dev/null)" ]; then
    log "SKIP: Embedding model already exists"
else
    log "Downloading Embedding: ${TEI_EMBED_MODEL}"

    docker run --rm \
        -v "${TEI_EMBED_DATA}:/data" \
        -v "${HF_CACHE}:/root/.cache/huggingface" \
        -e HF_HUB_ENABLE_HF_TRANSFER=1 \
        "${DOCKER_IMAGE}" \
        /bin/bash -c '
            pip install -q huggingface_hub hf_transfer 2>/dev/null
            export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
            python3 <<PYEOF
from huggingface_hub import snapshot_download
model = "'"${TEI_EMBED_MODEL}"'"
print(f"Downloading {model}...")
snapshot_download(repo_id=model, local_dir=f"/data/{model}", local_dir_use_symlinks=False, resume_download=True)
print(f"SUCCESS: {model}")
PYEOF
        ' 2>&1 | while IFS= read -r line; do log "  ${line}"; done
fi

# ==============================================================================
# Download Reranker Model (for TEI)
# ==============================================================================
if [ -d "${TEI_RERANK_DATA}/${TEI_RERANK_MODEL}" ] && [ "$(ls -A "${TEI_RERANK_DATA}/${TEI_RERANK_MODEL}" 2>/dev/null)" ]; then
    log "SKIP: Reranker model already exists"
else
    log "Downloading Reranker: ${TEI_RERANK_MODEL}"

    docker run --rm \
        -v "${TEI_RERANK_DATA}:/data" \
        -v "${HF_CACHE}:/root/.cache/huggingface" \
        -e HF_HUB_ENABLE_HF_TRANSFER=1 \
        "${DOCKER_IMAGE}" \
        /bin/bash -c '
            pip install -q huggingface_hub hf_transfer 2>/dev/null
            export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
            python3 <<PYEOF
from huggingface_hub import snapshot_download
model = "'"${TEI_RERANK_MODEL}"'"
print(f"Downloading {model}...")
snapshot_download(repo_id=model, local_dir=f"/data/{model}", local_dir_use_symlinks=False, resume_download=True)
print(f"SUCCESS: {model}")
PYEOF
        ' 2>&1 | while IFS= read -r line; do log "  ${line}"; done
fi

# ==============================================================================
# Final permissions & summary
# ==============================================================================
log "Setting final permissions..."
chown -R 99:100 "${BASE_DIR}"
chmod -R 755 "${BASE_DIR}"

log ""
log "=========================================="
log "DOWNLOAD SUMMARY"
log "=========================================="
echo ""
echo "vLLM Models:"
for MODEL_ID in "${VLLM_MODELS_LIST[@]}"; do
    SIZE=$(du -sh "${VLLM_MODELS}/${MODEL_ID}" 2>/dev/null | cut -f1 || echo "MISSING")
    echo "  ${MODEL_ID}: ${SIZE}"
done
echo ""
echo "Embedding: $(du -sh "${TEI_EMBED_DATA}/${TEI_EMBED_MODEL}" 2>/dev/null | cut -f1 || echo 'MISSING')"
echo "Reranker:  $(du -sh "${TEI_RERANK_DATA}/${TEI_RERANK_MODEL}" 2>/dev/null | cut -f1 || echo 'MISSING')"
echo ""
log "Log saved to: ${LOG_FILE}"
log "=========================================="
log "Ready to deploy Portainer stack!"
log "=========================================="
