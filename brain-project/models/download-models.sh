#!/bin/bash
###############################################################################
# Download AI Models for Brain Project
# Downloads and caches models using huggingface-cli
###############################################################################

set -euo pipefail

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[1;34m'; NC='\033[0m'
ok()   { echo -e "${G}✓${NC} $1"; }
warn() { echo -e "${Y}⚠${NC} $1"; }
fail() { echo -e "${R}✗${NC} $1"; }
info() { echo -e "${B}ℹ${NC} $1"; }

BRAIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODELS_DIR="${BRAIN_DIR}/data/models"
ENV_FILE="${BRAIN_DIR}/.env"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 Brain AI Model Downloader"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load environment
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
    export HUGGING_FACE_HUB_TOKEN
fi

# Check huggingface-cli
if ! command -v huggingface-cli &>/dev/null; then
    fail "huggingface-cli not found"
    echo ""
    echo "Install with:"
    echo "  pip install -U 'huggingface_hub[cli]'"
    echo ""
    exit 1
fi

ok "huggingface-cli found"

# Check token
if [ -z "${HUGGING_FACE_HUB_TOKEN:-}" ] || [ "$HUGGING_FACE_HUB_TOKEN" == "your_huggingface_token_here" ]; then
    warn "No Hugging Face token set"
    echo ""
    echo "Get your token from: https://huggingface.co/settings/tokens"
    echo ""
    read -rp "Enter your Hugging Face token: " token
    export HUGGING_FACE_HUB_TOKEN="$token"
fi

# Create cache directory
mkdir -p "$MODELS_DIR"
ok "Cache directory: $MODELS_DIR"
echo ""

###############################################################################
# Model 1: Dolphin 2.9.3 Llama 3.1 8B AWQ (Primary LLM)
###############################################################################

info "Downloading Dolphin 2.9.3 Llama 3.1 8B AWQ..."
echo "  Model: cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ"
echo "  Size: ~4.5GB"
echo "  Quantization: AWQ (optimized for speed)"
echo ""

huggingface-cli download \
    cognitivecomputations/dolphin-2.9.3-llama-3.1-8b-AWQ \
    --cache-dir "$MODELS_DIR" \
    --resume-download \
    --local-dir-use-symlinks False

if [ $? -eq 0 ]; then
    ok "Dolphin model downloaded successfully"
else
    fail "Dolphin model download failed"
fi

echo ""

###############################################################################
# Model 2: Nomic Embed Text v1.5 (Embeddings)
###############################################################################

info "Downloading nomic-embed-text-v1.5..."
echo "  Model: nomic-ai/nomic-embed-text-v1.5"
echo "  Size: ~500MB"
echo "  Purpose: Text embeddings for RAG"
echo ""

huggingface-cli download \
    nomic-ai/nomic-embed-text-v1.5 \
    --cache-dir "$MODELS_DIR" \
    --resume-download \
    --local-dir-use-symlinks False

if [ $? -eq 0 ]; then
    ok "Embedding model downloaded successfully"
else
    fail "Embedding model download failed"
fi

echo ""

###############################################################################
# Optional Models
###############################################################################

info "Additional Models (Optional)"
echo ""
echo "You can download additional models for variety:"
echo "  1. Qwen2.5-7B-Instruct-AWQ (alternative LLM)"
echo "  2. Mistral-7B-Instruct-AWQ (alternative LLM)"
echo "  3. DeepSeek-Coder-6.7B-AWQ (coding specialist)"
echo ""

read -rp "Download additional models? [y/N] " response
if [[ "$response" =~ ^[Yy]$ ]]; then
    
    # Qwen
    read -rp "  Download Qwen2.5-7B-Instruct-AWQ? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        info "Downloading Qwen2.5-7B-Instruct-AWQ..."
        huggingface-cli download \
            Qwen/Qwen2.5-7B-Instruct-AWQ \
            --cache-dir "$MODELS_DIR" \
            --resume-download
        ok "Qwen downloaded"
    fi
    
    # Mistral
    read -rp "  Download Mistral-7B-Instruct-AWQ? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        info "Downloading Mistral-7B-Instruct-v0.3-AWQ..."
        huggingface-cli download \
            TheBloke/Mistral-7B-Instruct-v0.3-AWQ \
            --cache-dir "$MODELS_DIR" \
            --resume-download
        ok "Mistral downloaded"
    fi
    
    # DeepSeek Coder
    read -rp "  Download DeepSeek-Coder-6.7B-AWQ? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        info "Downloading DeepSeek-Coder-6.7B-AWQ..."
        huggingface-cli download \
            TheBloke/deepseek-coder-6.7B-instruct-AWQ \
            --cache-dir "$MODELS_DIR" \
            --resume-download
        ok "DeepSeek Coder downloaded"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "Model downloads complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

info "Models cached in: $MODELS_DIR"
info "Total size: $(du -sh "$MODELS_DIR" | cut -f1)"
echo ""

info "To use a different model, edit docker-compose.yml and change the --model parameter"
echo ""

exit 0
