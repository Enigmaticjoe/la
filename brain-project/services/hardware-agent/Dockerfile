FROM python:3.11-slim

WORKDIR /app

# Install system dependencies for ROCm monitoring
RUN apt-get update && apt-get install -y \
    curl \
    lm-sensors \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY monitor.py .
COPY rocm-control.py .
COPY optimizer.py .
COPY metrics.py .
COPY config.yaml .

# Create data directory
RUN mkdir -p /app/data/metrics

# Expose API port
EXPOSE 5001

# Start the hardware agent server
CMD ["python", "monitor.py"]
