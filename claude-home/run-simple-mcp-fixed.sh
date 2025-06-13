#!/usr/bin/with-contenv bashio

# MCP Configuration Section - Testing different approaches

# First, check if MCP Server integration is installed
bashio::log.info "Checking for Home Assistant MCP Server integration..."
MCP_AVAILABLE=false
if curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
   "http://supervisor/core/api/config/entries/entry" 2>/dev/null | grep -q "mcp_server"; then
    MCP_AVAILABLE=true
    bashio::log.info "MCP Server integration detected in Home Assistant"
else
    bashio::log.warning "MCP Server integration not found - MCP features may be limited"
fi

# Function to create MCP config
create_mcp_config() {
    local config_path="$1"
    local config_content="$2"
    
    cat > "$config_path" << EOF
${config_content}
EOF
    bashio::log.info "Created MCP config at: $config_path"
}

# Determine which MCP configuration to use
if [ "$MCP_AVAILABLE" = "true" ]; then
    # Try the mcp-proxy approach as recommended by HA docs
    MCP_CONFIG='{
  "mcpServers": {
    "homeassistant": {
      "command": "npx",
      "args": ["-y", "mcp-proxy", "sse", "http://supervisor/core/mcp_server/sse"],
      "env": {
        "API_ACCESS_TOKEN": "'"${SUPERVISOR_TOKEN}"'"
      }
    }
  }
}'
    bashio::log.info "Using mcp-proxy configuration for native HA MCP"
else
    # Fallback: Could use hass-mcp here if installed
    bashio::log.warning "No MCP configuration available - install HA MCP Server integration"
    MCP_CONFIG='{
  "mcpServers": {}
}'
fi

# Create MCP configuration in all necessary locations
create_mcp_config "/config/claude-config/.mcp.json" "$MCP_CONFIG"
create_mcp_config "/config/claude-config/.config/claude/.mcp.json" "$MCP_CONFIG"
create_mcp_config "/root/.mcp.json" "$MCP_CONFIG"

# Also create in working directory if different
if [ "$WORKING_DIR" != "/root" ] && [ "$WORKING_DIR" != "/config/claude-config" ]; then
    create_mcp_config "$WORKING_DIR/.mcp.json" "$MCP_CONFIG"
fi

# Create a test config with all options for manual testing
cat > /config/claude-config/mcp-test-configs.json << 'EOF'
{
  "test_configs": {
    "mcp_proxy_stdio": {
      "comment": "Recommended by HA docs",
      "command": "npx -y mcp-proxy sse http://supervisor/core/mcp_server/sse",
      "env": "API_ACCESS_TOKEN=${SUPERVISOR_TOKEN}"
    },
    "direct_sse": {
      "comment": "If Claude Code supports SSE directly",
      "transport": "sse",
      "url": "http://supervisor/core/mcp_server/sse",
      "headers": "Authorization: Bearer ${SUPERVISOR_TOKEN}"
    },
    "wrong_endpoint": {
      "comment": "What we had before (wrong)",
      "url": "http://supervisor/core/api/mcp"
    }
  }
}
EOF

bashio::log.info "MCP configuration complete. Test configs saved to /config/claude-config/mcp-test-configs.json"