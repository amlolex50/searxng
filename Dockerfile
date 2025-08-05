# SPDX-License-Identifier: AGPL-3.0-or-later
# Standard Dockerfile for Cloud Build compatibility

# Build client assets
FROM node:18-alpine as client

WORKDIR /app

# Copy the entire source tree first (needed for vite build)
COPY . .

# Change to client directory and install dependencies
WORKDIR /app/client/simple

# Install dependencies (use npm install if no package-lock.json)
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# Build the client assets (outputs to searx/static/themes/simple)
RUN npm run build

# Python runtime stage
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash searxng

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code with built client assets from previous stage
COPY --from=client --chown=searxng:searxng /app .

# Switch to non-root user
USER searxng

# Environment variables
ENV SEARXNG_SETTINGS_PATH=/app/searx/settings_cloudrun.yml
ENV HOST=0.0.0.0
ENV PORT=8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/healthz')" || exit 1

# Expose port
EXPOSE 8080

# Start the application
CMD ["python", "searx/webapp.py"]
