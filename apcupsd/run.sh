#!/usr/bin/with-contenv bashio
set -e

CONFIG_PATH=/data/options.json
UPS_CONFIG_PATH=/etc/apcupsd/apcupsd.conf

VALID_SCRIPTS=(annoyme changeme commfailure commok doreboot doshutdown emergency failing loadlimit powerout onbattery offbattery mainsback remotedown runlimit timeout startselftest endselftest battdetach battattach)

# Input validation functions
validate_ups_name() {
    local name="$1"
    # UPS name should be alphanumeric with spaces, dashes, underscores (max 32 chars)
    if [[ -z "$name" || ${#name} -gt 32 || ! "$name" =~ ^[a-zA-Z0-9\ _-]+$ ]]; then
        bashio::log.error "UPS name must be 1-32 alphanumeric characters, spaces, dashes, or underscores"
        return 1
    fi
    return 0
}

validate_cable_type() {
    local cable="$1"
    # Valid cable types from apcupsd documentation
    case "$cable" in
        usb|simple|smart|ether|940-0024C|940-0095A|940-0095B|940-0095C|940-1524C|940-0128A|MAM-04-02-2000)
            return 0
            ;;
        *)
            bashio::log.error "Invalid cable type: $cable"
            return 1
            ;;
    esac
}

validate_ups_type() {
    local type="$1"
    # Valid UPS types from apcupsd documentation
    case "$type" in
        usb|net|apcsmart|dumb|pcnet|snmp|test|modbus)
            return 0
            ;;
        *)
            bashio::log.error "Invalid UPS type: $type"
            return 1
            ;;
    esac
}

validate_device_path() {
    local device="$1"
    # Device can be empty, or must be a valid device path or IP
    if [[ -n "$device" ]]; then
        # Check if it's a device path or IP address
        if [[ ! "$device" =~ ^(/dev/|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}) ]]; then
            bashio::log.error "Device must be empty, a /dev/ path, or IP address"
            return 1
        fi
    fi
    return 0
}

# Sanitize config value for safe file injection
sanitize_config_value() {
    local value="$1"
    # Remove potentially dangerous characters
    echo "$value" | sed 's/[;&|`$(){}]/\\_/g' | tr -d '\n\r'
}

# Get and validate configuration
bashio::log.info "Loading APC UPS configuration..."

NAME=$(jq --raw-output ".name" $CONFIG_PATH)
CABLE=$(jq --raw-output ".cable" $CONFIG_PATH)
TYPE=$(jq --raw-output ".type" $CONFIG_PATH)
DEVICE=$(jq --raw-output ".device" $CONFIG_PATH)
BATTERY_LEVEL=$(jq --raw-output ".battery_level" $CONFIG_PATH)
MINUTES_ON_BATTERY=$(jq --raw-output ".timeout_minutes" $CONFIG_PATH)
AUTO_DISCOVERY=$(jq --raw-output ".auto_discovery" $CONFIG_PATH)

# Validate all inputs
error=0

if ! validate_ups_name "$NAME"; then
    error=1
fi

if ! validate_cable_type "$CABLE"; then
    error=1
fi

if ! validate_ups_type "$TYPE"; then
    error=1
fi

if ! validate_device_path "$DEVICE"; then
    error=1
fi

if [[ $error -eq 1 ]]; then
    bashio::log.error "Configuration validation failed. Please check your settings."
    exit 1
fi

# Configure apcupsd with sanitized values
bashio::log.info "Configuring apcupsd..."

if [[ -n "$NAME" ]]; then
    sanitized_name=$(sanitize_config_value "$NAME")
    sed -i "s/^#\?UPSNAME\( .*\)\?\$/UPSNAME $sanitized_name/g" $UPS_CONFIG_PATH
    bashio::log.info "UPS name set to: $NAME"
fi

if [[ -n "$CABLE" ]]; then
    sed -i "s/^#\?UPSCABLE\( .*\)\?\$/UPSCABLE $CABLE/g" $UPS_CONFIG_PATH
    bashio::log.info "Cable type set to: $CABLE"
fi

if [[ -n "$TYPE" ]]; then
    sed -i "s/^#\?UPSTYPE\( .*\)\?\$/UPSTYPE $TYPE/g" $UPS_CONFIG_PATH
    bashio::log.info "UPS type set to: $TYPE"
fi

if [[ -n "$DEVICE" ]]; then
    sanitized_device=$(sanitize_config_value "$DEVICE")
    sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE $sanitized_device/g" $UPS_CONFIG_PATH
    bashio::log.info "Device set to: $DEVICE"
else
    sed -i "s/^#\?DEVICE\( .*\)\?\$//g" $UPS_CONFIG_PATH
    bashio::log.info "Device auto-detection enabled"
fi

