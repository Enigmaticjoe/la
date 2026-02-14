#!/bin/bash
# Quick test script to validate the evolution system

echo "=========================================="
echo "Testing Self-Evolution System"
echo "=========================================="
echo

# Test 1: Python syntax
echo "Test 1: Validating Python syntax..."
python3 -m py_compile self-evolve.py auto-optimize.py
if [ $? -eq 0 ]; then
    echo "✓ Python syntax valid"
else
    echo "✗ Python syntax error"
    exit 1
fi
echo

# Test 2: Bash syntax
echo "Test 2: Validating Bash syntax..."
bash -n backup.sh setup-evolution.sh
if [ $? -eq 0 ]; then
    echo "✓ Bash syntax valid"
else
    echo "✗ Bash syntax error"
    exit 1
fi
echo

# Test 3: Check requirements
echo "Test 3: Checking requirements..."
if [ -f requirements-evolution.txt ]; then
    echo "✓ requirements-evolution.txt exists"
    echo "  Dependencies:"
    grep -v '^#' requirements-evolution.txt | grep -v '^$' | head -5
else
    echo "✗ requirements-evolution.txt missing"
    exit 1
fi
echo

# Test 4: Docker files
echo "Test 4: Checking Docker files..."
if [ -f Dockerfile.evolution ]; then
    echo "✓ Dockerfile.evolution exists"
else
    echo "✗ Dockerfile.evolution missing"
    exit 1
fi

if [ -f docker-compose.evolution.yml ]; then
    echo "✓ docker-compose.evolution.yml exists"
else
    echo "✗ docker-compose.evolution.yml missing"
    exit 1
fi
echo

# Test 5: Documentation
echo "Test 5: Checking documentation..."
docs=("README.md" "IMPLEMENTATION-SUMMARY.md" "QUICKREF.txt")
for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        echo "✓ $doc exists ($(wc -l < "$doc") lines)"
    else
        echo "✗ $doc missing"
        exit 1
    fi
done
echo

# Test 6: File permissions
echo "Test 6: Checking file permissions..."
if [ -x self-evolve.py ] && [ -x auto-optimize.py ] && [ -x backup.sh ]; then
    echo "✓ Scripts are executable"
else
    echo "✗ Some scripts not executable"
    exit 1
fi
echo

# Summary
echo "=========================================="
echo "All tests passed! ✓"
echo "=========================================="
echo
echo "Next steps:"
echo "  1. Build container: docker build -f Dockerfile.evolution -t brain-evolution ."
echo "  2. Deploy: docker compose -f ../docker-compose.yml -f docker-compose.evolution.yml up -d"
echo "  3. Monitor: docker compose logs -f evolution"
echo
echo "Files ready in: $(pwd)"
