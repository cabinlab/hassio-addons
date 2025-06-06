#!/usr/bin/with-contenv bashio

# Initialize monitoring environment
init_environment() {
    # Ensure monitoring data directory exists with proper permissions
    mkdir -p /config/claude-watchdog
    chmod 700 /config/claude-watchdog
    
    # Create subdirectories for different data types
    mkdir -p /config/claude-watchdog/{insights,patterns,costs,logs}
    
    # Set environment variables
    export CLAUDE_WATCHDOG_DATA="/config/claude-watchdog"
    export HOME="/root"
    
    # Read configuration from Home Assistant
    local claude_model=$(bashio::config 'claude_model' 'claude-3-5-haiku-20241022')
    local check_interval=$(bashio::config 'check_interval' '30')
    local insight_threshold=$(bashio::config 'insight_threshold' '0.8')
    local max_daily_calls=$(bashio::config 'max_daily_api_calls' '1000')
    local cost_limit=$(bashio::config 'cost_limit_daily' '1.00')
    local enable_learning=$(bashio::config 'enable_learning' 'true')
    
    # Export configuration as environment variables
    export ANTHROPIC_MODEL="$claude_model"
    export WATCHDOG_CHECK_INTERVAL="$check_interval"
    export WATCHDOG_INSIGHT_THRESHOLD="$insight_threshold"
    export WATCHDOG_MAX_DAILY_CALLS="$max_daily_calls"
    export WATCHDOG_COST_LIMIT="$cost_limit"
    export WATCHDOG_ENABLE_LEARNING="$enable_learning"
    
    # Get monitoring scope as JSON array
    local monitoring_scope=$(bashio::config 'monitoring_scope')
    export WATCHDOG_MONITORING_SCOPE="$monitoring_scope"
    
    # Notification service
    local notification_service=$(bashio::config 'notification_service' 'persistent_notification')
    export WATCHDOG_NOTIFICATION_SERVICE="$notification_service"
    
    bashio::log.info "Claude Watchdog configured with model: $claude_model"
    bashio::log.info "Check interval: ${check_interval}s, Cost limit: \$${cost_limit}/day"
}

# Setup Home Assistant API access
setup_ha_access() {
    bashio::log.info "Setting up Home Assistant API access..."
    
    # Get Home Assistant details
    export HASSIO_TOKEN="${HASSIO_TOKEN}"
    export HA_URL="http://supervisor/core"
    
    # Test API connectivity
    if curl -s -H "Authorization: Bearer ${HASSIO_TOKEN}" "${HA_URL}/api/" > /dev/null; then
        bashio::log.info "Home Assistant API connection successful"
    else
        bashio::log.error "Failed to connect to Home Assistant API"
        exit 1
    fi
}

# Start the monitoring service
start_monitoring_service() {
    bashio::log.info "Starting Claude Watchdog monitoring service..."
    
    # Log environment information for debugging
    bashio::log.info "Environment variables:"
    bashio::log.info "ANTHROPIC_MODEL=${ANTHROPIC_MODEL}"
    bashio::log.info "WATCHDOG_CHECK_INTERVAL=${WATCHDOG_CHECK_INTERVAL}"
    bashio::log.info "WATCHDOG_COST_LIMIT=${WATCHDOG_COST_LIMIT}"
    
    # Start the Python monitoring application
    cd /app
    exec python3 main.py
}

# Main execution
main() {
    bashio::log.info "Initializing Claude Watchdog add-on..."
    
    init_environment
    setup_ha_access
    start_monitoring_service
}

# Execute main function
main "$@"