# Configure apcupsd settings
if [[ -n "$BATTERY_LEVEL" && "$BATTERY_LEVEL" != "null" ]]; then
    sed -i "s/^#\?BATTERYLEVEL\( .*\)\?\$/BATTERYLEVEL $BATTERY_LEVEL/g" $UPS_CONFIG_PATH
    bashio::log.info "Battery level threshold set to: $BATTERY_LEVEL%"
fi

if [[ -n "$MINUTES_ON_BATTERY" && "$MINUTES_ON_BATTERY" != "null" ]]; then
    sed -i "s/^#\?MINUTES\( .*\)\?\$/MINUTES $MINUTES_ON_BATTERY/g" $UPS_CONFIG_PATH
    bashio::log.info "Minutes on battery before shutdown set to: $MINUTES_ON_BATTERY"
fi


# Copy custom scripts with validation
bashio::log.info "Checking for custom event scripts..."
script_count=0

for script in "${VALID_SCRIPTS[@]}"; do
    script_path="/share/apcupsd/scripts/$script"
    if [[ -f "$script_path" ]]; then
        # Validate script file
        if [[ -r "$script_path" && $(stat -c%s "$script_path") -le 65536 ]]; then
            cp "$script_path" "/etc/apcupsd/$script"
            chmod 755 "/etc/apcupsd/$script"
            bashio::log.info "Copied custom $script script"
            ((script_count++))
        else
            bashio::log.warning "Skipping invalid script: $script (not readable or too large)"
        fi
    fi
done

if [[ $script_count -gt 0 ]]; then
    bashio::log.info "Loaded $script_count custom event scripts"
fi

# Copy email configuration with validation
if [[ -f "/share/apcupsd/msmtprc" ]]; then
    if [[ -r "/share/apcupsd/msmtprc" && $(stat -c%s "/share/apcupsd/msmtprc") -le 4096 ]]; then
        cp /share/apcupsd/msmtprc /etc/
        chmod 600 /etc/msmtprc
        bashio::log.info "Email configuration loaded"
    else
        bashio::log.warning "Skipping invalid msmtprc file"
    fi
fi

if [[ -f "/share/apcupsd/aliases" ]]; then
    if [[ -r "/share/apcupsd/aliases" && $(stat -c%s "/share/apcupsd/aliases") -le 1024 ]]; then
        cp /share/apcupsd/aliases /etc/
        bashio::log.info "Email aliases loaded"
    else
        bashio::log.warning "Skipping invalid aliases file"
    fi
fi

# Copy scripts
cp /scripts/ups-power-control.sh /usr/local/bin/
cp /scripts/auto-discovery.sh /usr/local/bin/
chmod +x /usr/local/bin/ups-power-control.sh /usr/local/bin/auto-discovery.sh

# Start syslog daemon for logging
bashio::log.info "Starting syslog daemon..."
syslogd -n -O - &

# Start apcupsd daemon
bashio::log.info "Starting APC UPS daemon..."
/sbin/apcupsd -b &

# Wait for apcupsd to be ready
sleep 5

# Run auto-discovery if enabled
if [[ "$AUTO_DISCOVERY" == "true" ]]; then
    bashio::log.info "Starting auto-discovery for Home Assistant integration..."
    /usr/local/bin/auto-discovery.sh &
else
    bashio::log.info "Auto-discovery disabled - skipping integration setup"
fi

# Monitor for Home Assistant service calls
bashio::log.info "Starting UPS power control service monitor..."

while true; do
    # Check for service calls via Home Assistant API
    if bashio::services.available "ups_shutdown_return"; then
        delay=$(bashio::services.get "ups_shutdown_return" "delay" "20")
        bashio::log.info "Received ups_shutdown_return service call with delay: $delay"
        /usr/local/bin/ups-power-control.sh shutdown_return "$delay"
    fi
    
    if bashio::services.available "ups_load_off"; then
        delay=$(bashio::services.get "ups_load_off" "delay" "10")
        bashio::log.info "Received ups_load_off service call with delay: $delay"
        /usr/local/bin/ups-power-control.sh load_off "$delay"
    fi
    
    if bashio::services.available "ups_load_on"; then
        delay=$(bashio::services.get "ups_load_on" "delay" "5")
        bashio::log.info "Received ups_load_on service call with delay: $delay"
        /usr/local/bin/ups-power-control.sh load_on "$delay"
    fi
    
    if bashio::services.available "ups_reboot"; then
        off_delay=$(bashio::services.get "ups_reboot" "off_delay" "10")
        on_delay=$(bashio::services.get "ups_reboot" "on_delay" "30")
        bashio::log.info "Received ups_reboot service call"
        /usr/local/bin/ups-power-control.sh reboot "$off_delay" "$on_delay"
    fi
    
    if bashio::services.available "ups_emergency_kill"; then
        bashio::log.warning "Received ups_emergency_kill service call"
        /usr/local/bin/ups-power-control.sh emergency_kill
    fi
    
    sleep 5
done
