# GitHub Container Registry (GHCR) Setup Guide

## Prerequisites
- GitHub account
- Docker installed
- GitHub CLI (optional but recommended)

## 1. Create Personal Access Token (PAT)
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate a new token with these scopes:
   - `write:packages`
   - `read:packages`
   - `delete:packages`

## 2. Docker Login Command
```bash
# Use the PAT as password
echo "YOUR_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

## 3. Multi-arch Build Commands
```bash
# Ensure buildx is available
docker buildx create --use

# Build and push multi-arch image
docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t ghcr.io/cabinlab/claude-home:latest \
    --push \
    .
```

## 4. Push Commands (Manual)
```bash
# Tag image
docker tag claude-home:latest ghcr.io/cabinlab/claude-home:latest

# Push to registry
docker push ghcr.io/cabinlab/claude-home:latest
```

## 5. Home Assistant Add-on Image Reference
In `config.yaml` or Dockerfile:
```yaml
image: ghcr.io/cabinlab/claude-home:{VERSION}
```

## Important Notes
- Always use version tags in production
- Rotate PAT tokens periodically
- Use GitHub Actions for automated builds when possible