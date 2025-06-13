#!/bin/bash
# Test script for hass-mcp

echo "Testing hass-mcp directly..."
echo ""

# Test if the virtual environment exists
if [ ! -f /opt/hass-mcp/venv/bin/python ]; then
    echo "ERROR: Virtual environment not found at /opt/hass-mcp/venv/bin/python"
    exit 1
fi

# Test if the app module exists
if [ ! -f /opt/hass-mcp/app/__main__.py ]; then
    echo "ERROR: app module not found at /opt/hass-mcp/app/__main__.py"
    exit 1
fi

echo "Files found correctly."
echo ""

# Set environment variables
export HA_URL="${HA_URL:-http://supervisor/core}"
export HA_TOKEN="${HA_TOKEN:-$SUPERVISOR_TOKEN}"

echo "Environment:"
echo "  HA_URL: $HA_URL"
echo "  HA_TOKEN: ${HA_TOKEN:0:10}..." # Only show first 10 chars for security
echo ""

# Test the command directly
echo "Testing command: cd /opt/hass-mcp && /opt/hass-mcp/venv/bin/python -m app"
echo "Press Ctrl+C to stop..."
echo ""

cd /opt/hass-mcp && exec /opt/hass-mcp/venv/bin/python -m app