#!/bin/bash
#
# Quick Start Script for Self-Evolution System
#
# This script helps you get started with the self-evolution and auto-optimization features.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Brain AI Stack - Self-Evolution Setup"
echo "=========================================="
echo

# Check if we're in the right directory
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
    echo "Error: docker-compose.yml not found in $PROJECT_DIR"
    echo "Please run this script from the brain-project/scripts directory"
    exit 1
fi

# Create necessary directories
echo "Creating data directories..."
mkdir -p "$PROJECT_DIR/data/evolution"
mkdir -p "$PROJECT_DIR/backups"

# Set permissions
chmod 755 "$PROJECT_DIR/data/evolution"
chmod 755 "$PROJECT_DIR/backups"

echo "✓ Directories created"
echo

# Option 1: Build and start evolution container
echo "=========================================="
echo "Option 1: Run Evolution in Docker"
echo "=========================================="
echo
echo "Commands:"
echo
echo "  # Build the evolution container"
echo "  docker build -f $SCRIPT_DIR/Dockerfile.evolution -t brain-evolution:latest $SCRIPT_DIR"
echo
echo "  # Start evolution service"
echo "  docker compose -f $PROJECT_DIR/docker-compose.yml -f $SCRIPT_DIR/docker-compose.evolution.yml up -d evolution"
echo
echo "  # View evolution logs"
echo "  docker compose -f $PROJECT_DIR/docker-compose.yml -f $SCRIPT_DIR/docker-compose.evolution.yml logs -f evolution"
echo

# Option 2: Run scripts manually
echo "=========================================="
echo "Option 2: Run Scripts Manually"
echo "=========================================="
echo
echo "Commands:"
echo
echo "  # Install Python dependencies"
echo "  pip install -r $SCRIPT_DIR/requirements-evolution.txt"
echo
echo "  # Run self-evolution engine"
echo "  export OPENWEBUI_URL=http://localhost:8080"
echo "  export VLLM_URL=http://localhost:8000"
echo "  export QDRANT_URL=http://localhost:6333"
echo "  python $SCRIPT_DIR/self-evolve.py"
echo
echo "  # Run auto-optimizer (in another terminal)"
echo "  python $SCRIPT_DIR/auto-optimize.py"
echo

# Backup
echo "=========================================="
echo "Backup System"
echo "=========================================="
echo
echo "Commands:"
echo
echo "  # Run manual backup"
echo "  docker compose -f $PROJECT_DIR/docker-compose.yml -f $SCRIPT_DIR/docker-compose.evolution.yml run --rm backup"
echo
echo "  # Or run backup script directly"
echo "  $SCRIPT_DIR/backup.sh"
echo
echo "  # Schedule daily backups with cron:"
echo "  0 2 * * * cd $PROJECT_DIR && docker compose -f docker-compose.yml -f scripts/docker-compose.evolution.yml run --rm backup"
echo

# Monitoring
echo "=========================================="
echo "Monitoring Evolution"
echo "=========================================="
echo
echo "Commands:"
echo
echo "  # Watch evolution logs"
echo "  tail -f $PROJECT_DIR/data/evolution/evolution.log"
echo
echo "  # Watch optimization logs"
echo "  tail -f $PROJECT_DIR/data/evolution/auto-optimize.log"
echo
echo "  # Query evolution database"
echo "  sqlite3 $PROJECT_DIR/data/evolution/evolution.db"
echo

# Next steps
echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo
echo "1. Ensure your main Brain AI stack is running"
echo "2. Choose Option 1 (Docker) or Option 2 (Manual) above"
echo "3. Start the evolution services"
echo "4. Monitor logs to see the system learning"
echo "5. After 24 hours, check optimization recommendations"
echo
echo "For detailed documentation, see:"
echo "  $SCRIPT_DIR/README.md"
echo
echo "=========================================="

# Ask if user wants to build now
echo
read -p "Would you like to build the evolution container now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "Building evolution container..."
    docker build -f "$SCRIPT_DIR/Dockerfile.evolution" -t brain-evolution:latest "$SCRIPT_DIR"
    echo
    echo "✓ Build complete!"
    echo
    echo "To start the evolution service, run:"
    echo "  cd $PROJECT_DIR"
    echo "  docker compose -f docker-compose.yml -f scripts/docker-compose.evolution.yml up -d evolution"
    echo
fi
