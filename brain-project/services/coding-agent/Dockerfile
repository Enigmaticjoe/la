FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY sandbox.py .
COPY executor.py .
COPY safety-rules.yaml .

# Create workspace directory
RUN mkdir -p /workspace && chmod 755 /workspace

# Create non-root user for code execution
RUN useradd -m -u 1000 coderunner && \
    chown -R coderunner:coderunner /workspace

# Expose API port
EXPOSE 5000

# Run as non-root user
USER coderunner

# Start the coding agent server
CMD ["python", "executor.py"]
