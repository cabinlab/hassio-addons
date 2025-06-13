#!/usr/bin/with-contenv bashio

# This is a complete rewrite of the MCP configuration section
# Place this after line 490 in run-simple.sh

# Get Home Assistant configuration for hass-mcp
HA_URL=$(bashio::config 'ha_url' '')
HA_TOKEN=$(bashio::config 'ha_token' '')

# Check if user provided HA configuration
USE_HASS_MCP=false
if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
    bashio::log.info "Home Assistant URL and token provided - hass-mcp will be configured"
    USE_HASS_MCP=true
else
    if [ -n "$HA_URL" ] || [ -n "$HA_TOKEN" ]; then
        bashio::log.warning "Both ha_url and ha_token must be provided for hass-mcp"
    fi
fi

# First check if HA MCP Server integration is available
bashio::log.info "Checking for Home Assistant MCP Server integration..."
MCP_ENDPOINT_TEST=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    -H "Accept: text/event-stream" \
    "http://supervisor/core/mcp_server/sse" 2>&1 || true)
MCP_HTTP_CODE=$(echo "$MCP_ENDPOINT_TEST" | grep "HTTP_CODE:" | cut -d: -f2)

if [ "$MCP_HTTP_CODE" = "200" ] || [ "$MCP_HTTP_CODE" = "404" ]; then
    bashio::log.info "MCP Server endpoint found (HTTP $MCP_HTTP_CODE)"
    USE_MCP_PROXY=true
else
    bashio::log.warning "MCP Server endpoint not available (HTTP $MCP_HTTP_CODE)"
    USE_MCP_PROXY=false
fi

# Create MCP configuration based on what's available
bashio::log.info "Creating MCP configuration..."

# Build the JSON dynamically based on available services
MCP_JSON='{"mcpServers":{'

# Add native HA MCP if available
if [ "$USE_MCP_PROXY" = "true" ]; then
    MCP_JSON="${MCP_JSON}\"homeassistant-native\":{\"command\":\"npx\",\"args\":[\"-y\",\"mcp-remote\",\"http://supervisor/core/mcp_server/sse\",\"--header\",\"Authorization:\${AUTH_HEADER}\"],\"env\":{\"AUTH_HEADER\":\"Bearer ${SUPERVISOR_TOKEN}\"}}"
    NEED_COMMA=true
fi

# Add hass-mcp if configured
if [ "$USE_HASS_MCP" = "true" ]; then
    [ "${NEED_COMMA}" = "true" ] && MCP_JSON="${MCP_JSON},"
    MCP_JSON="${MCP_JSON}\"homeassistant\":{\"command\":\"/bin/bash\",\"args\":[\"-c\",\"cd /opt/hass-mcp && /opt/hass-mcp/venv/bin/python -m app\"],\"env\":{\"HA_URL\":\"${HA_URL}\",\"HA_TOKEN\":\"${HA_TOKEN}\"}}"
    NEED_COMMA=true
fi

# Always add context7
[ "${NEED_COMMA}" = "true" ] && MCP_JSON="${MCP_JSON},"
MCP_JSON="${MCP_JSON}\"context7\":{\"command\":\"npx\",\"args\":[\"-y\",\"@upstash/context7-mcp\"]}"

MCP_JSON="${MCP_JSON}}}"

# Write to all locations
echo "$MCP_JSON" > /config/claude-config/.mcp.json
echo "$MCP_JSON" > /config/claude-config/.config/claude/.mcp.json
echo "$MCP_JSON" > /root/.mcp.json

# Also create in working directory if different
if [ "$WORKING_DIR" != "/root" ] && [ "$WORKING_DIR" != "/config/claude-config" ]; then
    echo "$MCP_JSON" > "$WORKING_DIR/.mcp.json"
    bashio::log.info "MCP config also created in working directory: $WORKING_DIR"
fi

# Log what was configured
bashio::log.info "MCP servers configured:"
[ "$USE_MCP_PROXY" = "true" ] && bashio::log.info "  - homeassistant-native: Native HA MCP (SSE transport)"
[ "$USE_HASS_MCP" = "true" ] && bashio::log.info "  - homeassistant: hass-mcp (direct API access)"
bashio::log.info "  - context7: Documentation server"
bashio::log.info "Use /mcp command in Claude Code to connect"