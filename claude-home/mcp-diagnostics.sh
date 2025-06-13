#!/usr/bin/with-contenv bashio

# MCP Diagnostics Script
bashio::log.info "=== MCP Configuration Diagnostics ==="

# Check all MCP config locations
bashio::log.info "Checking MCP configuration files:"
for loc in "/config/.mcp.json" "/root/.mcp.json" "$CLAUDE_CONFIG_DIR/.mcp.json" "$CLAUDE_CONFIG_DIR/.config/claude/.mcp.json"; do
    if [ -f "$loc" ]; then
        bashio::log.info "Found: $loc"
        jq -r '.mcpServers | keys[]' "$loc" 2>/dev/null | while read server; do
            bashio::log.info "  - Server: $server"
        done
    else
        bashio::log.info "Not found: $loc"
    fi
done

# Test hass-mcp directly
bashio::log.info ""
bashio::log.info "Testing hass-mcp directly:"
cd /opt/hass-mcp
export HA_URL="http://supervisor/core"
export HA_TOKEN="$SUPERVISOR_TOKEN"

# Test if module loads
if python3 -c "import app" 2>/dev/null; then
    bashio::log.info "✓ hass-mcp module loads successfully"
    
    # Test basic connection
    bashio::log.info "Testing HA connection..."
    python3 -c "
import asyncio
from app.hass import get_hass_version
async def test():
    try:
        version = await get_hass_version()
        print(f'✓ Connected to Home Assistant {version}')
    except Exception as e:
        print(f'✗ Connection failed: {e}')
asyncio.run(test())
" 2>&1 | while read line; do
        bashio::log.info "  $line"
    done
else
    bashio::log.error "✗ hass-mcp module failed to load"
fi

# Check native MCP endpoint
bashio::log.info ""
bashio::log.info "Testing native HA MCP endpoint:"
response=$(curl -s -w "\\nHTTP:%{http_code}" \
    -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
    "http://supervisor/core/mcp_server/sse" 2>&1 || true)
http_code=$(echo "$response" | grep "HTTP:" | cut -d: -f2)
bashio::log.info "  HTTP Response: $http_code"

# Check if mcp-remote is available
bashio::log.info ""
bashio::log.info "Checking mcp-remote availability:"
if npx -y mcp-remote --version 2>/dev/null; then
    bashio::log.info "✓ mcp-remote is available"
else
    bashio::log.info "✗ mcp-remote not available or failed to run"
fi

bashio::log.info "=== Diagnostics Complete ==="