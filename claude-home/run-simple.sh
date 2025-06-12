#!/usr/bin/with-contenv bashio

# Simple run script with nice UI

bashio::log.info "Claude Home starting..."

# Set Claude config directory to persistent storage
export CLAUDE_CONFIG_DIR="/config/claude-config"
bashio::log.info "Set CLAUDE_CONFIG_DIR to: $CLAUDE_CONFIG_DIR"

# Create persistent directories first
mkdir -p /config/claude-config/.claude
mkdir -p /config/claude-config

# Remove any existing .claude directory/symlink to ensure clean symlink creation
if [ -e /root/.claude ] || [ -L /root/.claude ]; then
    bashio::log.info "Removing existing /root/.claude to create fresh symlink"
    rm -rf /root/.claude
fi

# Create symlink for .claude directory BEFORE Claude initializes
ln -sf /config/claude-config/.claude /root/.claude
bashio::log.info "Created symlink: /root/.claude -> /config/claude-config/.claude"

# If credentials exist in persistent storage, they'll now be available via symlink
if [ -f /config/claude-config/.claude/.credentials.json ]; then
    bashio::log.info "Found existing credentials in persistent storage"
    # Validate the credentials file is not empty
    if [ -s /config/claude-config/.claude/.credentials.json ]; then
        bashio::log.info "Credentials file is valid (non-empty)"
    else
        bashio::log.warning "Credentials file exists but is empty"
    fi
fi

# Create persistent auth storage for other potential locations
mkdir -p /config/claude-config/.config/claude
mkdir -p /config/claude-config/.config/anthropic
mkdir -p /root/.config

# Remove existing directory/symlink if it exists
if [ -e /root/.config/claude ] || [ -L /root/.config/claude ]; then
    bashio::log.info "Removing existing /root/.config/claude to create symlink"
    rm -rf /root/.config/claude
fi

# Create symlink for auth persistence
ln -sf /config/claude-config/.config/claude /root/.config/claude

# Also symlink anthropic directory in case auth goes there
if [ -e /root/.config/anthropic ] || [ -L /root/.config/anthropic ]; then
    rm -rf /root/.config/anthropic
fi
ln -sf /config/claude-config/.config/anthropic /root/.config/anthropic

# Ensure the symlinks were created (not directories)
if [ -L /root/.config/claude ]; then
    bashio::log.info "Claude symlink created successfully"
elif [ -d /root/.config/claude ]; then
    bashio::log.error "ERROR: /root/.config/claude is a directory, not a symlink!"
fi

if [ -L /root/.config/anthropic ]; then
    bashio::log.info "Anthropic symlink created successfully"
fi

# Verify symlink was created
if [ -L /root/.config/claude ]; then
    bashio::log.info "Authentication persistence configured - symlink created"
    bashio::log.info "Symlink points to: $(readlink -f /root/.config/claude)"
    
    # Debug: Check permissions
    bashio::log.info "Persistent dir permissions: $(ls -ld /config/claude-config/.config/claude)"
    
    # Debug: List contents
    bashio::log.info "Contents of persistent auth dir:"
    ls -la /config/claude-config/.config/claude/ 2>&1 | while read line; do
        bashio::log.info "  $line"
    done
else
    bashio::log.error "Failed to create auth persistence symlink"
    bashio::log.error "Check if /root/.config/claude exists: $(ls -la /root/.config/ 2>&1)"
fi

# Copy existing auth if found in old location
if [ -f "/config/claude-config/auth.json" ]; then
    bashio::log.info "Migrating old auth file to new location"
    cp /config/claude-config/auth.json /config/claude-config/.config/claude/
fi

# No need to check and copy - symlink handles this automatically
# Any credentials saved by Claude will go directly to persistent storage

# Debug: Check various possible auth locations
bashio::log.info "Checking for existing auth files..."
for location in \
    "/root/.claude/.credentials.json" \
    "/config/claude-config/.claude/.credentials.json" \
    "/root/.claude.json" \
    "/root/.claude/.claude.json" \
    "/root/.config/claude/auth.json" \
    "/root/.config/anthropic/auth.json"; do
    if [ -f "$location" ]; then
        bashio::log.info "Found auth file at: $location"
        # Show file size to ensure it's not empty
        size=$(stat -c%s "$location" 2>/dev/null || echo "0")
        bashio::log.info "  Size: $size bytes"
    fi
done

# Check symlink status
bashio::log.info "Checking symlink status:"
if [ -L "/root/.claude" ]; then
    target=$(readlink -f "/root/.claude")
    bashio::log.info "  /root/.claude -> $target (symlink OK)"
else
    bashio::log.error "  /root/.claude is NOT a symlink!"
fi

