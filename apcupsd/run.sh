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
    # Enhanced device auto-detection following apcupsd best practices
    device_set=false
    
    if [[ "$TYPE" == "usb" ]]; then
        # For USB type, leave DEVICE blank per apcupsd documentation
        # apcupsd will auto-detect USB devices when DEVICE is empty
        sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE/g" $UPS_CONFIG_PATH
        bashio::log.info "Device set to: (blank - USB auto-detection enabled)"
        bashio::log.info "Following apcupsd best practice: USB devices auto-detected when DEVICE is blank"
        device_set=true
    elif [[ "$TYPE" == "apcsmart" ]]; then
        # For apcsmart with USB connection, also try blank device first
        if [[ "$CABLE" == "smart" ]] || [[ "$CABLE" == "usb" ]]; then
            bashio::log.info "Testing apcsmart with USB - trying blank device first (apcupsd best practice)..."
            sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE/g" $UPS_CONFIG_PATH
            
            # Test with blank device and capture which device apctest actually uses
            if command -v apctest &> /dev/null; then
                bashio::log.info "Testing apctest with blank device to discover working device..."
                
                # Test with apctest to see if it works with blank device
                test_output=$(timeout 5 bash -c "echo -e 'Y\nQ\n' | apctest -f /etc/apcupsd/apcupsd.conf 2>/dev/null | grep -E '(Smart|Status|Model)' | head -3" || echo "")
                if [[ -n "$test_output" && ! "$test_output" =~ "COMMLOST" ]]; then
                    bashio::log.info "✓ apctest succeeds with blank device"
                    bashio::log.info "UPS Response: $test_output"
                    
                    # Since apctest works but daemon might not, try to determine which device apctest is using
                    # Run apctest with more verbose output to see device selection
                    apctest_device=$(timeout 5 bash -c "echo -e '1\nQ\n' | apctest -f /etc/apcupsd/apcupsd.conf 2>&1 | grep -E 'Device.*open|Using.*device|Found.*device|Opened.*device'" || echo "")
                    
                    if [[ -n "$apctest_device" ]]; then
                        bashio::log.info "apctest device info: $apctest_device"
                        
                        # Extract device path if possible
                        device_path=$(echo "$apctest_device" | grep -oE '/dev/[^[:space:]]+' | head -1)
                        if [[ -n "$device_path" ]]; then
                            bashio::log.info "apctest discovered device: $device_path"
                            bashio::log.info "Setting specific device for daemon compatibility..."
                            sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE $device_path/g" $UPS_CONFIG_PATH
                            device_set=true
                        else
                            bashio::log.info "Could not extract device path from apctest, trying common paths..."
                            device_set=false
                        fi
                    else
                        # apctest works but we can't determine device - try hiddev0 as most likely
                        bashio::log.info "apctest works but device unclear - trying /dev/usb/hiddev0 for daemon"
                        sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE \/dev\/usb\/hiddev0/g" $UPS_CONFIG_PATH
                        device_set=true
                    fi
                else
                    bashio::log.info "Blank device test failed, trying specific device paths..."
                    bashio::log.info "Test output: $test_output"
                fi
            fi
        fi
        
        # If blank device failed, try specific device paths
        if [[ "$device_set" == "false" ]]; then
            bashio::log.info "Testing apcsmart with specific device paths..."
            
            # Test hiddev0 first
            if [[ -e "/dev/usb/hiddev0" ]]; then
                bashio::log.info "Testing /dev/usb/hiddev0 for apcsmart compatibility..."
                sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE \/dev\/usb\/hiddev0/g" $UPS_CONFIG_PATH
                
                # Test actual UPS communication with a simple status query
                if command -v apctest &> /dev/null; then
                    test_output=$(timeout 5 bash -c "echo -e 'Y\nQ\n' | apctest -f /etc/apcupsd/apcupsd.conf 2>/dev/null | grep -E '(Smart|Status|Model)' | head -3" || echo "")
                    if [[ -n "$test_output" && ! "$test_output" =~ "COMMLOST" ]]; then
                        bashio::log.info "Device set to: /dev/usb/hiddev0 (apcsmart via USB HID - communication verified)"
                        bashio::log.info "UPS Response: $test_output"
                        device_set=true
                    else
                        bashio::log.info "hiddev0 communication test failed, trying hiddev1..."
                        bashio::log.info "Test output: $test_output"
                    fi
                fi
            fi
            
            # Test hiddev1 if hiddev0 failed
            if [[ "$device_set" == "false" && -e "/dev/usb/hiddev1" ]]; then
                bashio::log.info "Testing /dev/usb/hiddev1 for apcsmart compatibility..."
                sed -i "s/^#\?DEVICE\( .*\)\?\$/DEVICE \/dev\/usb\/hiddev1/g" $UPS_CONFIG_PATH
                
                if command -v apctest &> /dev/null; then
                    test_output=$(timeout 5 bash -c "echo -e 'Y\nQ\n' | apctest -f /etc/apcupsd/apcupsd.conf 2>/dev/null | grep -E '(Smart|Status|Model)' | head -3" || echo "")
                    if [[ -n "$test_output" && ! "$test_output" =~ "COMMLOST" ]]; then
                        bashio::log.info "Device set to: /dev/usb/hiddev1 (apcsmart via USB HID - communication verified)"
                        bashio::log.info "UPS Response: $test_output"
                        device_set=true
                    else
                        bashio::log.warning "Both blank device and specific paths failed for apcsmart"
                        bashio::log.info "hiddev1 test output: $test_output"
                        device_set=true  # Still set to avoid no device
                    fi
                fi
            fi
        fi
    fi
    
    # Fallback if no device was set
    if [[ "$device_set" == "false" ]]; then
        sed -i "s/^#\?DEVICE\( .*\)\?\$//g" $UPS_CONFIG_PATH
        bashio::log.info "Device auto-detection enabled (no specific device found or tested)"
    fi
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

