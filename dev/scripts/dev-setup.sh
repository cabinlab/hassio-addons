#!/bin/bash
# One-time setup script for development environment

set -e

SCRIPT_DIR="$(dirname "$0")"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"  # hassio-addons root

echo "Setting up Home Assistant addon development environment..."

# Make scripts executable
chmod +x "$SCRIPT_DIR"/*.sh

# Add to gitignore if not already present
cd "$ROOT_DIR"
if ! grep -q "\.dev-version" .gitignore 2>/dev/null; then
    echo "Updating .gitignore..."
    cat >> .gitignore << EOF

# Development files
.dev-version
config.yaml.dev
config.yaml.backup
*-dev-build/
*.tar.gz
EOF
fi

# Create git pre-commit hook to prevent committing dev versions
HOOK_FILE="$ROOT_DIR/.git/hooks/pre-commit"
if [ ! -f "$HOOK_FILE" ]; then
    echo "Creating git pre-commit hook..."
    mkdir -p "$ROOT_DIR/.git/hooks"
    cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash
# Prevent committing development version files

if git diff --cached --name-only | grep -q "\.dev-version"; then
    echo "Error: Attempting to commit .dev-version file"
    echo "These files should not be committed"
    exit 1
fi

# Check for dev version strings in config.yaml
for file in $(git diff --cached --name-only | grep "config.yaml$"); do
    if git diff --cached "$file" | grep -q "^+version:.*dev-"; then
        echo "Error: Attempting to commit development version in $file"
        echo "Please restore the original version number"
        exit 1
    fi
done

exit 0
EOF
    chmod +x "$HOOK_FILE"
fi

# Check for required tools
echo "Checking for required tools..."
if command -v docker >/dev/null 2>&1; then
    echo "✓ Docker found"
else
    echo "✗ Docker not found - please install Docker"
fi

if command -v docker-compose >/dev/null 2>&1; then
    echo "✓ Docker Compose found"
else
    echo "✗ Docker Compose not found - please install Docker Compose"
fi

if command -v fswatch >/dev/null 2>&1 || command -v inotifywait >/dev/null 2>&1; then
    echo "✓ File watcher found"
else
    echo "✗ File watcher not found"
    echo "  Install with:"
    echo "    macOS: brew install fswatch"
    echo "    Linux: sudo apt-get install inotify-tools"
fi

# Create hassd override if it doesn't exist
HASSD_OVERRIDE="$ROOT_DIR/../../hassd/docker-compose.override.yml"
if [ ! -f "$HASSD_OVERRIDE" ]; then
    echo "Note: docker-compose.override.yml created in hassd directory"
    echo "This file is used for development and should not be committed"
fi

echo ""
echo "Setup complete! Available commands:"
echo ""
echo "  ./dev/scripts/dev-build.sh <addon-name>     # Build addon with dev version"
echo "  ./dev/scripts/dev-watch.sh <addon-name>     # Watch and auto-rebuild"
echo "  ./dev/scripts/dev-deploy.sh <addon-name>    # Deploy to local HA"
echo "  ./dev/scripts/dev-clean.sh                  # Clean up dev artifacts"
echo ""
echo "Example workflow:"
echo "  cd hassio-addons"
echo "  ./dev/scripts/dev-watch.sh claude-home &    # Start watching in background"
echo "  # Make your changes to claude-home files"
echo "  # Changes will automatically rebuild and deploy"
echo ""