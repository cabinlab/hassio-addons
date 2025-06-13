#!/bin/bash
# This shows the changes needed in run-simple.sh

# Add this after line 488 (before "# Configure MCP servers"):

# Get Home Assistant configuration for hass-mcp
HA_URL=$(bashio::config 'ha_url' '')
HA_TOKEN=$(bashio::config 'ha_token' '')

# Check if user provided HA configuration
if [ -n "$HA_URL" ] && [ -n "$HA_TOKEN" ]; then
    bashio::log.info "Home Assistant URL and token provided for hass-mcp"
    # Update all occurrences of:
    # "HA_URL": "http://supervisor/core",
    # to:
    # "HA_URL": "${HA_URL}",
    
    # And update all occurrences of:
    # "HA_TOKEN": "${SUPERVISOR_TOKEN}"
    # to:
    # "HA_TOKEN": "${HA_TOKEN}"
    
    # Also change the command to use bash -c to ensure proper directory:
    # "command": "/opt/hass-mcp/venv/bin/python",
    # to:
    # "command": "/bin/bash",
    # "args": ["-c", "cd /opt/hass-mcp && /opt/hass-mcp/venv/bin/python -m app"],
else
    # Remove the homeassistant MCP server from the configuration
    # Or log that it won't be available
    bashio::log.info "No Home Assistant credentials provided - hass-mcp will not be available"
fi