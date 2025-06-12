#!/usr/bin/with-contenv bashio

# Simple run script with nice UI

bashio::log.info "Claude Home starting..."

# Create settings directory and move existing .claude if it exists
if [ -d /root/.claude ] && [ ! -L /root/.claude ]; then
    bashio::log.info "Moving existing .claude directory to persistent storage"
    cp -r /root/.claude /config/claude-config/
    rm -rf /root/.claude
fi

mkdir -p /config/claude-config/.claude
mkdir -p /config/claude-config

# Create symlink for .claude directory (where auth is actually stored!)
ln -sf /config/claude-config/.claude /root/.claude

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

# Check if credentials.json exists in home directory and copy to persistent storage
if [ -f "/root/.claude/.credentials.json" ] && [ ! -f "/config/claude-config/.claude/.credentials.json" ]; then
    bashio::log.info "Found credentials in /root/.claude/, copying to persistent storage"
    cp /root/.claude/.credentials.json /config/claude-config/.claude/
fi

# Debug: Check various possible auth locations
bashio::log.info "Checking for existing auth files..."
for location in \
    "/root/.claude.json" \
    "/root/.claude/.claude.json" \
    "/config/claude-config/.claude/.claude.json" \
    "/root/.config/claude/auth.json" \
    "/root/.config/anthropic/auth.json" \
    "/config/claude-config/.config/claude/auth.json"; do
    if [ -f "$location" ]; then
        bashio::log.info "Found auth file at: $location"
    fi
done

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

# Create settings.json in correct location (persistent)
cat > /config/claude-config/.claude/settings.json << EOF
{
  "model": "$CLAUDE_MODEL"
}
EOF

# Also create in /root/.claude if it's a symlink
if [ -L /root/.claude ]; then
    bashio::log.info "Settings saved to persistent storage via symlink"
fi

bashio::log.info "Model set to: $CLAUDE_MODEL"

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

# Check if authenticated by looking for Claude credential files
# Claude Code stores auth in ~/.claude/.credentials.json
if [ -f "/config/claude-config/.claude/.credentials.json" ] || [ -f "/root/.claude/.credentials.json" ]; then
    AUTH_FOUND=true
else
    AUTH_FOUND=false
fi

if [ "\$AUTH_FOUND" = "true" ]; then
    echo -e "                \${GREEN}***** Authenticated *****\${RESET}"
    echo ""
    echo "             Run 'claude' to start an interactive session"
    echo "             Run 'claude --help' to see all options"
else
    echo -e "              \${BRIGHT_ORANGE}¡¡¡¡¡ Not authenticated yet !!!!!\${RESET}"
    echo ""
    echo "             Run 'claude' and follow the prompts to login"
    echo ""
    echo "             Debug: After login, run: check-auth"
    echo "             This will search for auth files in all locations"
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

# Create a credential sync helper
cat > /usr/local/bin/sync-credentials << 'EOF'
#!/bin/bash
# Sync Claude credentials to persistent storage
if [ -f "/root/.claude/.credentials.json" ]; then
    cp /root/.claude/.credentials.json /config/claude-config/.claude/ 2>/dev/null && \
        echo "Credentials synced to persistent storage"
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

# Start web terminal
bashio::log.info "Starting web terminal on port 7681..."

exec ttyd \
    --port 7681 \
    --interface 0.0.0.0 \
    --writable \
    /tmp/startup.sh