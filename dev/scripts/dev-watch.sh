#!/bin/bash
# Watch for file changes and automatically rebuild addon

set -e

ADDON_NAME="${1:-}"
INSTANCE="${2:-haos}"

if [ -z "$ADDON_NAME" ]; then
    echo "Usage: $0 <addon-name> [instance]"
    echo "Available instances: hadocker, hassdeb, haos"
    exit 1
fi

ADDON_DIR="$(dirname "$0")/../../$ADDON_NAME"
SCRIPT_DIR="$(dirname "$0")"

if [ ! -d "$ADDON_DIR" ]; then
    echo "Error: Addon directory $ADDON_DIR not found"
    exit 1
fi

echo "Watching $ADDON_NAME for changes..."
echo "Press Ctrl+C to stop"

# Initial build
"$SCRIPT_DIR/dev-build.sh" "$ADDON_NAME" "$INSTANCE"

# Watch for changes (requires inotify-tools on Linux or fswatch on macOS)
if command -v fswatch >/dev/null 2>&1; then
    # macOS with fswatch
    fswatch -o "$ADDON_DIR" --exclude="\.git" --exclude="\.dev-version" | while read f; do
        echo "Change detected, rebuilding..."
        "$SCRIPT_DIR/dev-build.sh" "$ADDON_NAME" "$INSTANCE"
        
        if [ "$INSTANCE" == "hadocker" ]; then
            # For hadocker, the build already deployed to addons directory
            echo "Addon updated in hadocker addons directory - test standalone deployment"
        elif [ "$INSTANCE" == "hassdeb" ]; then
            # For hassdeb, the build already deployed via Samba
            echo "Addon updated in hassdeb mount - check HA UI for updates"
        fi
    done
elif command -v inotifywait >/dev/null 2>&1; then
    # Linux with inotify-tools
    while inotifywait -r -e modify,create,delete --exclude '\.git|\.dev-version' "$ADDON_DIR"; do
        echo "Change detected, rebuilding..."
        "$SCRIPT_DIR/dev-build.sh" "$ADDON_NAME" "$INSTANCE"
        
        if [ "$INSTANCE" == "hadocker" ]; then
            # For hadocker, the build already deployed to addons directory
            echo "Addon updated in hadocker addons directory - test standalone deployment"
        elif [ "$INSTANCE" == "hassdeb" ]; then
            # For hassdeb, the build already deployed via Samba
            echo "Addon updated in hassdeb mount - check HA UI for updates"
        fi
    done
else
    echo "Error: Neither fswatch (macOS) nor inotifywait (Linux) found"
    echo "Install with:"
    echo "  macOS: brew install fswatch"
    echo "  Linux: sudo apt-get install inotify-tools"
    exit 1
fi