# Test one more time before starting daemon to ensure config is correct
bashio::log.info "Final configuration verification before daemon startup:"
grep -E "^(UPSCABLE|UPSTYPE|DEVICE)" $UPS_CONFIG_PATH | while read line; do
    bashio::log.info "  $line"
done

# Test device permissions and access before starting daemon
if [[ -n $(grep "^DEVICE" $UPS_CONFIG_PATH | cut -d' ' -f2) ]]; then
    device_path=$(grep "^DEVICE" $UPS_CONFIG_PATH | cut -d' ' -f2)
    if [[ -e "$device_path" ]]; then
        bashio::log.info "Device $device_path exists with permissions: $(ls -la $device_path)"
        if [[ -r "$device_path" && -w "$device_path" ]]; then
            bashio::log.info "✓ Device $device_path is readable and writable"
        else
            bashio::log.warning "✗ Device $device_path permissions issue"
        fi
    else
        bashio::log.warning "✗ Device $device_path does not exist"
    fi
fi

# Fix device permissions before starting daemon
device_path=$(grep "^DEVICE" $UPS_CONFIG_PATH | cut -d' ' -f2)
if [[ -n "$device_path" && -e "$device_path" ]]; then
    bashio::log.info "Fixing permissions for device: $device_path"
    chmod 666 "$device_path" || bashio::log.warning "Could not change device permissions"
    chown root:root "$device_path" || bashio::log.warning "Could not change device ownership"
    bashio::log.info "Device permissions after fix: $(ls -la $device_path)"
fi

# Also ensure hiddev devices are accessible if they exist
for hiddev in /dev/usb/hiddev*; do
    if [[ -e "$hiddev" ]]; then
        bashio::log.info "Fixing permissions for HID device: $hiddev"
        chmod 666 "$hiddev" || bashio::log.warning "Could not change $hiddev permissions"
        chown root:root "$hiddev" || bashio::log.warning "Could not change $hiddev ownership"
    fi
done

# Start daemon with additional debugging
bashio::log.info "Starting apcupsd daemon in debug mode..."
/sbin/apcupsd -b -d 10 &
daemon_pid=$!

# Wait for daemon initialization
bashio::log.info "Waiting for apcupsd daemon to initialize (PID: $daemon_pid)..."
sleep 3

# Check if daemon is still running
if kill -0 $daemon_pid 2>/dev/null; then
    bashio::log.info "✓ apcupsd daemon is running (PID: $daemon_pid)"
else
    bashio::log.error "✗ apcupsd daemon failed to start or crashed"
fi

# Additional wait for stabilization
sleep 2

# Debug environment
bashio::log.info "=== DEBUG INFO ==="
bashio::log.info "SUPERVISOR_TOKEN available: $([ -n "$SUPERVISOR_TOKEN" ] && echo "YES" || echo "NO")"
bashio::log.info "Auto-discovery setting: $AUTO_DISCOVERY"

# Debug USB devices
bashio::log.info "=== USB DEBUGGING ==="
bashio::log.info "USB devices available:"
ls -la /dev/usb* 2>/dev/null || bashio::log.warning "No /dev/usb devices found"
bashio::log.info "USB bus devices:"
lsusb 2>/dev/null || bashio::log.warning "lsusb not available"
bashio::log.info "Checking for APC vendor ID (051d):"
lsusb 2>/dev/null | grep "051d" || bashio::log.warning "No APC vendor ID (051d) devices detected"
bashio::log.info "HID devices (UPS likely uses HID):"
ls -la /dev/hiddev* 2>/dev/null || bashio::log.warning "No HID devices found"
bashio::log.info "USB device permissions:"
ls -la /dev/bus/usb/*/*051d* 2>/dev/null || bashio::log.warning "Cannot find APC USB device files"

# Test apcupsd is working
bashio::log.info "Testing apcupsd daemon..."

# Immediate status check
bashio::log.info "Immediate daemon status check..."
if pgrep apcupsd > /dev/null; then
    bashio::log.info "✓ apcupsd daemon process found"
    
    # Try immediate apcaccess test
    bashio::log.info "Testing immediate apcaccess connection..."
    if timeout 3 apcaccess status >/dev/null 2>&1; then
        immediate_status=$(apcaccess status | grep STATUS | cut -d: -f2 | xargs)
        bashio::log.info "Immediate UPS Status: $immediate_status"
    else
        bashio::log.warning "✗ Immediate apcaccess test failed"
    fi
else
    bashio::log.error "✗ apcupsd daemon process not found immediately after startup"
fi

# Wait a bit more for stabilization
sleep 3

bashio::log.info "Post-stabilization daemon status check..."
if pgrep apcupsd > /dev/null; then
    bashio::log.info "✓ apcupsd daemon is running"
    # Test if apcaccess works
    if timeout 5 apcaccess status >/dev/null 2>&1; then
        bashio::log.info "✓ apcaccess can connect to daemon"
        ups_status=$(apcaccess status | grep STATUS | cut -d: -f2 | xargs)
        bashio::log.info "UPS Status: $ups_status"
        
        if [[ "$ups_status" == "COMMLOST" ]]; then
            bashio::log.warning "UPS communication lost - detailed debugging..."
            bashio::log.info "Current apcupsd configuration:"
            grep -E "^(UPSCABLE|UPSTYPE|DEVICE)" /etc/apcupsd/apcupsd.conf || bashio::log.warning "Cannot read apcupsd config"
            bashio::log.info "Testing device access:"
            ls -la /dev/usb/hiddev0 2>/dev/null || bashio::log.warning "hiddev0 not accessible"
            ls -la /dev/usb/hiddev1 2>/dev/null || bashio::log.warning "hiddev1 not accessible" 
            bashio::log.info "Full apcaccess output:"
            apcaccess status 2>&1 | head -10 || bashio::log.warning "Cannot get apcaccess status"
            
            # Try alternative device for apcsmart
            if [[ "$CABLE" == "smart" && "$TYPE" == "apcsmart" ]]; then
                current_device=$(grep "^DEVICE" /etc/apcupsd/apcupsd.conf | cut -d' ' -f2)
                if [[ "$current_device" == "/dev/usb/hiddev0" && -e "/dev/usb/hiddev1" ]]; then
                    bashio::log.info "Trying alternative device /dev/usb/hiddev1..."
                    sed -i "s/^DEVICE.*/DEVICE \/dev\/usb\/hiddev1/g" /etc/apcupsd/apcupsd.conf
                    bashio::log.info "Restarting apcupsd with hiddev1..."
                    pkill apcupsd
                    sleep 2
                    /sbin/apcupsd -b &
                    sleep 3
                    new_status=$(apcaccess status | grep STATUS | cut -d: -f2 | xargs)
                    bashio::log.info "UPS Status with hiddev1: $new_status"
                elif [[ "$current_device" == "/dev/usb/hiddev1" ]]; then
                    bashio::log.info "Already tried hiddev1, UPS may not be compatible with current settings"
                fi
            fi
            
            # Suggest manual device configuration
            bashio::log.info "TROUBLESHOOTING: Try manually setting Device Path in add-on config:"
            bashio::log.info "- Try: /dev/usb/hiddev0"
            bashio::log.info "- Try: /dev/usb/hiddev1" 
            bashio::log.info "- Try: /dev/ttyUSB0 (if available)"
            bashio::log.info "- Or try Cable Type 'usb' with Communication Protocol 'usb'"
        fi
    else
        bashio::log.warning "✗ apcaccess cannot connect to daemon"
    fi
else
    bashio::log.error "✗ apcupsd daemon is not running"
fi

# Run auto-discovery if enabled
if [[ "$AUTO_DISCOVERY" == "true" ]]; then
    bashio::log.info "Starting auto-discovery for Home Assistant integration..."
    /usr/local/bin/auto-discovery.sh &
else
    bashio::log.info "Auto-discovery disabled - manual setup required"
    bashio::log.info "Add to configuration.yaml:"
    bashio::log.info "apcupsd:"
    bashio::log.info "  host: \"12862deb-apcupsd\""
    bashio::log.info "  port: 3551"
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
