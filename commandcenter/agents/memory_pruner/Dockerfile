FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY pruner.py .

# Make executable
RUN chmod +x pruner.py

# Create log directory
RUN mkdir -p /var/log/jules_protocol

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run pruner
CMD ["python3", "pruner.py"]
