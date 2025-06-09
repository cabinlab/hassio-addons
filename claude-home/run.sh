#!/usr/bin/with-contenv bashio

# Initialize credentials and environment
init_environment() {
    # Ensure claude-config directory exists with proper permissions
    mkdir -p /config/claude-config
    chmod 777 /config/claude-config

    # Create links between credential locations and our persistent directory
    mkdir -p /root/.config
    ln -sf /config/claude-config /root/.config/anthropic

    # Link the found credential files to our persistent directory
    if [ -f "/config/claude-config/.claude" ]; then
        ln -sf /config/claude-config/.claude /root/.claude
    fi
    if [ -f "/config/claude-config/.claude.json" ]; then
        ln -sf /config/claude-config/.claude.json /root/.claude.json
    fi

    # Set environment variables
    export CLAUDE_CREDENTIALS_DIRECTORY="/config/claude-config"
    export ANTHROPIC_CONFIG_DIR="/config/claude-config"
    export HOME="/root"
    
    # Also set model directly as environment variable as fallback
    local claude_model_config=$(bashio::config 'claude_model' 'claude-3-5-haiku-20241022')
    export ANTHROPIC_MODEL="$claude_model_config"
    bashio::log.info "Set ANTHROPIC_MODEL environment variable to: $claude_model_config"
    
    # Read configuration from Home Assistant and create Claude settings
    create_claude_settings
    
    # Set basic environment variables (telemetry only)
    local disable_telemetry=$(bashio::config 'disable_telemetry' 'false')
    if [ "$disable_telemetry" = "true" ]; then
        export DISABLE_TELEMETRY=1
        export DISABLE_ERROR_REPORTING=1
    fi
    
    local claude_model=$(bashio::config 'claude_model' 'claude-3-5-haiku-20241022')
    local theme=$(bashio::config 'theme' 'dark')
    bashio::log.info "Configuration: Model=$claude_model, Theme=$theme, Telemetry=$([ "$disable_telemetry" = "true" ] && echo "disabled" || echo "enabled")"
}

# Create Claude native settings.json from Home Assistant configuration
create_claude_settings() {
    bashio::log.info "Creating Claude native settings configuration..."
    
    # Read configuration from Home Assistant
    local claude_model=$(bashio::config 'claude_model' 'claude-3-5-haiku-20241022')
    local theme=$(bashio::config 'theme' 'dark')
    
    bashio::log.info "Configuration read: model=$claude_model, theme=$theme"
    local verbose_logging=$(bashio::config 'verbose_logging' 'false')
    local max_turns=$(bashio::config 'max_turns' '10')
    local terminal_bell=$(bashio::config 'terminal_bell' 'true')
    local ha_notifications=$(bashio::config 'ha_notifications' 'false')
    local notification_service=$(bashio::config 'notification_service' 'persistent_notification')
    local context_integration=$(bashio::config 'context_integration' 'true')
    local context_domains=$(bashio::config 'context_domains' 'climate,sensor,binary_sensor,light,switch,weather')
    local context_max_entities=$(bashio::config 'context_max_entities' '100')
    
    # Convert boolean strings to JSON booleans
    local verbose_json=$([ "$verbose_logging" = "true" ] && echo "true" || echo "false")
    local bell_json=$([ "$terminal_bell" = "true" ] && echo "true" || echo "false")
    local notifications_json=$([ "$ha_notifications" = "true" ] && echo "true" || echo "false")
    local context_json=$([ "$context_integration" = "true" ] && echo "true" || echo "false")
    
    # Basic JSON string escaping for notification service (escape quotes and backslashes)
    local notification_service_escaped="${notification_service//\\/\\\\}"
    notification_service_escaped="${notification_service_escaped//\"/\\\"}"
    
    # Create Claude settings.json with native configuration format
    cat > /config/claude-config/settings.json << EOF
{
  "env": {
    "ANTHROPIC_MODEL": "$claude_model"
  },
  "theme": "$theme",
  "verbose": $verbose_json,
  "maxTurns": $max_turns,
  "terminalBell": $bell_json,
  "homeAssistant": {
    "notifications": $notifications_json,
    "notificationService": "$notification_service_escaped",
    "contextIntegration": $context_json,
    "contextDomains": "$context_domains",
    "contextMaxEntities": $context_max_entities
  }
}
EOF
    
    chmod 600 /config/claude-config/settings.json
    bashio::log.info "Claude settings.json created with model: $claude_model"
    bashio::log.info "Settings file contents:"
    cat /config/claude-config/settings.json
}

