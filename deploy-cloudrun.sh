#!/bin/bash
# SPDX-License-Identifier: AGPL-3.0-or-later
# Google Cloud Run deployment script for SearXNG

set -e

# Configuration
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-$(gcloud config get-value project)}
REGION=${REGION:-us-central1}
SERVICE_NAME=${SERVICE_NAME:-searxng}
IMAGE_NAME="gcr.io/${PROJECT_ID}/searxng:latest"

# Generate a secure secret key if not provided
SECRET_KEY=${SEARXNG_SECRET_KEY:-$(openssl rand -hex 32)}

echo "🚀 Deploying SearXNG to Google Cloud Run"
echo "Project: ${PROJECT_ID}"
echo "Region: ${REGION}"
echo "Service: ${SERVICE_NAME}"
echo "Image: ${IMAGE_NAME}"

# Build and push the container image
echo "📦 Building container image..."
gcloud builds submit \
  --tag "${IMAGE_NAME}" \
  --dockerfile=Dockerfile.cloudrun \
  --project="${PROJECT_ID}"

# Deploy to Cloud Run
echo "🌐 Deploying to Cloud Run..."
gcloud run deploy "${SERVICE_NAME}" \
  --image="${IMAGE_NAME}" \
  --region="${REGION}" \
  --platform=managed \
  --allow-unauthenticated \
  --port=8080 \
  --cpu=1 \
  --memory=512Mi \
  --timeout=30s \
  --max-instances=10 \
  --concurrency=80 \
  --set-env-vars="SEARXNG_SECRET_KEY=${SECRET_KEY}" \
  --set-env-vars="SEARXNG_INSTANCE_NAME=SearXNG Cloud API" \
  --set-env-vars="SEARXNG_DEBUG=false" \
  --project="${PROJECT_ID}"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "${SERVICE_NAME}" \
  --region="${REGION}" \
  --project="${PROJECT_ID}" \
  --format='value(status.url)')

echo "✅ Deployment complete!"
echo "🔗 Service URL: ${SERVICE_URL}"
echo "🔍 Test search: ${SERVICE_URL}/search?q=test&format=json"
echo "❤️  Health check: ${SERVICE_URL}/healthz"
echo "⚙️  Config endpoint: ${SERVICE_URL}/config"

# Test the deployment
echo "🧪 Testing deployment..."
if curl -s "${SERVICE_URL}/healthz" | grep -q "OK"; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
    exit 1
fi

echo "🎉 SearXNG is now running on Cloud Run!"
echo "📝 Remember to:"
echo "   - Configure your domain/DNS if needed"
echo "   - Set up monitoring and alerting"
echo "   - Review security settings for production use"
