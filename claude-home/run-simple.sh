#!/usr/bin/with-contenv bashio

# Simple run script with nice UI

bashio::log.info "Claude Home starting..."

# Create settings directory
mkdir -p /root/.claude
mkdir -p /config/claude-config

# Get model from config and map to actual model ID
MODEL_CHOICE=$(bashio::config 'claude_model' 'Haiku - RECOMMENDED for Home Assistant')
case "$MODEL_CHOICE" in
    "Haiku - RECOMMENDED for Home Assistant")
        CLAUDE_MODEL="claude-3-5-haiku-20241022"
        ;;
    "Sonnet - More powerful and 4x cost")
        CLAUDE_MODEL="sonnet"
        ;;
    "Opus - Most powerful and up to 19x cost")
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

# Create startup script with ASCII header
cat > /tmp/startup.sh << 'EOF'
#!/bin/bash

# Colors
CYAN='\033[38;2;79;195;193m'
BRIGHT_ORANGE='\033[1;38;2;244;132;95m'
GREEN='\033[0;32m'
RESET='\033[0m'

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

exec bash
EOF

chmod +x /tmp/startup.sh

# Start web terminal
bashio::log.info "Starting web terminal on port 7681..."

exec ttyd \
    --port 7681 \
    --interface 0.0.0.0 \
    --writable \
    /tmp/startup.sh