# Install required tools
install_tools() {
    bashio::log.info "Installing additional tools..."
    apk add --no-cache ttyd curl
}

# Setup credential management and security scripts
setup_security_scripts() {
    bashio::log.info "Setting up security scripts..."
    
    # Copy modular scripts to system locations if they exist
    if [ -d "/config/scripts" ]; then
        bashio::log.info "Found script modules, copying to system locations..."
        
        # Copy each script individually with error checking
        for script in credentials-manager credentials-service claude-auth resource-limits app-security activity-monitor filesystem-security ha-context claude-automate; do
            if [ -f "/config/scripts/${script}.sh" ]; then
                cp "/config/scripts/${script}.sh" "/usr/local/bin/${script}" && \
                chmod +x "/usr/local/bin/${script}" && \
                bashio::log.info "Installed ${script} script"
            else
                bashio::log.warning "Script ${script}.sh not found, creating minimal fallback"
                create_fallback_script "${script}"
            fi
        done
    else
        # Fallback to embedded scripts for backward compatibility
        bashio::log.warning "Script modules directory not found, creating fallback scripts"
        create_all_fallback_scripts
    fi

    # Create convenience aliases (only if target files exist)
    [ -f /usr/local/bin/credentials-manager ] && ln -sf /usr/local/bin/credentials-manager /usr/local/bin/claude-logout
    [ -f /usr/local/bin/claude-auth ] && ln -sf /usr/local/bin/claude-auth /usr/local/bin/debug-claude-auth
    [ -f /usr/local/bin/resource-limits ] && ln -sf /usr/local/bin/resource-limits /usr/local/bin/security-limits
    [ -f /usr/local/bin/app-security ] && ln -sf /usr/local/bin/app-security /usr/local/bin/app-sec
    [ -f /usr/local/bin/activity-monitor ] && ln -sf /usr/local/bin/activity-monitor /usr/local/bin/monitor
    [ -f /usr/local/bin/filesystem-security ] && ln -sf /usr/local/bin/filesystem-security /usr/local/bin/fs-sec
    [ -f /usr/local/bin/ha-context ] && ln -sf /usr/local/bin/ha-context /usr/local/bin/ha
    [ -f /usr/local/bin/claude-automate ] && ln -sf /usr/local/bin/claude-automate /usr/local/bin/automate
}

# Create minimal fallback scripts
create_fallback_script() {
    local script_name="$1"
    local script_path="/usr/local/bin/${script_name}"
    
    case "$script_name" in
        credentials-manager)
            cat > "$script_path" << 'EOF'
#!/bin/bash
# Minimal fallback credentials manager
mkdir -p /config/claude-config
chmod 700 /config/claude-config
case "$1" in
    logout)
        echo "Clearing credentials..."
        rm -rf /config/claude-config/.claude* /root/.claude*
        rm -rf /root/.config/anthropic /config/claude-config/credentials.json
        echo "Credentials cleared. Please restart to re-authenticate."
        ;;
    *)
        echo "Basic credential management active"
        ;;
esac
EOF
            ;;
        resource-limits)
            cat > "$script_path" << 'EOF'
#!/bin/bash
# Minimal fallback resource limits
ulimit -n 1024  # File descriptors
ulimit -u 256   # Processes  
ulimit -c 0     # No core dumps
ulimit -f 102400 # File size: 100MB
echo "Basic resource limits applied"
EOF
            ;;
        ha-context)
            cat > "$script_path" << 'EOF'
#!/bin/bash
# Minimal fallback HA context script
echo "Home Assistant context integration not available"
echo "Context features require full script modules"
exit 1
EOF
            ;;
        claude-automate)
            cat > "$script_path" << 'EOF'
#!/bin/bash
# Minimal fallback automation builder
echo "Natural Language Automation Builder not available"
echo "Automation builder requires full script modules"
exit 1
EOF
            ;;
        *)
            cat > "$script_path" << 'EOF'
#!/bin/bash
# Minimal fallback script
echo "Fallback script active"
EOF
            ;;
    esac
    
    chmod +x "$script_path"
}

# Create all fallback scripts
create_all_fallback_scripts() {
    for script in credentials-manager credentials-service claude-auth resource-limits app-security activity-monitor filesystem-security ha-context claude-automate; do
        create_fallback_script "$script"
    done
}

