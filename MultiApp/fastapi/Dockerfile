# Use a lightweight Python base image
FROM python:3.11-slim

# Set environment variables for better performance and logging
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Set working directory
WORKDIR /app

# Copy and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application source code
COPY . .

# Create non-root user and set ownership
RUN adduser --system --group appuser
RUN chown -R appuser:appuser /app
USER appuser

# Expose app port
EXPOSE 8989

# Start the server with Hypercorn
CMD ["hypercorn", "main:app", "--bind", "0.0.0.0:8989"]

