#!/bin/bash
################################################################################
# Document Ingestion Script for Open WebUI
# Bulk ingest documents into the knowledge base
################################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_usage() {
    echo "Usage: $0 <directory-path>"
    echo ""
    echo "This script ingests documents from a directory into Open WebUI."
    echo "Supported formats: PDF, DOCX, TXT, MD, CSV, JSON"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/documents"
    echo ""
    exit 1
}

if [ $# -eq 0 ]; then
    show_usage
fi

DOC_DIR="$1"

if [ ! -d "$DOC_DIR" ]; then
    echo "Error: Directory not found: $DOC_DIR"
    exit 1
fi

echo "================================================"
echo "   Document Ingestion Script"
echo "================================================"
echo ""

echo -e "${BLUE}[INFO]${NC} Document directory: $DOC_DIR"
echo -e "${BLUE}[INFO]${NC} Supported formats: PDF, DOCX, TXT, MD, CSV, JSON"
echo ""

# Count files
PDF_COUNT=$(find "$DOC_DIR" -type f -iname "*.pdf" | wc -l)
DOCX_COUNT=$(find "$DOC_DIR" -type f -iname "*.docx" | wc -l)
TXT_COUNT=$(find "$DOC_DIR" -type f -iname "*.txt" | wc -l)
MD_COUNT=$(find "$DOC_DIR" -type f -iname "*.md" | wc -l)
CSV_COUNT=$(find "$DOC_DIR" -type f -iname "*.csv" | wc -l)
JSON_COUNT=$(find "$DOC_DIR" -type f -iname "*.json" | wc -l)
TOTAL=$((PDF_COUNT + DOCX_COUNT + TXT_COUNT + MD_COUNT + CSV_COUNT + JSON_COUNT))

echo "Found documents:"
echo "  PDF: $PDF_COUNT"
echo "  DOCX: $DOCX_COUNT"
echo "  TXT: $TXT_COUNT"
echo "  MD: $MD_COUNT"
echo "  CSV: $CSV_COUNT"
echo "  JSON: $JSON_COUNT"
echo "  Total: $TOTAL"
echo ""

if [ $TOTAL -eq 0 ]; then
    echo -e "${YELLOW}[WARNING]${NC} No supported documents found"
    exit 0
fi

read -p "Do you want to continue with ingestion? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Ingestion cancelled"
    exit 0
fi

echo ""
echo -e "${BLUE}[INFO]${NC} Starting document ingestion..."
echo ""

# Create a temporary directory in the container
echo -e "${BLUE}[INFO]${NC} Copying documents to Open WebUI container..."
docker exec open-webui mkdir -p /tmp/ingest

# Copy documents to container
docker cp "$DOC_DIR/." open-webui:/tmp/ingest/

# Process documents (this is a placeholder - actual implementation depends on Open WebUI API)
echo -e "${BLUE}[INFO]${NC} Processing documents..."
echo -e "${YELLOW}[INFO]${NC} Note: Documents should be uploaded through the Open WebUI interface"
echo -e "${YELLOW}[INFO]${NC} Files are available in the container at: /tmp/ingest/"
echo ""

echo -e "${BLUE}[INFO]${NC} To ingest these documents:"
echo "  1. Open Open WebUI in your browser"
echo "  2. Navigate to Workspace → Knowledge"
echo "  3. Create a new collection or select existing"
echo "  4. Upload documents from /tmp/ingest/ inside the container"
echo "  5. Or use the API endpoint to bulk upload"
echo ""

echo -e "${GREEN}[SUCCESS]${NC} Documents copied to container"
echo ""
echo "Alternative: Use Open WebUI's API for bulk upload"
echo "See documentation: https://docs.openwebui.com"