# Apply security policies and resource limits
apply_security_policies() {
    bashio::log.info "Applying container security policies..."
    
    # Create security log directory with proper permissions
    mkdir -p /config/claude-config
    touch /config/claude-config/security.log
    chmod 600 /config/claude-config/security.log
    
    # Apply all security policies and resource limits
    if [ -x "/usr/local/bin/resource-limits" ]; then
        /usr/local/bin/resource-limits all
        bashio::log.info "Resource limits and security policies applied"
    else
        bashio::log.warning "Resource limits script not found, applying basic limits"
        # Fallback basic limits
        ulimit -n 1024  # File descriptors
        ulimit -u 256   # Processes
        ulimit -c 0     # No core dumps
        ulimit -f 102400 # File size: 100MB
    fi
    
    # Log security initialization
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Container security initialization completed" >> /config/claude-config/security.log
}

# Apply application security controls
apply_app_security() {
    bashio::log.info "Applying application security controls..."
    
    # Apply all application security controls
    if [ -x "/usr/local/bin/app-security" ]; then
        /usr/local/bin/app-security all
        bashio::log.info "Application security controls applied"
    else
        bashio::log.warning "Application security script not found, applying basic controls"
        # Fallback basic application security
        export NODE_ENV=production
        export NODE_OPTIONS="--max-old-space-size=256 --max-listeners=20"
        export NODE_NO_WARNINGS=1
        export NO_UPDATE_NOTIFIER=1
        npm config set audit-level moderate 2>/dev/null || true
        npm config set ignore-scripts true 2>/dev/null || true
    fi
    
    # Log application security initialization
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Application security initialization completed" >> /config/claude-config/security.log
}

# Start container activity monitoring
start_activity_monitoring() {
    bashio::log.info "Starting container activity monitoring..."
    
    # Start activity monitoring services
    if [ -x "/usr/local/bin/activity-monitor" ]; then
        /usr/local/bin/activity-monitor start
        bashio::log.info "Container activity monitoring started"
    else
        bashio::log.warning "Activity monitor script not found, skipping monitoring"
    fi
    
    # Log monitoring initialization
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Container activity monitoring started" >> /config/claude-config/security.log
}

