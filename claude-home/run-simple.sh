#!/usr/bin/with-contenv bashio

# Simple run script for testing

bashio::log.info "Claude Home starting..."

# Create settings directory
mkdir -p /root/.claude
mkdir -p /config/claude-config

# Get model from config
CLAUDE_MODEL=$(bashio::config 'claude_model' 'claude-3-5-haiku-20241022')
export ANTHROPIC_MODEL="$CLAUDE_MODEL"

# Create settings.json in correct location
cat > /root/.claude/settings.json << EOF
{
  "model": "$CLAUDE_MODEL"
}
EOF

bashio::log.info "Model set to: $CLAUDE_MODEL"

# Start web terminal
bashio::log.info "Starting web terminal on port 7681..."

exec ttyd \
    --port 7681 \
    --interface 0.0.0.0 \
    --writable \
    bash -c "echo 'Claude Home Terminal'; echo 'Run: claude auth'; echo ''; exec bash"