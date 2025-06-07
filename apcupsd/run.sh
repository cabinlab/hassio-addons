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
MINUTES_ON_BATTERY=$(jq --raw-output ".minutes_on_battery" $CONFIG_PATH)
MAX_TIME_ON_BATTERY=$(jq --raw-output ".max_time_on_battery" $CONFIG_PATH)
KILL_DELAY=$(jq --raw-output ".kill_delay" $CONFIG_PATH)
NETWORK_PORT=$(jq --raw-output ".network_port" $CONFIG_PATH)
NETWORK_TIMEOUT=$(jq --raw-output ".network_timeout" $CONFIG_PATH)

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

# Configure common apcupsd settings
if [[ -n "$BATTERY_LEVEL" && "$BATTERY_LEVEL" != "null" ]]; then
    sed -i "s/^#\?BATTERYLEVEL\( .*\)\?\$/BATTERYLEVEL $BATTERY_LEVEL/g" $UPS_CONFIG_PATH
    bashio::log.info "Battery level threshold set to: $BATTERY_LEVEL%"
fi

if [[ -n "$MINUTES_ON_BATTERY" && "$MINUTES_ON_BATTERY" != "null" ]]; then
    sed -i "s/^#\?MINUTES\( .*\)\?\$/MINUTES $MINUTES_ON_BATTERY/g" $UPS_CONFIG_PATH
    bashio::log.info "Minutes on battery before shutdown set to: $MINUTES_ON_BATTERY"
fi

if [[ -n "$MAX_TIME_ON_BATTERY" && "$MAX_TIME_ON_BATTERY" != "null" && "$MAX_TIME_ON_BATTERY" != "0" ]]; then
    sed -i "s/^#\?MAXTIME\( .*\)\?\$/MAXTIME $MAX_TIME_ON_BATTERY/g" $UPS_CONFIG_PATH
    bashio::log.info "Maximum time on battery set to: $MAX_TIME_ON_BATTERY seconds"
fi

if [[ -n "$KILL_DELAY" && "$KILL_DELAY" != "null" ]]; then
    sed -i "s/^#\?KILLDELAY\( .*\)\?\$/KILLDELAY $KILL_DELAY/g" $UPS_CONFIG_PATH
    bashio::log.info "Kill delay set to: $KILL_DELAY seconds"
fi

if [[ -n "$NETWORK_PORT" && "$NETWORK_PORT" != "null" ]]; then
    sed -i "s/^#\?NISPORT\( .*\)\?\$/NISPORT $NETWORK_PORT/g" $UPS_CONFIG_PATH
    bashio::log.info "Network port set to: $NETWORK_PORT"
fi

if [[ -n "$NETWORK_TIMEOUT" && "$NETWORK_TIMEOUT" != "null" ]]; then
    sed -i "s/^#\?NETTIME\( .*\)\?\$/NETTIME $NETWORK_TIMEOUT/g" $UPS_CONFIG_PATH
    bashio::log.info "Network timeout set to: $NETWORK_TIMEOUT seconds"
fi

# Process extra configuration with validation
extra_keys=$(jq --raw-output ".extra[].key" $CONFIG_PATH)
if [[ -n "$extra_keys" ]]; then
    bashio::log.info "Processing extra configuration options..."
    
    IFS=$'\n' read -rd '' -a keys <<< "$extra_keys" || true
    extra_count=0
    
    for key in "${keys[@]}"; do
        # Limit number of extra config options
        if [[ $extra_count -ge 50 ]]; then
            bashio::log.warning "Maximum 50 extra configuration options allowed"
            break
        fi
        
        # Validate key format (alphanumeric and underscore only)
        if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || [[ ${#key} -gt 32 ]]; then
            bashio::log.warning "Skipping invalid configuration key: $key"
            continue
        fi
        
        val=$(jq --raw-output ".extra[] | select(.key == \"$key\").val" $CONFIG_PATH)
        
        if [[ -n "$val" ]]; then
            # Sanitize value and limit length
            if [[ ${#val} -gt 256 ]]; then
                bashio::log.warning "Configuration value too long for $key (max 256 chars)"
                continue
            fi
            
            sanitized_val=$(sanitize_config_value "$val")
            
            if grep -q "^#\?$key\( .*\)\?\$" $UPS_CONFIG_PATH; then
                # Replace existing config
                sed -i "s/^#\?$key\( .*\)\?\$/$key $sanitized_val/g" $UPS_CONFIG_PATH
            else
                # Add to bottom
                echo "$key $sanitized_val" >> $UPS_CONFIG_PATH
            fi
            bashio::log.info "Set $key = $val"
            ((extra_count++))
        else
            # Remove from config
            sed -i "s/^#\?$key\( .*\)\?\$//g" $UPS_CONFIG_PATH
            bashio::log.info "Removed $key from configuration"
        fi
    done
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

# Start syslog daemon for logging
bashio::log.info "Starting syslog daemon..."
syslogd -n -O - &

# Start apcupsd daemon
bashio::log.info "Starting APC UPS daemon..."
exec /sbin/apcupsd -b
