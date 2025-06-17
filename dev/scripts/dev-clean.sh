#!/bin/bash
# Clean up development artifacts

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"  # hassio-addons root

echo "Cleaning up development artifacts..."

# Remove .dev-version files
find "$ROOT_DIR" -name ".dev-version" -type f -delete 2>/dev/null || true

# Remove backup config files
find "$ROOT_DIR" -name "config.yaml.backup" -type f -delete 2>/dev/null || true
find "$ROOT_DIR" -name "config.yaml.dev" -type f -delete 2>/dev/null || true

# Remove exported images
find "$ROOT_DIR" -name "*-dev-*.tar.gz" -type f -delete 2>/dev/null || true

# Clean up Docker images
echo "Cleaning up development Docker images..."
docker images --format "{{.Repository}}:{{.Tag}}" | grep "^local/.*:dev-" | while read img; do
    echo "Removing $img"
    docker rmi "$img" 2>/dev/null || true
done

# Remove dangling images
docker image prune -f

echo "Cleanup complete!"