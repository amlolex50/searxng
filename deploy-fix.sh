#!/bin/bash

# SearXNG Cloud Run Deployment Script - API Fix
# This script deploys the fixed version that allows API requests

set -e

echo "🚀 Deploying SearXNG with API fixes to Cloud Run..."

# Set project variables
PROJECT_ID="teachaisearch"
SERVICE_NAME="teachaisearch"
REGION="us-central1"

# Generate a secure secret key for production
SECRET_KEY=$(openssl rand -base64 32)

echo "📦 Building and deploying to Cloud Run..."

# Deploy with the fixed configuration
gcloud run deploy $SERVICE_NAME \
  --source . \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 300 \
  --concurrency 80 \
  --max-instances 10 \
  --set-env-vars="SEARXNG_SECRET_KEY=$SECRET_KEY" \
  --set-env-vars="SEARXNG_SETTINGS_PATH=/app/searx/settings_cloudrun.yml" \
  --set-env-vars="SEARXNG_LIMITER_CFG_PATH=/app/limiter.toml"

echo "✅ Deployment complete!"
echo "🔑 Secret key set: ${SECRET_KEY:0:8}..."
echo "🌐 Your API should now be accessible at:"
echo "   https://teachaisearch-403836129705.us-central1.run.app/search?q=test&format=json"
