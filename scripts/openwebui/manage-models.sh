#!/bin/bash
################################################################################
# Model Management Script for Open WebUI
# Pull, list, and manage Ollama models
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    echo "Usage: $0 {list|pull|remove|info} [model-name]"
    echo ""
    echo "Commands:"
    echo "  list              - List all installed models"
    echo "  pull <model>      - Pull a new model"
    echo "  remove <model>    - Remove a model"
    echo "  info <model>      - Show model information"
    echo "  recommended       - Show recommended models"
    echo ""
    exit 1
}

list_models() {
    echo -e "${BLUE}[INFO]${NC} Installed models:"
    docker exec ollama ollama list
}

pull_model() {
    local MODEL=$1
    echo -e "${BLUE}[INFO]${NC} Pulling model: $MODEL"
    docker exec ollama ollama pull "$MODEL"
    echo -e "${GREEN}[SUCCESS]${NC} Model pulled successfully"
}

remove_model() {
    local MODEL=$1
    echo -e "${YELLOW}[WARNING]${NC} Removing model: $MODEL"
    docker exec ollama ollama rm "$MODEL"
    echo -e "${GREEN}[SUCCESS]${NC} Model removed"
}

show_model_info() {
    local MODEL=$1
    echo -e "${BLUE}[INFO]${NC} Model information: $MODEL"
    docker exec ollama ollama show "$MODEL"
}

show_recommended() {
    echo "Recommended Models:"
    echo ""
    echo "General Purpose:"
    echo "  llama3.2:latest      - Fast, versatile (3B/7B parameters)"
    echo "  llama3.1:70b         - High quality, large (needs powerful GPU)"
    echo "  mistral:latest       - Good balance (7B parameters)"
    echo "  qwen2.5:latest       - Excellent performance"
    echo ""
    echo "Code:"
    echo "  codellama:latest     - Code generation and completion"
    echo "  deepseek-coder:latest - Advanced code understanding"
    echo "  qwen2.5-coder:latest - Specialized code model"
    echo ""
    echo "Embedding (for RAG):"
    echo "  nomic-embed-text     - Fast, efficient embeddings"
    echo "  mxbai-embed-large    - High quality embeddings"
    echo ""
    echo "Vision:"
    echo "  llava:latest         - Image understanding"
    echo "  bakllava:latest      - Better image analysis"
    echo ""
    echo "To pull a model: $0 pull <model-name>"
    echo ""
}

# Main
case "${1:-}" in
    list)
        list_models
        ;;
    pull)
        if [ -z "${2:-}" ]; then
            echo "Error: Model name required"
            show_usage
        fi
        pull_model "$2"
        ;;
    remove)
        if [ -z "${2:-}" ]; then
            echo "Error: Model name required"
            show_usage
        fi
        remove_model "$2"
        ;;
    info)
        if [ -z "${2:-}" ]; then
            echo "Error: Model name required"
            show_usage
        fi
        show_model_info "$2"
        ;;
    recommended)
        show_recommended
        ;;
    *)
        show_usage
        ;;
esac
