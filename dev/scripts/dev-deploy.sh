#!/bin/bash
# Deploy development addon to Home Assistant instance

set -e

ADDON_NAME="${1:-}"
INSTANCE="${2:-haos}"
ACTION="${3:-reload}"  # reload or restart

if [ -z "$ADDON_NAME" ]; then
    echo "Usage: $0 <addon-name> [instance] [reload|restart]"
    echo "Available instances: hadocker, hassdeb, haos"
    exit 1
fi

ADDON_DIR="$(dirname "$0")/../../$ADDON_NAME"

if [ ! -d "$ADDON_DIR" ]; then
    echo "Error: Addon directory $ADDON_DIR not found"
    exit 1
fi

cd "$ADDON_DIR"

# Read dev version
if [ ! -f ".dev-version" ]; then
    echo "Error: No .dev-version file found. Run dev-build.sh first."
    exit 1
fi

DEV_VERSION=$(cat .dev-version)

echo "Deploying $ADDON_NAME version $DEV_VERSION to $INSTANCE..."

if [ "$INSTANCE" == "hadocker" ]; then
    # For standalone container hadocker
    HADOCKER_DIR="$(dirname "$0")/../../../hadocker"
    
    echo "Deploying to hadocker (standalone container) environment"
    
    if [ -d "$HADOCKER_DIR" ]; then
        echo "Copying addon to hadocker addons directory..."
        mkdir -p "$HADOCKER_DIR/addons"
        cp -r "$ADDON_DIR" "$HADOCKER_DIR/addons/"
        echo "Addon deployed to hadocker addons directory"
        echo "Next steps:"
        echo "1. Addon available for standalone container testing"
        echo "2. Deploy as separate container alongside HA"
        echo "3. Test migration scenarios from supervised to standalone"
    else
        echo "Error: hadocker directory not found at $HADOCKER_DIR"
        echo "Make sure hadocker environment is set up"
        exit 1
    fi
    
elif [ "$INSTANCE" == "hassdeb" ]; then
    # For Debian Supervised instance via Samba
    HASSDEB_IP="${HASSDEB_IP:-10.0.0.40}"
    HASSDEB_PORT="${HASSDEB_PORT:-8123}"
    HASSDEB_DIR="$(dirname "$0")/../../../hacabin"
    
    echo "Deploying to hassdeb at $HASSDEB_IP:$HASSDEB_PORT"
    
    if [ -d "$HASSDEB_DIR" ]; then
        echo "Copying addon to hassdeb via Samba mount..."
        cp -r "$ADDON_DIR" "$HASSDEB_DIR/"
        echo "Addon deployed to hassdeb mount"
        echo "Next steps:"
        echo "1. Access HA at http://$HASSDEB_IP:$HASSDEB_PORT"
        echo "2. Go to Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates"
        echo "3. Update/install the addon version $DEV_VERSION"
    else
        echo "Error: hacabin directory not found at $HASSDEB_DIR"
        echo "Make sure Samba mount is active and accessible"
        exit 1
    fi
    
elif [ "$INSTANCE" == "haos" ]; then
    # For HAOS VirtualBox instance via Samba
    HAOS_IP="${HAOS_IP:-homeassistant.local}"
    HAOS_PORT="${HAOS_PORT:-8123}"
    HAOS_DIR="$(dirname "$0")/../../../haos"
    
    echo "Deploying to HAOS at $HAOS_IP:$HAOS_PORT"
    
    if [ -d "$HAOS_DIR" ]; then
        echo "Copying addon to haos via Samba mount..."
        cp -r "$ADDON_DIR" "$HAOS_DIR/"
        echo "Addon deployed to haos mount"
        echo "Next steps:"
        echo "1. Access HA at http://$HAOS_IP:$HAOS_PORT"
        echo "2. Go to Settings -> Add-ons -> Add-on Store -> ⋮ -> Check for updates"
        echo "3. Update/install the addon version $DEV_VERSION"
    else
        echo "Error: haos directory not found at $HAOS_DIR"
        echo "Make sure Samba mount is active and accessible"
        exit 1
    fi
fi

echo "Deployment complete!"