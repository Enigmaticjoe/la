#!/bin/bash
###############################################################################
# brain-model-downloader.sh
# NODE B (Brain) - Pop!_OS | Ultra 9 285K | RX 7900 XT 20GB | 128GB DDR5
#
# Usage: bash brain-model-downloader.sh
#
# Purpose: Downloads HuggingFace models for vLLM inference on AMD GPU
# Optimized for: AMD Radeon RX 7900 XT (20GB VRAM) with ROCm support
#
# What this does:
#   1. Validates system prerequisites (huggingface-cli, disk space, ROCm)
#   2. Downloads Dolphin 2.9.3 Llama 3.1 8B AWQ model
#   3. Optionally downloads embedding models for RAG
#   4. Optimizes for 128GB RAM and AMD GPU architecture
###############################################################################

set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'; BOLD='\033[1m'
ok()   { echo -e "${G}[ok]${NC} $1"; }
warn() { echo -e "${Y}[!!]${NC} $1"; }
fail() { echo -e "${R}[xx]${NC} $1"; }
info() { echo -e "${B}[ii]${NC} $1"; }
section() { echo -e "\n${BOLD}=== $1 ===${NC}"; }

echo ""
echo "####################################################"
echo "#  BRAIN AI Model Downloader                       #"
echo "#  AMD RX 7900 XT 20GB | 128GB RAM                #"
echo "#  Optimized for AWQ Quantized Models              #"
echo "####################################################"
echo ""

# ==============================================================================
# CONFIGURATION
# ==============================================================================
BASE_DIR="/home/brains/ai-models"
LOG_FILE="/tmp/brain-model-download.log"

# --- Primary LLM Model (AWQ quantized for efficient inference) ---
PRIMARY_MODEL="cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ"
PRIMARY_MODEL_DIR="${BASE_DIR}/models--cognitivecomputations--dolphin-2.9.3-llama-3.1-8b-AWQ"

# --- Optional: Embedding Model for RAG (auto-downloaded by TEI if not present) ---
EMBED_MODEL="Qwen/Qwen3-Embedding-0.6B"
EMBED_MODEL_DIR="${BASE_DIR}/models--Qwen--Qwen3-Embedding-0.6B"

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

check_disk_space() {
    local available
    available=$(df -BG "${BASE_DIR}" 2>/dev/null | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ -n "$available" ]] && (( available < 30 )); then
        warn "Only ${available}GB free. AWQ models need ~20-30GB."
        read -rp "  Continue anyway? [y/N] " ans
        if [[ ! "${ans:-}" =~ ^[Yy]$ ]]; then
            fail "Aborting due to insufficient disk space"
            exit 1
        fi
    else
        ok "Disk space: ${available:-unknown}GB available"
    fi
}

check_gpu() {
    if command -v rocm-smi &>/dev/null; then
        ok "AMD GPU detected:"
        rocm-smi --showproductname 2>/dev/null | grep -i "card\|name" | head -2 | while read line; do info "  $line"; done
    else
        warn "rocm-smi not found - cannot verify AMD GPU"
    fi
}

# ==============================================================================
# SYSTEM VALIDATION
# ==============================================================================
section "SYSTEM VALIDATION"

# Check huggingface-cli
if ! command -v huggingface-cli &>/dev/null; then
    fail "huggingface-cli not found"
    echo ""
    info "Install with:"
    info "  pip install -U huggingface_hub"
    echo ""
    info "Or for faster downloads with hf_transfer:"
    info "  pip install -U huggingface_hub[hf_transfer]"
    echo ""
    exit 1
else
    ok "huggingface-cli: $(huggingface-cli --version 2>/dev/null || echo 'installed')"
fi

# Check Python
if command -v python3 &>/dev/null; then
    ok "Python: $(python3 --version | cut -d' ' -f2)"
else
    warn "Python3 not found in PATH"
fi

# Check pip
if command -v pip &>/dev/null || command -v pip3 &>/dev/null; then
    ok "pip: available"
