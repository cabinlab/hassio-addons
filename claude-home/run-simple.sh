#!/usr/bin/with-contenv bashio

# Simple run script with nice UI

bashio::log.info "Claude Home starting..."

# Create settings directory
mkdir -p /root/.claude
mkdir -p /config/claude-config

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

# Create settings.json in correct location
cat > /root/.claude/settings.json << EOF
{
  "model": "$CLAUDE_MODEL"
}
EOF

bashio::log.info "Model set to: $CLAUDE_MODEL"

# Get auto-start preference
AUTO_CLAUDE=$(bashio::config 'auto_claude' 'false')
bashio::log.info "Auto-start Claude: $AUTO_CLAUDE"

# Get notification settings
HA_NOTIFICATIONS=$(bashio::config 'ha_notifications' 'false')
NOTIFICATION_SERVICE=$(bashio::config 'notification_service' 'persistent_notification')

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

# Create startup script with ASCII header
cat > /tmp/startup.sh << EOF
#!/bin/bash

# Auto-start Claude setting
AUTO_CLAUDE="$AUTO_CLAUDE"

# Notification settings
HA_NOTIFICATIONS="$HA_NOTIFICATIONS"
NOTIFICATION_SERVICE="$NOTIFICATION_SERVICE"
NOTIFY_SERVICES="$NOTIFY_SERVICES"

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
# Claude Code stores auth in ~/.config/claude/auth.json
if [ -f "/root/.config/claude/auth.json" ] || [ -f "/root/.claude/credentials" ] || [ -f "/config/claude-config/auth.json" ]; then
    echo -e "                \${GREEN}***** Authenticated *****\${RESET}"
    echo ""
    echo "             Run 'claude' to start an interactive session"
    echo "             Run 'claude --help' to see all options"
else
    echo -e "              \${BRIGHT_ORANGE}¡¡¡¡¡ Not authenticated yet !!!!!\${RESET}"
    echo ""
    echo "             Run 'claude' and follow the prompts to login"
fi
echo ""
echo "             Model: \${ANTHROPIC_MODEL:-claude-3-5-haiku-20241022}"

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

# Start web terminal
bashio::log.info "Starting web terminal on port 7681..."

exec ttyd \
    --port 7681 \
    --interface 0.0.0.0 \
    --writable \
    /tmp/startup.sh