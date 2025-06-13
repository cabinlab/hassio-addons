# MCP Setup for Claude Home

## Home Assistant MCP Integration

To use the Home Assistant MCP server with Claude Code, you need to:

1. **Create a Long-Lived Access Token** in Home Assistant:
   - Go to your profile (click your name in the sidebar)
   - Scroll to "Long-Lived Access Tokens"
   - Create a new token and copy it

2. **Configure the addon**:
   - Add these to your addon configuration:
   - `ha_url`: Your Home Assistant URL (e.g., `http://192.168.1.100:8123`)
   - `ha_token`: Your long-lived access token

3. **Important Notes**:
   - The supervisor proxy (`http://supervisor/core`) does NOT work with bearer tokens
   - You must use your actual Home Assistant URL
   - Both ha_url and ha_token must be provided for the integration to work

## Available MCP Servers

- **homeassistant**: Access to HA entities, automations, and services (requires configuration)
- **context7**: Documentation server for libraries and frameworks (works out of the box)

## Troubleshooting

If MCP servers show as "failed":
- Check your Home Assistant URL is accessible from the addon
- Verify your long-lived token is valid
- Run with `claude --debug` to see detailed error messages