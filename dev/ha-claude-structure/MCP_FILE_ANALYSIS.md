# MCP Configuration File Analysis

## UPDATE: Fixed Configuration (Working)

After troubleshooting, the following changes were made to fix the MCP issues:

1. **Removed homeassistant-native block** - This was failing and not needed
2. **Changed command format for hass-mcp** - Fixed to use `bash -c` format
3. **Renamed "homeassistant" to "hass-mcp"** - To match our codebase naming

### Working Configuration:
```json
{
  "mcpServers": {
    "hass-mcp": {
      "command": "bash",
      "args": ["-c", "cd /opt/hass-mcp && exec /opt/hass-mcp/venv/bin/python -m app"],
      "env": {
        "HA_URL": "http://10.0.0.40:8123",
        "HA_TOKEN": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      }
    },
    "context7": {
      "command": "npx",
      "args": ["-y", "@upstash/context7-mcp"]
    }
  }
}
```

### Files Updated:
- ✅ `/homeassistant/.mcp.json` - PRIMARY (project scope, highest priority)
- ✅ `/homeassistant/claude-config/.mcp.json` - Secondary
- ⚠️ `/homeassistant/claude-config/.config/claude/.mcp.json` - Not updated due to SSH issues
- ❓ `/root/.mcp.json` (in container) - Status unknown

---

# Original Analysis

## File Locations (from host perspective)

1. `/homeassistant/.mcp.json`
   - **Container path**: `/config/.mcp.json`
   - **Scope**: Project (working directory)
   - **Priority**: HIGHEST - This overrides all others
   - **Purpose**: Project-specific MCP servers

2. `/homeassistant/claude-config/.mcp.json`
   - **Container path**: `/config/claude-config/.mcp.json`
   - **Scope**: Unclear - possibly user scope
   - **Purpose**: Created by run-simple.sh

3. `/homeassistant/claude-config/.config/claude/.mcp.json`
   - **Container path**: `/config/claude-config/.config/claude/.mcp.json`
   - **Scope**: Likely redundant
   - **Purpose**: Created by run-simple.sh "just in case"

4. `/root/.mcp.json` (in container)
   - **Container path**: `/root/.mcp.json`
   - **Scope**: Root's home directory
   - **Purpose**: Created by run-simple.sh for "backward compatibility"

## Key Findings

- All files are identical (same MD5 hash)
- The working directory is `/config` 
- CLAUDE_CONFIG_DIR is `/config/claude-config`
- Claude Code will use project scope first (highest priority)

## Likely Redundant Files

Based on Claude Code's documented behavior:
- `/homeassistant/claude-config/.config/claude/.mcp.json` - Probably not used
- One of either `/homeassistant/claude-config/.mcp.json` or `/root/.mcp.json` - Depends on how Claude Code handles user scope with CLAUDE_CONFIG_DIR set

## The Real Problem (FIXED)

All files had the wrong command format for hass-mcp:
```json
"command": "/opt/hass-mcp/venv/bin/python",
"args": ["-m", "app"],
```

This was fixed to:
```json
"command": "bash",
"args": ["-c", "cd /opt/hass-mcp && exec /opt/hass-mcp/venv/bin/python -m app"],
```

The key issue was that hass-mcp needs to run from its directory (`/opt/hass-mcp`) for imports to work correctly. The `bash -c` wrapper with `cd` ensures the working directory is correct before launching Python.