# Also search for any auth-related files
bashio::log.info "Searching for auth-related files..."
find /root -name "*auth*" -o -name "*credential*" -type f 2>/dev/null | while read file; do
    bashio::log.info "Found auth-related file: $file"
done

# Check for OAuth tokens or credentials
bashio::log.info "Searching for Claude OAuth/credential files..."
for pattern in "*token*" "*credential*" "*oauth*" "*.json"; do
    find /root/.config -name "$pattern" -type f 2>/dev/null | while read file; do
        bashio::log.info "Found potential auth file: $file"
    done
done

# Get model from config and map to actual model ID
MODEL_CHOICE=$(bashio::config 'claude_model' 'haiku')
case "$MODEL_CHOICE" in
    "haiku")
        CLAUDE_MODEL="claude-3-5-haiku-20241022"
        ;;
    "sonnet")
        CLAUDE_MODEL="sonnet"
        ;;
    "opus")
        CLAUDE_MODEL="default"
        ;;
    *)
        CLAUDE_MODEL="claude-3-5-haiku-20241022"
        ;;
esac
export ANTHROPIC_MODEL="$CLAUDE_MODEL"

# Create settings.json in Claude config directory
# Since CLAUDE_CONFIG_DIR is set to /config/claude-config,
# Claude will look for settings.json directly there
cat > /config/claude-config/settings.json << EOF
{
  "model": "$CLAUDE_MODEL"
}
EOF

# Also create in .claude subdirectory for backwards compatibility
mkdir -p /config/claude-config/.claude
cat > /config/claude-config/.claude/settings.json << EOF
{
  "model": "$CLAUDE_MODEL"
}
EOF

bashio::log.info "Settings saved to Claude config directory"

bashio::log.info "Model set to: $CLAUDE_MODEL"

# Validate Claude authentication if credentials exist
if [ -f "/root/.claude/.credentials.json" ]; then
    bashio::log.info "Validating Claude authentication..."
    # Use timeout to prevent hanging if auth is invalid
    if timeout 5 claude --version >/dev/null 2>&1; then
        bashio::log.info "Claude authentication validated successfully"
    else
        bashio::log.warning "Claude credentials exist but validation failed"
        bashio::log.warning "You may need to re-authenticate with 'claude auth'"
    fi
fi

# Get auto-start preference
AUTO_CLAUDE=$(bashio::config 'auto_claude' 'false')
bashio::log.info "Auto-start Claude: $AUTO_CLAUDE"

# Get notification settings
HA_NOTIFICATIONS=$(bashio::config 'ha_notifications' 'false')
NOTIFICATION_SERVICE=$(bashio::config 'notification_service' 'persistent_notification')
NOTIFY_SERVICES=""

# Discover available notification services if notifications are enabled
if [ "$HA_NOTIFICATIONS" = "true" ]; then
    bashio::log.info "Discovering available notification services..."
    
    # Try to get services from Home Assistant API
    if bashio::api.supervisor GET /core/api/services false &>/dev/null; then
        NOTIFY_SERVICES=$(bashio::api.supervisor GET /core/api/services false | \
            jq -r '.[] | select(.domain == "notify") | .services | keys[]' 2>/dev/null | \
            sed 's/^/notify./' | sort -u | tr '\n' ',' | sed 's/,$//')
        
        if [ -n "$NOTIFY_SERVICES" ]; then
            bashio::log.info "Found notification services: $NOTIFY_SERVICES"
            
            # Check if configured service is available
            if [ "$NOTIFICATION_SERVICE" != "custom" ] && [ "$NOTIFICATION_SERVICE" != "persistent_notification" ]; then
                if ! echo ",$NOTIFY_SERVICES," | grep -q ",$NOTIFICATION_SERVICE,"; then
                    bashio::log.warning "Configured service '$NOTIFICATION_SERVICE' not found in available services"
                fi
            fi
        else
            bashio::log.info "No notification services found, using default"
        fi
    else
        bashio::log.warning "Could not query Home Assistant services"
    fi
fi

# Check for MCP availability early
MCP_AVAILABLE="false"
# TODO: Need to find correct way to detect if MCP Server integration is installed
# For now, always false until we figure out the right detection method
# if bashio::api.supervisor GET /core/api/mcp false &>/dev/null 2>&1; then
#     MCP_AVAILABLE="true"
# fi

# Create startup script with ASCII header
cat > /tmp/startup.sh << EOF
#!/bin/bash

# Set Claude config directory to persistent storage
export CLAUDE_CONFIG_DIR="/config/claude-config"

# Change to a more appropriate working directory
cd /root

# Auto-start Claude setting
AUTO_CLAUDE="$AUTO_CLAUDE"