else
    warn "pip not found - may need for additional packages"
fi

# Check disk space
check_disk_space

# Check GPU
check_gpu

# Create base directory if needed
if [ ! -d "$BASE_DIR" ]; then
    mkdir -p "$BASE_DIR" && ok "Created: $BASE_DIR" || fail "Could not create: $BASE_DIR"
else
    ok "Base directory exists: $BASE_DIR"
fi

# ==============================================================================
# DOWNLOAD PRIMARY LLM MODEL
# ==============================================================================
section "PRIMARY LLM MODEL DOWNLOAD"

info "Model: ${PRIMARY_MODEL}"
info "Destination: ${PRIMARY_MODEL_DIR}"
info "Type: AWQ Quantized (4-bit) - optimized for inference"
info "Size: ~5-6GB (quantized from 16GB FP16)"
echo ""

if [ -d "${PRIMARY_MODEL_DIR}" ] && [ "$(ls -A "${PRIMARY_MODEL_DIR}" 2>/dev/null)" ]; then
    warn "Model directory already exists and contains files"
    ls -lh "${PRIMARY_MODEL_DIR}" | head -5
    echo ""
    read -rp "  Re-download/update model? [y/N] " ans
    if [[ ! "${ans:-}" =~ ^[Yy]$ ]]; then
        ok "Skipping download - using existing model"
    else
        info "Downloading/updating ${PRIMARY_MODEL}..."
        echo ""
        
        # Enable hf_transfer for faster downloads if available
        export HF_HUB_ENABLE_HF_TRANSFER=1
        
        huggingface-cli download "${PRIMARY_MODEL}" \
            --local-dir "${PRIMARY_MODEL_DIR}" \
            --local-dir-use-symlinks False \
            --resume-download 2>&1 | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            ok "✅ Model downloaded successfully"
        else
            fail "❌ Model download failed - check log: $LOG_FILE"
            exit 1
        fi
    fi
else
    info "Downloading ${PRIMARY_MODEL}..."
    echo ""
    info "This will download ~5-6GB. On fast connections: ~5-10 min"
    echo ""
    
    # Enable hf_transfer for faster downloads if available
    export HF_HUB_ENABLE_HF_TRANSFER=1
    
    huggingface-cli download "${PRIMARY_MODEL}" \
        --local-dir "${PRIMARY_MODEL_DIR}" \
        --local-dir-use-symlinks False \
        --resume-download 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        ok "✅ Model downloaded successfully"
    else
        fail "❌ Model download failed - check log: $LOG_FILE"
        exit 1
    fi
fi

# ==============================================================================
# OPTIONAL: DOWNLOAD EMBEDDING MODEL
# ==============================================================================
section "EMBEDDING MODEL (OPTIONAL)"

echo ""
info "The embedding model (${EMBED_MODEL}) is used for RAG functionality."
info "It will auto-download when TEI container starts (adds 5-10 min to startup)."
echo ""
read -rp "  Download embedding model now? [y/N] " ans

if [[ "${ans:-}" =~ ^[Yy]$ ]]; then
    if [ -d "${EMBED_MODEL_DIR}" ] && [ "$(ls -A "${EMBED_MODEL_DIR}" 2>/dev/null)" ]; then
        ok "Embedding model already exists - skipping"
    else
        info "Downloading ${EMBED_MODEL}..."
        echo ""
        
        export HF_HUB_ENABLE_HF_TRANSFER=1
        
        huggingface-cli download "${EMBED_MODEL}" \
            --local-dir "${EMBED_MODEL_DIR}" \
            --local-dir-use-symlinks False \
            --resume-download 2>&1 | tee -a "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            ok "✅ Embedding model downloaded"
        else
            warn "Embedding model download failed - TEI will download it automatically"
        fi
    fi
else
    info "Skipping embedding model - TEI will auto-download on first start"
fi

# ==============================================================================
# SUMMARY
# ==============================================================================
section "DOWNLOAD SUMMARY"

