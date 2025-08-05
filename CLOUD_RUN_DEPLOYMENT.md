# SearXNG Cloud Run Deployment Guide

This guide provides everything needed to deploy SearXNG as a production-ready API on Google Cloud Run.

## Quick Start

1. **Prerequisites**
   ```bash
   # Install Google Cloud SDK
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   
   # Enable required APIs
   gcloud services enable cloudbuild.googleapis.com run.googleapis.com
   ```

2. **Deploy with one command**
   ```bash
   chmod +x deploy-cloudrun.sh
   ./deploy-cloudrun.sh
   ```

## Files Added/Modified

### New Files
- `Dockerfile.cloudrun` - Optimized container for Cloud Run
- `searx/settings_cloudrun.yml` - Cloud Run specific configuration
- `deploy-cloudrun.sh` - Automated deployment script
- `cloudbuild.yaml` - CI/CD configuration
- `CLOUD_RUN_DEPLOYMENT.md` - This documentation

### Modified Files
- `searx/webapp.py` - Added Cloud Run environment variable support
- `searx/settings_loader.py` - Added environment override functionality

## Configuration

### Environment Variables

The following environment variables can be set for Cloud Run deployment:

| Variable | Description | Default |
|----------|-------------|---------|
| `SEARXNG_SECRET_KEY` | **Required** - Flask secret key | Must be set |
| `SEARXNG_INSTANCE_NAME` | Display name for the instance | "SearXNG Cloud API" |
| `SEARXNG_DEBUG` | Enable debug mode | false |
| `SEARXNG_BIND_ADDRESS` | Bind address | "0.0.0.0" |
| `SEARXNG_PORT` | Port number | 8080 |
| `PORT` | Cloud Run port override | 8080 |
| `HOST` | Cloud Run host override | "0.0.0.0" |

### Security

- **Secret Key**: Always set `SEARXNG_SECRET_KEY` to a secure random value
- **CORS**: Configured for API access with `Access-Control-Allow-Origin: *`
- **Public Instance**: Enabled for API usage

## API Usage

### Endpoints

- **Search**: `GET/POST /search?q=QUERY&format=json`
- **Health**: `GET /healthz`
- **Config**: `GET /config`
- **Autocomplete**: `GET /autocompleter?q=PARTIAL_QUERY`

### Example API Calls

```bash
# Basic search
curl "https://your-service-url/search?q=python&format=json"

# Search with parameters
curl "https://your-service-url/search?q=machine+learning&format=json&categories=general&safesearch=1"

# Health check
curl "https://your-service-url/healthz"
```

### JavaScript Integration

```javascript
const SEARXNG_API = 'https://your-service-url';

async function search(query) {
  const params = new URLSearchParams({
    q: query,
    format: 'json',
    categories: 'general'
  });
  
  const response = await fetch(`${SEARXNG_API}/search?${params}`);
  const data = await response.json();
  return data.results;
}

// Usage
search('artificial intelligence').then(results => {
  console.log(results);
});
```

## Deployment Options

### Option 1: Automated Script
```bash
./deploy-cloudrun.sh
```

### Option 2: Manual gcloud Commands
```bash
# Build image
gcloud builds submit --tag gcr.io/PROJECT_ID/searxng:latest --dockerfile=Dockerfile.cloudrun

# Deploy to Cloud Run
gcloud run deploy searxng \
  --image gcr.io/PROJECT_ID/searxng:latest \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars SEARXNG_SECRET_KEY=$(openssl rand -hex 32)
```

### Option 3: CI/CD with Cloud Build
```bash
# Set up build trigger
gcloud builds triggers create github \
  --repo-name=searxng \
  --repo-owner=YOUR_USERNAME \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

## Production Considerations

### Security
- Remove `--allow-unauthenticated` for private APIs
- Use Cloud IAP for authentication
- Set up Cloud Armor for DDoS protection
- Rotate secret keys regularly

### Performance
- Adjust `--cpu` and `--memory` based on load
- Set `--max-instances` for cost control
- Enable request/response caching
- Use Cloud CDN for static assets

### Monitoring
- Enable Cloud Run metrics
- Set up alerting for errors/latency
- Monitor search engine response times
- Track API usage patterns

### Cost Optimization
- Set appropriate `--concurrency` (default: 80)
- Use `--min-instances=0` for cost savings
- Monitor and adjust resource allocation
- Consider regional deployment for global users

## Troubleshooting

### Common Issues

1. **Secret Key Error**
   ```
   Error: server.secret_key is not changed
   ```
   Solution: Set `SEARXNG_SECRET_KEY` environment variable

2. **Port Binding Issues**
   ```
   Error: Address already in use
   ```
   Solution: Cloud Run automatically sets `PORT` environment variable

3. **CORS Errors**
   ```
   Error: Access-Control-Allow-Origin
   ```
   Solution: CORS is pre-configured in `settings_cloudrun.yml`

### Debugging

```bash
# View logs
gcloud run services logs read searxng --region=us-central1

# Check service status
gcloud run services describe searxng --region=us-central1

# Test locally
docker build -f Dockerfile.cloudrun -t searxng-test .
docker run -p 8080:8080 -e SEARXNG_SECRET_KEY=test searxng-test
```

## API Response Format

### Search Response
```json
{
  "query": "python programming",
  "number_of_results": 10,
  "results": [
    {
      "title": "Python.org",
      "url": "https://python.org",
      "content": "Official Python website...",
      "engine": "duckduckgo",
      "category": "general"
    }
  ],
  "suggestions": ["python tutorial", "python guide"],
  "corrections": [],
  "infoboxes": []
}
```

### Error Response
```json
{
  "error": "No query provided"
}
```

## Support

For issues specific to this Cloud Run deployment:
1. Check the logs: `gcloud run services logs read searxng`
2. Verify environment variables are set correctly
3. Test the health endpoint: `/healthz`
4. Review the configuration in `settings_cloudrun.yml`

For general SearXNG issues, refer to the [official documentation](https://docs.searxng.org/).