# Notification settings
HA_NOTIFICATIONS="$HA_NOTIFICATIONS"
NOTIFICATION_SERVICE="$NOTIFICATION_SERVICE"
NOTIFY_SERVICES="$NOTIFY_SERVICES"

# MCP status
MCP_AVAILABLE="$MCP_AVAILABLE"

# Colors
CYAN='\\033[38;2;79;195;193m'
BRIGHT_ORANGE='\\033[1;38;2;244;132;95m'
GREEN='\\033[0;32m'
RESET='\\033[0m'

clear

# ASCII Header
echo -e "\${CYAN}"
echo "  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗"
echo " ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝"
echo " ██║     ██║     ███████║██║   ██║██║  ██║█████╗  "
echo " ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  "
echo " ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗"
echo "  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝"
echo ""
echo "                    ██╗  ██╗ ██████╗ ███╗   ███╗███████╗"
echo "                    ██║  ██║██╔═══██╗████╗ ████║██╔════╝"
echo "                    ███████║██║   ██║██╔████╔██║█████╗  "
echo "                    ██╔══██║██║   ██║██║╚██╔╝██║██╔══╝  "
echo "                    ██║  ██║╚██████╔╝██║ ╚═╝ ██║███████╗"
echo "                    ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
echo -e "\${RESET}"
echo ""

# Check if authenticated by seeing if claude works without prompting for auth
# We'll use a simple test that should fail quickly if not authenticated
AUTH_FOUND=false

# Check if credentials file exists
if [ -f "/config/claude-config/.claude/.credentials.json" ] || [ -f "/root/.claude/.credentials.json" ]; then
    # Try to run claude with a timeout to see if it prompts for auth
    # If it exits with code 1, it likely needs auth
    # If it starts successfully (code 0 or timeout), auth is probably valid
    if timeout 2 claude --help 2>&1 | grep -q "login\\|auth\\|authenticate"; then
        # Claude is prompting for auth
        AUTH_FOUND=false
    else
        # Claude started without auth prompt - might be authenticated
        # This isn't perfect but better than always showing false
        AUTH_FOUND=true
    fi
else
    # No credentials file at all
    AUTH_FOUND=false
fi

if [ "\$AUTH_FOUND" = "true" ]; then
    echo -e "                \${GREEN}***** Authenticated *****\${RESET}"
    echo ""
    echo "             Run 'claude' to start an interactive session"
    echo "             Run 'claude --help' to see all options"
else
    # Check if we have stored credentials that aren't working
    if [ -f "/config/claude-config/.claude/.credentials.json" ]; then
        echo -e "              \${BRIGHT_ORANGE}¡¡¡¡¡ Authentication needed !!!!!\${RESET}"
        echo ""
        echo "             Previous session expired (container restarted)"
        echo "             Run 'claude' to start"
    else
        echo -e "              \${BRIGHT_ORANGE}¡¡¡¡¡ Welcome to Claude Home !!!!!\${RESET}"
        echo ""
        echo "             Run 'claude' to get started"
    fi
fi
echo ""
echo "             Model: \${ANTHROPIC_MODEL:-claude-3-5-haiku-20241022}"

# Show MCP status
if [ "\$MCP_AVAILABLE" = "true" ]; then
    echo "             MCP: \${GREEN}Connected to Home Assistant\${RESET}"
else
    echo "             MCP: Not available"
fi

# Show notification settings if enabled
if [ "\$HA_NOTIFICATIONS" = "true" ]; then
    echo ""
    echo "             Notifications: Enabled → \$NOTIFICATION_SERVICE"
    if [ -n "\$NOTIFY_SERVICES" ]; then
        echo "             Available: \$NOTIFY_SERVICES"
    fi
fi
echo ""

# Check if auto-start is enabled
if [ "\$AUTO_CLAUDE" = "true" ]; then
    echo "             Auto-starting Claude CLI..."
    echo ""
    exec claude
else
    exec bash
fi
EOF

chmod +x /tmp/startup.sh

# Create auth check helper script
cat > /usr/local/bin/check-auth << 'EOF'
#!/bin/bash
echo "=== Checking for Claude authentication files ==="
echo ""

echo "1. Searching ALL of /root for auth-related files:"
find /root -type f \( -name "*auth*" -o -name "*token*" -o -name "*credential*" -o -name "*oauth*" \) 2>/dev/null | while read f; do
    echo "  Found: $f"
    if [ -L "$f" ]; then
        echo "    -> Symlink to: $(readlink -f "$f")"
    fi
done

echo ""
echo "2. Checking Claude Code config locations:"
for dir in ~/.claude ~/.config/claude ~/.config/anthropic ~/.anthropic ~/.config/@anthropic-ai; do
    if [ -d "$dir" ]; then
        echo "  Directory exists: $dir"
        ls -la "$dir" | head -5
    fi
done

