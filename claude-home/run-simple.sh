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

# Create startup script with ASCII header
cat > /tmp/startup.sh << EOF
#!/bin/bash

# Auto-start Claude setting
AUTO_CLAUDE="$AUTO_CLAUDE"

# Colors
CYAN='\\033[38;2;79;195;193m'
BRIGHT_ORANGE='\\033[1;38;2;244;132;95m'
GREEN='\\033[0;32m'
RESET='\\033[0m'

clear

# ASCII Header
echo -e "${CYAN}"
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
echo -e "${RESET}"
echo ""

# Check if authenticated by looking for Claude credential files
# Claude Code stores auth in ~/.config/claude/auth.json
if [ -f "/root/.config/claude/auth.json" ] || [ -f "/root/.claude/credentials" ] || [ -f "/config/claude-config/auth.json" ]; then
    echo -e "                ${GREEN}***** Authenticated *****${RESET}"
    echo ""
    echo "             Run 'claude' to start an interactive session"
    echo "             Run 'claude --help' to see all options"
else
    echo -e "              ${BRIGHT_ORANGE}¡¡¡¡¡ Not authenticated yet !!!!!${RESET}"
    echo ""
    echo "             Run 'claude' and follow the prompts to login"
fi
echo ""
echo "             Model: ${ANTHROPIC_MODEL:-claude-3-5-haiku-20241022}"
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