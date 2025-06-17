#!/bin/bash
# Development build script for Home Assistant addons
# This script builds addons with development versions without affecting git

set -e

ADDON_NAME="${1:-}"
INSTANCE="${2:-haos}"  # haos, hassdeb, or hadocker

if [ -z "$ADDON_NAME" ]; then
    echo "Usage: $0 <addon-name> [instance]"
    echo "Available instances: hadocker, hassdeb, haos"
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

# Generate development version
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

echo "Building $ADDON_NAME with version $DEV_VERSION..."

# Build based on instance type
if [ "$INSTANCE" == "hadocker" ]; then
    # For standalone container development
    echo "Building for hadocker (standalone container) deployment..."
    
    # Build Docker image
    docker build -t "local/$ADDON_NAME:$DEV_VERSION" .
    
    # Process template and generate hadocker deployment
    HADOCKER_DIR="$(dirname "$0")/../../../hadocker"
    SCRIPT_DIR="$(dirname "$0")"
    
    if [ -d "$HADOCKER_DIR" ]; then
        # Source template processing functions
        source "$SCRIPT_DIR/hadocker-template.sh"
        
        # Ensure Docker network exists
        ensure_homeassistant_network
        
        # Generate compose file from template
        echo "Generating hadocker compose file..."
        generate_hadocker_compose "$ADDON_NAME" "$DEV_VERSION" "." "$HADOCKER_DIR"
        
        echo "Hadocker deployment ready at $HADOCKER_DIR/addons/$ADDON_NAME/"
        echo "To start: cd $HADOCKER_DIR/addons/$ADDON_NAME && docker compose up -d"
    else
        echo "Warning: hadocker directory not found at $HADOCKER_DIR"
        echo "Make sure hadocker environment is set up"
    fi
elif [ "$INSTANCE" == "hassdeb" ]; then
    # For Debian Supervised deployment via Samba
    echo "Building for hassdeb (Debian Supervised) deployment..."
    docker build -t "local/$ADDON_NAME:$DEV_VERSION" .
    
    # Copy addon directory to hassdeb mount
    HASSDEB_DIR="$(dirname "$0")/../../../hacabin"
    if [ -d "$HASSDEB_DIR" ]; then
        echo "Copying addon to hassdeb mount..."
        cp -r . "$HASSDEB_DIR/$ADDON_NAME/"
        echo "Addon copied to $HASSDEB_DIR/$ADDON_NAME/"
    else
        echo "Warning: hacabin directory not found at $HASSDEB_DIR"
        echo "Make sure Samba mount is active"
    fi
else
    # For HAOS VirtualBox deployment via Samba
    echo "Building for HAOS deployment..."
    docker build -t "local/$ADDON_NAME:$DEV_VERSION" .
    
    # Copy addon directory to haos mount
    HAOS_DIR="$(dirname "$0")/../../../haos"
    if [ -d "$HAOS_DIR" ]; then
        echo "Copying addon to haos mount..."
        cp -r . "$HAOS_DIR/$ADDON_NAME/"
        echo "Addon copied to $HAOS_DIR/$ADDON_NAME/"
    else
        echo "Warning: haos directory not found at $HAOS_DIR"
        echo "Make sure Samba mount is active"
    fi
fi

# Restore original config.yaml
mv config.yaml.backup config.yaml

echo "Development build complete!"