FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY aishell.py .

# Make executable
RUN chmod +x aishell.py

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run shell
CMD ["python3", "aishell.py"]
