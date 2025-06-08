#!/usr/bin/with-contenv bashio
set -e

# Auto-Discovery Script for APC UPS Daemon Integration
# Automatically configures Home Assistant's native apcupsd integration

LOG_PREFIX="[AUTO-DISCOVERY]"

log_info() {
    bashio::log.info "$LOG_PREFIX $1"
}

log_warning() {
    bashio::log.warning "$LOG_PREFIX $1"
}

log_error() {
    bashio::log.error "$LOG_PREFIX $1"
}

# Get the correct add-on hostname from Supervisor
get_addon_hostname() {
    local addons_response addon_hostname
    
    log_info "Detecting add-on hostname..."
    
    # Get list of running add-ons from Supervisor
    addons_response=$(curl -s -f \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        "http://supervisor/addons" 2>/dev/null || echo "error")
    
    if [[ "$addons_response" == "error" ]]; then
        log_warning "Could not get add-ons list from Supervisor"
        return 1
    fi
    
    # Find our add-on (slug contains "apcupsd") and get its full slug
    addon_hostname=$(echo "$addons_response" | jq -r '.data.addons[] | select(.slug | contains("apcupsd")) | .slug' | head -1)
    
    if [[ -n "$addon_hostname" && "$addon_hostname" != "null" ]]; then
        log_info "Detected add-on hostname: $addon_hostname"
        echo "$addon_hostname"
        return 0
    else
        log_warning "Could not detect add-on hostname, falling back to 'apcupsd'"
        echo "apcupsd"
        return 1
    fi
}

# Check if apcupsd integration is already configured
check_existing_integration() {
    local response
    
    log_info "Checking for existing apcupsd integration..."
    
    # Query config entries via Supervisor API
    response=$(curl -s -f \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        "http://supervisor/core/api/config/config_entries" 2>/dev/null || echo "error")
    
    if [[ "$response" == "error" ]]; then
        log_warning "Could not check existing integrations via API"
        return 1
    fi
    
    # Check if apcupsd domain exists in config entries
    if echo "$response" | jq -r '.[].domain' | grep -q "apcupsd"; then
        log_info "APC UPS Daemon integration already configured"
        return 0
    else
        log_info "No existing apcupsd integration found"
        return 1
    fi
}

# Set up apcupsd integration via Supervisor API
setup_apcupsd_integration() {
    local flow_response config_response addon_hostname
    
    log_info "Setting up APC UPS Daemon integration..."
    
    # Get the correct add-on hostname
    addon_hostname=$(get_addon_hostname)
    
    # Step 1: Start config flow
    flow_response=$(curl -s -f \
        -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        "http://supervisor/core/api/config/config_entries/flow" \
        -d '{
            "handler": "apcupsd",
            "show_advanced_options": false
        }' 2>/dev/null || echo "error")
    
    if [[ "$flow_response" == "error" ]]; then
        log_error "Failed to start apcupsd integration config flow"
        return 1
    fi
    
    # Extract flow_id from response
    local flow_id
    flow_id=$(echo "$flow_response" | jq -r '.flow_id // empty')
    
    if [[ -z "$flow_id" ]]; then
        log_error "Could not get flow_id from config flow response"
        return 1
    fi
    
    log_info "Config flow started with ID: $flow_id"
    
    # Step 2: Configure with detected add-on hostname
    log_info "Configuring integration with hostname: $addon_hostname"
    config_response=$(curl -s -f \
        -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        "http://supervisor/core/api/config/config_entries/flow/$flow_id" \
        -d "{
            \"host\": \"$addon_hostname\",
            \"port\": 3551
        }" 2>/dev/null || echo "error")
    
    if [[ "$config_response" == "error" ]]; then
        log_error "Failed to configure apcupsd integration"
        return 1
    fi
    
    log_info "APC UPS Daemon integration configured successfully!"
    log_info "Host: apcupsd, Port: 3551"
    
    return 0
}

# Alternative: Add to configuration.yaml (recommended method)
setup_yaml_integration() {
    local config_file="/config/configuration.yaml" addon_hostname
    
    log_info "Adding apcupsd configuration to configuration.yaml..."
    
    # Get the correct add-on hostname
    addon_hostname=$(get_addon_hostname)
    
    # Check if configuration.yaml exists
    if [[ ! -f "$config_file" ]]; then
        log_warning "configuration.yaml not found, creating basic config"
        cat > "$config_file" << EOF
# Home Assistant Configuration
homeassistant:

# APC UPS Daemon Integration (Auto-configured by add-on)
apcupsd:
  host: "$addon_hostname"
  port: 3551
EOF
    else
        # Check if apcupsd is already configured
        if grep -q "^apcupsd:" "$config_file"; then
            log_info "apcupsd already configured in configuration.yaml"
            return 0
        fi
        
        # Add apcupsd configuration
        cat >> "$config_file" << EOF

# APC UPS Daemon Integration (Auto-configured by add-on)
apcupsd:
  host: "$addon_hostname"
  port: 3551
EOF
    fi
    
    log_info "apcupsd configuration added to configuration.yaml"
    
    # Try to reload core configuration to pick up changes
    log_info "Attempting to reload Home Assistant configuration..."
    curl -s -f \
        -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        "http://supervisor/core/api/services/homeassistant/reload_config_entry" >/dev/null 2>&1
    
    return 0
}

# Send notification to Home Assistant
send_notification() {
    local message="$1"
    
    curl -s -f \
        -X POST \
        -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
        -H "Content-Type: application/json" \
        "http://supervisor/core/api/services/persistent_notification/create" \
        -d "{
            \"message\": \"$message\",
            \"title\": \"APC UPS Add-on\",
            \"notification_id\": \"apcupsd_addon_discovery\"
        }" >/dev/null 2>&1
}

# Wait for Home Assistant to be ready
wait_for_homeassistant() {
    local max_attempts=30
    local attempt=0
    
    log_info "Waiting for Home Assistant to be ready..."
    
    while [[ $attempt -lt $max_attempts ]]; do
        if curl -s -f \
            -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
            "http://supervisor/core/api/states" >/dev/null 2>&1; then
            log_info "Home Assistant is ready"
            return 0
        fi
        
        ((attempt++))
        sleep 10
    done
    
    log_warning "Timeout waiting for Home Assistant to be ready"
    return 1
}

# Main auto-discovery function
main() {
    log_info "Starting APC UPS Daemon auto-discovery..."
    
    # Wait for Home Assistant to be available
    if ! wait_for_homeassistant; then
        log_error "Home Assistant not available, skipping auto-discovery"
        return 1
    fi
    
    # Check if integration already exists
    if check_existing_integration; then
        log_info "Auto-discovery complete - integration already configured"
        return 0
    fi
    
    # Use configuration.yaml method (more reliable)
    if setup_yaml_integration; then
        send_notification "APC UPS configuration added to configuration.yaml. The apcupsd sensors will be available after Home Assistant restart."
        log_info "Auto-discovery complete - configuration added to YAML"
        return 0
    fi
    
    # Fall back to API method if YAML fails
    log_warning "YAML method failed, trying API method..."
    if setup_apcupsd_integration; then
        send_notification "APC UPS Daemon integration automatically configured! Check Settings > Devices & Services."
        log_info "Auto-discovery complete - integration configured via API"
        return 0
    fi
    
    local addon_hostname
    addon_hostname=$(get_addon_hostname)
    
    log_error "Auto-discovery failed - manual integration setup required"
    send_notification "APC UPS Add-on is running on $addon_hostname:3551. Please manually add the APC UPS Daemon integration in Settings > Devices & Services using this hostname."
    
    return 1
}

# Run auto-discovery if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi