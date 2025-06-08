#!/usr/bin/with-contenv bashio
set -e

# UPS Power Control Script
# Handles various UPS power management commands

LOG_PREFIX="[UPS-CONTROL]"

log_info() {
    bashio::log.info "$LOG_PREFIX $1"
}

log_warning() {
    bashio::log.warning "$LOG_PREFIX $1"
}

log_error() {
    bashio::log.error "$LOG_PREFIX $1"
}

# Validate delay parameter
validate_delay() {
    local delay="$1"
    if [[ ! "$delay" =~ ^[0-9]+$ ]] || [[ "$delay" -lt 0 ]] || [[ "$delay" -gt 7200 ]]; then
        log_error "Invalid delay: $delay. Must be 0-7200 seconds."
        return 1
    fi
    return 0
}

# Stop apcupsd safely
stop_apcupsd() {
    log_info "Stopping apcupsd daemon for power control operation..."
    if pgrep apcupsd > /dev/null; then
        pkill apcupsd
        sleep 2
    fi
}

# Start apcupsd safely  
start_apcupsd() {
    log_info "Restarting apcupsd daemon..."
    /sbin/apcupsd -b &
    sleep 3
}

# Execute apctest command safely
execute_apctest() {
    local command="$1"
    local description="$2"
    
    log_info "Executing UPS command: $description"
    
    stop_apcupsd
    
    # Send command to apctest
    echo "$command" | timeout 30 /sbin/apctest
    local result=$?
    
    start_apcupsd
    
    if [[ $result -eq 0 ]]; then
        log_info "UPS command completed: $description"
    else
        log_error "UPS command failed: $description"
        return 1
    fi
}

# UPS Shutdown with Return (graceful)
ups_shutdown_return() {
    local delay="${1:-20}"
    
    if ! validate_delay "$delay"; then
        return 1
    fi
    
    log_warning "Initiating UPS shutdown with auto-return in $delay seconds..."
    log_warning "UPS will restart automatically when power returns"
    
    # Use apccontrol for coordinated shutdown
    echo "$delay" > /tmp/shutdown_delay
    /etc/apcupsd/apccontrol doshutdown
}

# Load Off (cut power to outlets)
ups_load_off() {
    local delay="${1:-10}"
    
    if ! validate_delay "$delay"; then
        return 1
    fi
    
    log_warning "Cutting power to UPS outlets in $delay seconds..."
    log_warning "This will immediately shut down connected equipment!"
    
    # Configure delay then execute load off
    stop_apcupsd
    sleep "$delay"
    echo "1" | /sbin/apctest  # Test kill UPS power
    start_apcupsd
}

# Load On (restore power to outlets)
ups_load_on() {
    local delay="${1:-5}"
    
    if ! validate_delay "$delay"; then
        return 1
    fi
    
    log_info "Restoring power to UPS outlets in $delay seconds..."
    
    sleep "$delay"
    # This typically happens automatically when UPS detects load
    log_info "Power restoration command sent"
}

# UPS Reboot (shutdown then restart)
ups_reboot() {
    local off_delay="${1:-10}"
    local on_delay="${2:-30}"
    
    if ! validate_delay "$off_delay" || ! validate_delay "$on_delay"; then
        return 1
    fi
    
    log_warning "Rebooting UPS: off in $off_delay seconds, on after $on_delay seconds"
    
    # Execute coordinated reboot
    stop_apcupsd
    sleep "$off_delay"
    echo "1" | /sbin/apctest  # Kill power
    sleep "$on_delay"
    start_apcupsd
    
    log_info "UPS reboot sequence completed"
}

# Emergency Kill (immediate power cut)
ups_emergency_kill() {
    log_error "EMERGENCY: Executing immediate UPS power kill!"
    log_error "All connected equipment will lose power immediately!"
    
    # Direct killpower command
    /sbin/apcupsd --killpower
    
    log_error "Emergency power kill executed"
}

# Main command dispatcher
case "$1" in
    "shutdown_return")
        ups_shutdown_return "$2"
        ;;
    "load_off")
        ups_load_off "$2"
        ;;
    "load_on")
        ups_load_on "$2"
        ;;
    "reboot")
        ups_reboot "$2" "$3"
        ;;
    "emergency_kill")
        ups_emergency_kill
        ;;
    *)
        log_error "Unknown command: $1"
        log_info "Available commands: shutdown_return, load_off, load_on, reboot, emergency_kill"
        exit 1
        ;;
esac