echo ""
echo "Model Storage:"
echo "  Location: ${BASE_DIR}"
echo ""

if [ -d "${PRIMARY_MODEL_DIR}" ]; then
    SIZE=$(du -sh "${PRIMARY_MODEL_DIR}" 2>/dev/null | cut -f1 || echo "UNKNOWN")
    ok "Primary LLM: ${PRIMARY_MODEL} (${SIZE})"
    info "  Path: ${PRIMARY_MODEL_DIR}"
    echo ""
    info "  Model files:"
    ls -lh "${PRIMARY_MODEL_DIR}" | grep -E "\.safetensors|\.json|tokenizer" | head -10 | while read line; do
        echo "    $line"
    done
else
    warn "Primary LLM not found - download may have failed"
fi

echo ""

if [ -d "${EMBED_MODEL_DIR}" ]; then
    SIZE=$(du -sh "${EMBED_MODEL_DIR}" 2>/dev/null | cut -f1 || echo "UNKNOWN")
    ok "Embedding: ${EMBED_MODEL} (${SIZE})"
else
    info "Embedding: Not downloaded (will auto-download by TEI)"
fi

echo ""
log "Log saved to: ${LOG_FILE}"
echo ""

# ==============================================================================
# AMD GPU OPTIMIZATION NOTES
# ==============================================================================
section "AMD GPU OPTIMIZATION NOTES"

echo ""
info "System Specs:"
info "  • GPU: AMD Radeon RX 7900 XT (20GB VRAM)"
info "  • RAM: 128GB DDR5"
info "  • Model: Dolphin 2.9.3 Llama 3.1 8B AWQ (~5-6GB)"
echo ""
info "Expected Performance:"
info "  • VRAM Usage: ~8-9GB with vLLM overhead (45% of available)"
info "  • Context Length: 16K tokens (configurable in brain-stack.yml)"
info "  • Inference Speed: ~30-50 tokens/sec on RX 7900 XT"
info "  • Concurrent Requests: 16 (max-num-seqs in config)"
echo ""
info "ROCm Environment Variables (already in brain-stack.yml):"
info "  • HSA_OVERRIDE_GFX_VERSION=11.0.0"
info "  • ROCM_PATH=/opt/rocm"
info "  • PYTORCH_ROCM_ARCH=gfx1100"
info "  • HIP_VISIBLE_DEVICES=0"
echo ""
info "Memory Optimization:"
info "  • AWQ quantization: 4-bit weights → ~70% VRAM reduction"
info "  • GPU memory utilization: 90% (configurable)"
info "  • 128GB RAM allows large batch processing and caching"
echo ""

section "NEXT STEPS"

echo ""
echo "  1. Verify ROCm environment (if not done):"
echo "     export HSA_OVERRIDE_GFX_VERSION=11.0.0"
echo "     export ROCM_PATH=/opt/rocm"
echo "     echo 'HSA_OVERRIDE_GFX_VERSION=11.0.0' | sudo tee -a /etc/environment"
echo "     echo 'ROCM_PATH=/opt/rocm' | sudo tee -a /etc/environment"
echo ""
echo "  2. Deploy the brain stack:"
echo "     docker compose -f brain-stack.yml up -d"
echo ""
echo "  3. Monitor vLLM startup (model load takes ~2-3 min):"
echo "     docker logs -f brain-vllm"
echo ""
echo "  4. Test inference once loaded:"
echo "     curl http://localhost:8000/v1/models"
echo "     curl http://localhost:8000/v1/completions \\"
echo "       -H 'Content-Type: application/json' \\"
echo "       -d '{\"model\": \"cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ\", "
echo "            \"prompt\": \"Hello, how are you?\", \"max_tokens\": 50}'"
echo ""
echo "  =================================================="
echo "  ✅ Models ready for deployment!"
echo "  See: BRAIN-AMD-SETUP.md for complete ROCm setup guide"
echo "  =================================================="
echo ""
