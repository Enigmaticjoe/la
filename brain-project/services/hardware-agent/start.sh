#!/bin/bash
# Quick start script for hardware monitoring agent

set -e

echo "================================================"
echo "Hardware Monitoring Agent - Quick Start"
echo "================================================"

# Check Python version
echo "Checking Python version..."
python3 --version

# Check if virtual environment should be created
if [ ! -d "venv" ]; then
    echo ""
    read -p "Create virtual environment? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Creating virtual environment..."
        python3 -m venv venv
        source venv/bin/activate
        echo "Installing dependencies..."
        pip install -r requirements.txt
    fi
else
    echo "Activating virtual environment..."
    source venv/bin/activate
fi

# Create data directories
echo "Creating data directories..."
mkdir -p data/metrics logs

# Check for config file
if [ ! -f "config.yaml" ]; then
    echo "ERROR: config.yaml not found!"
    exit 1
fi

echo ""
echo "Configuration:"
echo "  - Metrics storage: $(grep 'data_dir:' config.yaml | awk '{print $2}')"
echo "  - Collection interval: $(grep 'interval:' config.yaml | head -1 | awk '{print $2}')s"
echo "  - Retention: $(grep 'retention_days:' config.yaml | awk '{print $2}') days"

# Check for ROCm
echo ""
if command -v rocm-smi &> /dev/null; then
    echo "✓ ROCm detected: $(rocm-smi --version 2>/dev/null | head -1 || echo 'installed')"
else
    echo "⚠ ROCm not found - will use fallback metrics"
fi

# Environment variables
echo ""
echo "Environment variables (optional):"
echo "  GPU_TEMP_THRESHOLD=${GPU_TEMP_THRESHOLD:-80}"
echo "  VRAM_THRESHOLD=${VRAM_THRESHOLD:-90}"
echo "  CPU_THRESHOLD=${CPU_THRESHOLD:-90}"
echo "  MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-90}"

echo ""
echo "================================================"
echo "Starting Hardware Monitoring Agent..."
echo "================================================"
echo ""
echo "Server will be available at:"
echo "  - Health: http://localhost:5000/health"
echo "  - Metrics: http://localhost:5000/api/v1/metrics"
echo "  - Prometheus: http://localhost:5000/metrics"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start the server
exec python3 monitor.py