echo ""
echo "3. Checking npm config:"
npm config list | grep -i auth
npm config get userconfig
if [ -f ~/.npmrc ]; then
    echo "  .npmrc contents:"
    cat ~/.npmrc | grep -v "^#"
fi

echo ""
echo "4. Checking environment variables:"
env | grep -i "claude\|anthropic\|auth" | grep -v TOKEN

echo ""
echo "5. Checking process list for Claude:"
ps aux | grep -i claude | grep -v grep

echo ""
echo "6. Checking persistent storage:"
echo "  /config/claude-config/.claude/:"
ls -la /config/claude-config/.claude/ 2>/dev/null
echo "  /config/claude-config/.config/claude/:"
ls -la /config/claude-config/.config/claude/ 2>/dev/null
echo "  /config/claude-config/.config/anthropic/:"
ls -la /config/claude-config/.config/anthropic/ 2>/dev/null

echo ""
echo "7. Looking for .credentials.json specifically:"
find /root /config -name ".credentials.json" 2>/dev/null
echo ""
echo "8. Looking for .claude.json as fallback:"
find /root /config -name ".claude.json" 2>/dev/null
EOF

chmod +x /usr/local/bin/check-auth

# Create a helper to restore auth from stored credentials
cat > /usr/local/bin/restore-auth << 'EOF'
#!/bin/bash
echo "Attempting to restore authentication from stored credentials..."

if [ ! -f "/root/.claude/.credentials.json" ]; then
    echo "No credentials file found at /root/.claude/.credentials.json"
    exit 1
fi

# OAuth tokens cannot be used as API keys
echo "Unfortunately, Claude Code OAuth tokens cannot be restored this way."
echo ""
echo "Claude Code uses OAuth authentication which includes:"
echo "- Access tokens (for API calls)"
echo "- Refresh tokens (to get new access tokens)"
echo "- Session state (internal to Claude Code)"
echo ""
echo "After container restart, the session state is lost and cannot be restored"
echo "by simply having the token files. This is a known limitation."
echo ""
echo "Please run 'claude auth' to re-authenticate."
EOF

chmod +x /usr/local/bin/restore-auth

# Create a credential sync helper
cat > /usr/local/bin/sync-credentials << 'EOF'
#!/bin/bash
# Since we use symlinks, this is now just for verification
if [ -L "/root/.claude" ]; then
    if [ -f "/root/.claude/.credentials.json" ]; then
        echo "Credentials found via symlink (already persistent)"
    else
        echo "No credentials found"
    fi
else
    echo "WARNING: /root/.claude is not a symlink! Auth may not persist."
fi
EOF

chmod +x /usr/local/bin/sync-credentials

# Create a background process to periodically sync credentials
cat > /usr/local/bin/credential-sync-daemon << 'EOF'
#!/bin/bash
while true; do
    sleep 60  # Check every minute
    /usr/local/bin/sync-credentials >/dev/null 2>&1
done
EOF

chmod +x /usr/local/bin/credential-sync-daemon

# Start the credential sync daemon in background
/usr/local/bin/credential-sync-daemon &

# Create claude alias to use wrapper (optional - can be disabled if it causes issues)
# Uncomment the next line to enable the wrapper
# echo "alias claude='/usr/local/bin/claude-wrapper'" >> /etc/bash.bashrc

# Do NOT extract OAuth tokens and set as API keys - they are different!
# Claude Code uses OAuth for authentication, not API keys
# Setting ANTHROPIC_API_KEY with an OAuth token causes confusion

# Configure MCP servers in the persistent location
# This ensures Claude Code picks up the configuration
# Note: Directory already created above before symlink

# Create project-level MCP configuration
cat > /config/claude-config/.config/claude/.mcp.json << EOF
{
  "homeassistant": {
    "transport": "sse", 
    "url": "http://supervisor/core/api/mcp",
    "env": {
      "SUPERVISOR_TOKEN": "${SUPERVISOR_TOKEN}"
    }
  }
}
EOF

# Also create in the working directory for project scope
cat > /root/.mcp.json << EOF
{
  "homeassistant": {
    "transport": "sse", 
    "url": "http://supervisor/core/api/mcp",
    "env": {
      "SUPERVISOR_TOKEN": "${SUPERVISOR_TOKEN}"
    }
  }
}
EOF

bashio::log.info "MCP configuration files created in persistent and project locations"

# Do NOT pre-create CLAUDE.md - Claude Code needs to create it itself
# to properly link it to the memory system
bashio::log.info "Working directory set to /root for Claude memory support"

# Start web terminal
bashio::log.info "Starting web terminal on port 7681..."

exec ttyd \
    --port 7681 \
    --interface 0.0.0.0 \
    --writable \
    /tmp/startup.sh