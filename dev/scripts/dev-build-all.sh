#!/bin/bash
# Build and deploy addon to all environments efficiently

set -e

ADDON_NAME="${1:-}"

if [ -z "$ADDON_NAME" ]; then
    echo "Usage: $0 <addon-name>"
    echo "Available addons:"
    ls -d ../../*/ | grep -v dev | grep -v hass-mcp | grep -v '\.git' | xargs -n1 basename
    exit 1
fi

ADDON_DIR="$(dirname "$0")/../../$ADDON_NAME"
if [ ! -d "$ADDON_DIR" ]; then
    echo "Error: Addon directory $ADDON_DIR not found"
    exit 1
fi

cd "$ADDON_DIR"

# Generate development version (shared across all builds)
DEV_VERSION="dev-$(date +%Y%m%d-%H%M%S)"
echo "$DEV_VERSION" > .dev-version

# Backup original config.yaml
cp config.yaml config.yaml.backup

# Update version in config.yaml temporarily
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s/^version:.*/version: \"$DEV_VERSION\"/" config.yaml
else
    # Linux
    sed -i "s/^version:.*/version: \"$DEV_VERSION\"/" config.yaml
fi

echo "Building $ADDON_NAME with version $DEV_VERSION for ALL environments..."

# Build Docker image once (shared for haos, hassdeb, and hadocker)
echo "Building Docker image..."
docker build -t "local/$ADDON_NAME:$DEV_VERSION" .

# Deploy to all environments in parallel
echo "Deploying to all environments..."

# Deploy to haos
(
    HAOS_DIR="$(dirname "$0")/../../../haos"
    if [ -d "$HAOS_DIR" ]; then
        echo "→ Deploying to haos..."
        cp -r . "$HAOS_DIR/$ADDON_NAME/"
        echo "✓ haos deployment complete"
    else
        echo "⚠ haos directory not found at $HAOS_DIR"
    fi
) &

# Deploy to hassdeb  
(
    HASSDEB_DIR="$(dirname "$0")/../../../hacabin"
    if [ -d "$HASSDEB_DIR" ]; then
        echo "→ Deploying to hassdeb..."
        cp -r . "$HASSDEB_DIR/$ADDON_NAME/"
        echo "✓ hassdeb deployment complete"
    else
        echo "⚠ hacabin directory not found at $HASSDEB_DIR"
    fi
) &

# Deploy to hadocker
(
    HADOCKER_DIR="$(dirname "$0")/../../../hadocker"
    SCRIPT_DIR="$(dirname "$0")"
    if [ -d "$HADOCKER_DIR" ]; then
        echo "→ Deploying to hadocker..."
        source "$SCRIPT_DIR/hadocker-template.sh"
        ensure_homeassistant_network
        generate_hadocker_compose "$ADDON_NAME" "$DEV_VERSION" "." "$HADOCKER_DIR"
        echo "✓ hadocker deployment complete"
    else
        echo "⚠ hadocker directory not found at $HADOCKER_DIR"
    fi
) &

# Wait for all parallel deployments to complete
wait

# Restore original config.yaml
mv config.yaml.backup config.yaml

echo ""
echo "🚀 ALL DEPLOYMENTS COMPLETE!"
echo "Version: $DEV_VERSION"
echo ""
echo "Access your environments:"
echo "• haos:     http://homeassistant.local:8123"
echo "• hassdeb:  http://10.0.0.40:8123" 
echo "• hadocker: cd hadocker/addons/$ADDON_NAME && docker compose up -d"
echo ""
echo "Next: Go to Settings → Add-ons → Add-on Store → ⋮ → Check for updates"