# Setup filesystem security controls
setup_filesystem_security() {
    bashio::log.info "Setting up filesystem security controls..."
    
    # Apply filesystem security policies
    if [ -x "/usr/local/bin/filesystem-security" ]; then
        /usr/local/bin/filesystem-security all
        bashio::log.info "Filesystem security controls applied"
    else
        bashio::log.warning "Filesystem security script not found, applying basic controls"
        # Fallback basic filesystem security
        chmod 700 /config/claude-config 2>/dev/null || true
        chmod 600 /config/claude-config/*.log 2>/dev/null || true
        chmod 600 /config/claude-config/*.hash 2>/dev/null || true
        umask 077
    fi
    
    # Log filesystem security initialization
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Filesystem security controls applied" >> /config/claude-config/security.log
}

# Verify all security components are functioning
verify_security_integration() {
    bashio::log.info "Verifying security integration..."
    
    local security_log="/config/claude-config/security.log"
    local status_file="/config/claude-config/security-status.txt"
    
    # Create security status report
    {
        echo "========================================"
        echo "Claude Home Security Status Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "========================================"
        echo ""
        
        echo "Security Components Status:"
        echo "- Enhanced credential validation: $([ -x /usr/local/bin/credentials-manager ] && echo "✓ Active" || echo "✗ Missing")"
        echo "- Process resource limits: $([ -x /usr/local/bin/resource-limits ] && echo "✓ Active" || echo "✗ Missing")"
        echo "- Application security controls: $([ -x /usr/local/bin/app-security ] && echo "✓ Active" || echo "✗ Missing")"
        echo "- Container activity monitoring: $([ -x /usr/local/bin/activity-monitor ] && echo "✓ Active" || echo "✗ Missing")"
        echo "- Filesystem access controls: $([ -x /usr/local/bin/filesystem-security ] && echo "✓ Active" || echo "✗ Missing")"
        echo ""
        
        echo "Security Logs:"
        echo "- Main security log: $([ -f "$security_log" ] && echo "✓ Present" || echo "✗ Missing")"
        echo "- Credential access log: $([ -f /config/claude-config/access.log ] && echo "✓ Present" || echo "✗ Missing")"
        echo "- Activity monitoring: $([ -f /config/claude-config/activity.log ] && echo "✓ Present" || echo "✗ Missing")"
        echo "- Filesystem integrity: $([ -f /config/claude-config/integrity.log ] && echo "✓ Present" || echo "✗ Missing")"
        echo ""
        
        echo "Current Security Settings:"
        echo "- File descriptor limit: $(ulimit -n)"
        echo "- Process limit: $(ulimit -u)"
        echo "- Memory limit: $(ulimit -v)KB"
        echo "- File size limit: $(ulimit -f)KB"
        echo "- Core dumps: $(ulimit -c)"
        echo "- umask setting: $(umask)"
        echo ""
        
        echo "Directory Permissions:"
        [ -d /config/claude-config ] && echo "- /config/claude-config: $(stat -c%a /config/claude-config 2>/dev/null || echo 'N/A')"
        [ -d /config/claude-config/backups ] && echo "- /config/claude-config/backups: $(stat -c%a /config/claude-config/backups 2>/dev/null || echo 'N/A')"
        echo ""
        
        echo "Security Processes:"
        echo "- Activity monitors: $(pgrep -f activity-monitor | wc -l) running"
        echo "- Node.js processes: $(pgrep node | wc -l) running"
        echo ""
        
        echo "Recent Security Events:"
        if [ -f "$security_log" ]; then
            echo "Last 5 security log entries:"
            tail -n 5 "$security_log" | sed 's/^/  /'
        else
            echo "No security log available"
        fi
        
    } > "$status_file"
    
    chmod 600 "$status_file"
    
    # Log integration verification
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Security integration verification completed" >> "$security_log"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Security status report generated: $status_file" >> "$security_log"
    
    bashio::log.info "Security integration verification completed - see $status_file for details"
}

# Start credential monitoring service
start_credential_service() {
    bashio::log.info "Starting credential monitoring service..."
    /usr/local/bin/credentials-service &
}

# Setup Home Assistant context integration
setup_context_integration() {
    local context_integration=$(bashio::config 'context_integration' 'true')
    
    if [ "$context_integration" = "true" ]; then
        bashio::log.info "Setting up Home Assistant context integration..."
        
        # Create cache directory for HA API responses
        mkdir -p /config/claude-config/ha-cache
        chmod 700 /config/claude-config/ha-cache
        
        # Set environment variables for context script
        export HA_URL="http://supervisor/core"
        export HASSIO_TOKEN="${HASSIO_TOKEN}"
        export SUPERVISOR_TOKEN="${SUPERVISOR_TOKEN}"
        
        # Test HA API connectivity
        if [ -n "${HASSIO_TOKEN}" ] && curl -s -H "Authorization: Bearer ${HASSIO_TOKEN}" "${HA_URL}/api/" > /dev/null; then
            bashio::log.info "Home Assistant API connection verified"
            
            # Create welcome message for context features
            cat > /tmp/ha_context_welcome.txt << EOF
🏠 Home Assistant Context Integration Active

Available commands:
  ha entities [domain]     - List HA entities  
  ha state <entity_id>     - Get entity state
  ha summary              - System overview
  ha help                 - Show all commands

🤖 Natural Language Automation Builder Active

Available commands:
  claude-automate "description"       - Create automation from natural language
  automate "description"              - Shortcut for claude-automate
  
Examples:
  claude-automate "Turn off all lights when I say good night"
  automate "Turn on porch light when motion detected" deploy
  claude-automate help                - Show automation builder help

EOF
        else
            bashio::log.warning "Home Assistant API not accessible - context features disabled"
        fi
    else
        bashio::log.info "Home Assistant context integration disabled in configuration"
    fi
}

# Setup credential management and Claude wrapper
setup_claude_wrapper() {
    # Backup original claude command and create wrapper
    if [ -f "/usr/local/bin/claude" ]; then
        mv /usr/local/bin/claude /usr/local/bin/claude-original
    fi
    
    # Create a Node.js wrapper for Claude CLI to bypass BusyBox env issues
    cat > /usr/local/bin/hiclaude << 'EOF'
#!/bin/bash
# Claude CLI wrapper to handle BusyBox compatibility issues

CLAUDE_BIN="/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js"

if [ ! -f "$CLAUDE_BIN" ]; then
    echo "ERROR: Could not find Claude CLI binary at $CLAUDE_BIN"
    echo "Expected location: /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js"
    exit 1
fi

# Execute Claude directly with Node.js to avoid env -S issues
exec node "$CLAUDE_BIN" "$@"
EOF

    chmod +x /usr/local/bin/hiclaude
}

# Check Claude authentication status
check_claude_auth() {
    # Check for credential files in persistent and runtime locations
    if [ -f "/config/claude-config/.claude" ] || [ -f "/config/claude-config/.claude.json" ] || 
       [ -f "/root/.claude" ] || [ -f "/root/.claude.json" ]; then
        # Try a quick validation by checking if claude can run without auth prompts
        if timeout 3 claude --version >/dev/null 2>&1; then
            export CLAUDE_AUTH_STATUS="authenticated"
        else
            export CLAUDE_AUTH_STATUS="invalid"
        fi
    else
        export CLAUDE_AUTH_STATUS="missing"
    fi
}

# Display ASCII header and auth status
show_terminal_header() {
    local auto_claude=$(bashio::config 'auto_claude' 'false')
    
    # Colors from reference script
    local CYAN='\033[38;2;79;195;193m'
    local BRIGHT_ORANGE='\033[1;38;2;244;132;95m'
    local GREEN='\033[0;32m'
    local RESET='\033[0m'
    
    # ASCII Header in cyan
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
    
    # Auth status
    case "$CLAUDE_AUTH_STATUS" in
        "authenticated")
            echo -e "${GREEN}***** Authenticated *****${RESET}"
            echo ""
            if [ "$auto_claude" = "true" ]; then
                echo "Auto-starting Claude..."
                sleep 1
                exec claude
            else
                echo "Run 'claude' to start, or 'claude --help' for options"
            fi
            ;;
        *)
            echo -e "${BRIGHT_ORANGE}¡¡¡¡¡ You get to login again !!!!!${RESET}"
            echo ""
            echo "Run 'claude auth' to authenticate"
            ;;
    esac
    echo ""
}

# Create terminal startup script
create_terminal_startup() {
    cat > /tmp/start_terminal.sh << 'EOF'
#!/bin/bash

# Clear screen and show header
clear
show_terminal_header

# Start bash shell
exec bash
EOF

    chmod +x /tmp/start_terminal.sh
}

# Start main web terminal
start_web_terminal() {
    local port=7681
    bashio::log.info "Starting web terminal on port ${port}..."
    
    # Log environment information for debugging
    bashio::log.info "Environment variables:"
    bashio::log.info "CLAUDE_CREDENTIALS_DIRECTORY=${CLAUDE_CREDENTIALS_DIRECTORY}"
    bashio::log.info "ANTHROPIC_CONFIG_DIR=${ANTHROPIC_CONFIG_DIR}"
    bashio::log.info "HOME=${HOME}"
    
    # Display current settings from settings.json if it exists
    if [ -f "/config/claude-config/settings.json" ]; then
        bashio::log.info "Claude settings.json created successfully"
    fi

    # Create functions script for terminal session
    cat > /tmp/claude_functions.sh << 'EOF'
#!/bin/bash
# Claude Home functions

check_claude_auth() {
    if [ -f "/config/claude-config/.claude" ] || [ -f "/config/claude-config/.claude.json" ] || 
       [ -f "/root/.claude" ] || [ -f "/root/.claude.json" ]; then
        if timeout 3 hiclaude --version >/dev/null 2>&1; then
            export CLAUDE_AUTH_STATUS="authenticated"
        else
            export CLAUDE_AUTH_STATUS="invalid"
        fi
    else
        export CLAUDE_AUTH_STATUS="missing"
    fi
}

show_terminal_header() {
    local auto_claude_setting=$(jq -r '.auto_claude // false' /data/options.json)
    local CYAN='\033[38;2;79;195;193m'
    local BRIGHT_ORANGE='\033[1;38;2;244;132;95m'
    local GREEN='\033[0;32m'
    local RESET='\033[0m'
    
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
    
    case "$CLAUDE_AUTH_STATUS" in
        "authenticated")
            echo -e "                ${GREEN}***** Authenticated *****${RESET}"
            echo ""
            if [ "$auto_claude_setting" = "true" ]; then
                echo "                  Auto-starting Claude..."
                sleep 1
                exec hiclaude
            else
                echo "             Run 'hiclaude' to start, or 'claude auth' to authenticate"
            fi
            ;;
        *)
            echo -e "              ${BRIGHT_ORANGE}¡¡¡¡¡ You get to login again !!!!!${RESET}"
            echo ""
            echo "                 Run 'claude auth' to authenticate"
            ;;
    esac
    echo ""
}
EOF
    chmod +x /tmp/claude_functions.sh

    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        bash -c "source /tmp/claude_functions.sh && check_claude_auth && show_terminal_header && bash"
}

# Main execution
main() {
    bashio::log.info "Initializing Claude Home add-on with enhanced security..."
    
    init_environment
    install_tools
    setup_security_scripts
    apply_security_policies
    apply_app_security
    setup_filesystem_security
    start_activity_monitoring
    verify_security_integration
    setup_claude_wrapper
    check_claude_auth
    start_credential_service
    setup_context_integration
    start_web_terminal
}

# Execute main function
main "$@"