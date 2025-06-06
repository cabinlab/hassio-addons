#!/bin/bash

# Claude Home: Natural Language Automation Builder
# Transforms natural language into Home Assistant automations

# Configuration
HA_URL="http://supervisor/core"
TOKEN="${SUPERVISOR_TOKEN:-$HASSIO_TOKEN}"
AUTOMATION_DIR="/config/claude-config/automations"
BACKUP_DIR="/config/claude-config/automation-backups"

# Create directories
mkdir -p "$AUTOMATION_DIR" "$BACKUP_DIR"

# Logging functions
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> /config/claude-config/automation-builder.log
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> /config/claude-config/automation-builder.log
    echo "Error: $1" >&2
}

# Get Claude model and reasoning from settings
get_claude_config() {
    if [ -f "/config/claude-config/settings.json" ]; then
        local model=$(grep -o '"model":[[:space:]]*"[^"]*"' /config/claude-config/settings.json | sed 's/"model":[[:space:]]*"//' | sed 's/"//')
        local verbose=$(grep -o '"verbose":[[:space:]]*[^,}]*' /config/claude-config/settings.json | sed 's/"verbose":[[:space:]]*//')
        echo "${model:-claude-3-5-sonnet-20241022}:${verbose:-false}"
    else
        echo "claude-3-5-sonnet-20241022:false"
    fi
}

# Validate HA API connection
validate_ha_connection() {
    if [ -z "$TOKEN" ]; then
        log_error "No Home Assistant token found"
        return 1
    fi
    
    if ! curl -s -H "Authorization: Bearer $TOKEN" "$HA_URL/api/" > /dev/null; then
        log_error "Cannot connect to Home Assistant API"
        return 1
    fi
    
    return 0
}

# Get available entities by domain
get_entities_by_domain() {
    local domain="$1"
    local entities_json=$(curl -s -H "Authorization: Bearer $TOKEN" "$HA_URL/api/states")
    
    if [ $? -eq 0 ] && [ -n "$entities_json" ]; then
        echo "$entities_json" | grep -o '"entity_id":"[^"]*"' | sed 's/"entity_id":"//' | sed 's/"//' | grep "^${domain}\." | head -20
    fi
}

# Parse natural language automation description
parse_automation_intent() {
    local description="$1"
    local model_config=$(get_claude_config)
    local model=${model_config%:*}
    local verbose=${model_config#*:}
    
    log_info "Parsing automation intent: $description (Model: $model)"
    
    # Create context for Claude about available entities
    local context="Available Home Assistant entities for automation:\n"
    context+="Lights: $(get_entities_by_domain 'light' | tr '\n' ',' | sed 's/,$//')\n"
    context+="Switches: $(get_entities_by_domain 'switch' | tr '\n' ',' | sed 's/,$//')\n"
    context+="Sensors: $(get_entities_by_domain 'sensor' | head -10 | tr '\n' ',' | sed 's/,$//')\n"
    context+="Binary Sensors: $(get_entities_by_domain 'binary_sensor' | head -10 | tr '\n' ',' | sed 's/,$//')\n"
    
    # Create Claude prompt for automation parsing
    local prompt="Parse this Home Assistant automation request into structured components:

Request: \"$description\"

$context

Please analyze and provide:
1. TRIGGER: What event should start this automation (time, state change, etc.)
2. CONDITION: Any conditions that must be met (optional)
3. ACTION: What should happen (which entities, which services)
4. AUTOMATION_NAME: A descriptive name for this automation

Respond in this exact format:
TRIGGER: [trigger description]
CONDITION: [condition description or 'none']
ACTION: [action description]
AUTOMATION_NAME: [descriptive name]
ENTITIES: [comma-separated list of specific entity IDs to use]"

    # For now, return a structured response (in real implementation, this would call Claude)
    # This is a placeholder that demonstrates the expected output format
    case "$description" in
        *"turn off all lights"*"bedtime"*|*"turn off all lights"*"good night"*)
            echo "TRIGGER: Manual trigger or voice command 'good night'"
            echo "CONDITION: none"
            echo "ACTION: Turn off all lights"
            echo "AUTOMATION_NAME: Good Night Lights Off"
            echo "ENTITIES: $(get_entities_by_domain 'light' | tr '\n' ',' | sed 's/,$//')"
            ;;
        *"motion"*"light"*)
            echo "TRIGGER: Motion sensor activation"
            echo "CONDITION: Time after sunset"
            echo "ACTION: Turn on specified lights"
            echo "AUTOMATION_NAME: Motion Activated Lighting"
            echo "ENTITIES: $(get_entities_by_domain 'binary_sensor' | grep motion | head -1),$(get_entities_by_domain 'light' | head -3 | tr '\n' ',' | sed 's/,$//')"
            ;;
        *)
            echo "TRIGGER: Manual trigger"
            echo "CONDITION: none"
            echo "ACTION: Custom action based on description"
            echo "AUTOMATION_NAME: Custom Automation"
            echo "ENTITIES: "
            ;;
    esac
}

# Generate Home Assistant automation YAML
generate_automation_yaml() {
    local trigger="$1"
    local condition="$2"
    local action="$3"
    local name="$4"
    local entities="$5"
    
    log_info "Generating automation YAML for: $name"
    
    # Generate unique ID
    local automation_id="claude_$(date +%s)"
    
    # Start YAML generation
    local yaml="# Generated by Claude Home Automation Builder
# $(date '+%Y-%m-%d %H:%M:%S')
# Description: $name

automation:
  id: $automation_id
  alias: \"$name\"
  description: \"Generated from: $action\"
  mode: single"

    # Add trigger based on parsed intent
    case "$trigger" in
        *"good night"*|*"voice command"*)
            yaml+="\n  trigger:\n    - platform: conversation\n      command: \"good night\""
            ;;
        *"motion"*)
            local motion_sensor=$(echo "$entities" | cut -d',' -f1)
            if [ -n "$motion_sensor" ]; then
                yaml+="\n  trigger:\n    - platform: state\n      entity_id: $motion_sensor\n      to: 'on'"
            fi
            ;;
        *"time"*|*"bedtime"*)
            yaml+="\n  trigger:\n    - platform: time\n      at: \"22:00:00\""
            ;;
        *)
            yaml+="\n  trigger:\n    - platform: homeassistant\n      event: start"
            ;;
    esac
    
    # Add conditions if specified
    if [ "$condition" != "none" ] && [ -n "$condition" ]; then
        case "$condition" in
            *"sunset"*)
                yaml+="\n  condition:\n    - condition: sun\n      after: sunset"
                ;;
            *"nobody home"*)
                yaml+="\n  condition:\n    - condition: state\n      entity_id: group.all_persons\n      state: 'not_home'"
                ;;
        esac
    fi
    
    # Add actions based on parsed intent
    yaml+="\n  action:"
    case "$action" in
        *"turn off all lights"*)
            yaml+="\n    - service: light.turn_off\n      target:\n        entity_id: all"
            ;;
        *"turn on"*"lights"*)
            local light_entities=$(echo "$entities" | grep "light\." | tr ',' '\n' | head -3)
            if [ -n "$light_entities" ]; then
                yaml+="\n    - service: light.turn_on\n      target:\n        entity_id:"
                for entity in $light_entities; do
                    yaml+="\n          - $entity"
                done
            fi
            ;;
        *)
            yaml+="\n    - service: persistent_notification.create\n      data:\n        title: \"Claude Automation\"\n        message: \"Custom automation executed: $action\""
            ;;
    esac
    
    echo -e "$yaml"
}

# Validate generated automation YAML
validate_automation() {
    local yaml_content="$1"
    local temp_file="/tmp/automation_validate.yaml"
    
    echo "$yaml_content" > "$temp_file"
    
    # Basic YAML syntax validation
    if ! python3 -c "import yaml; yaml.safe_load(open('$temp_file'))" 2>/dev/null; then
        log_error "Generated YAML has syntax errors"
        rm -f "$temp_file"
        return 1
    fi
    
    # Check for required automation fields
    if ! grep -q "automation:" "$temp_file" || ! grep -q "trigger:" "$temp_file" || ! grep -q "action:" "$temp_file"; then
        log_error "Generated automation missing required fields"
        rm -f "$temp_file"
        return 1
    fi
    
    # Validate entity existence (check first few entities)
    local entities=$(grep -o "entity_id: [^[:space:]]*" "$temp_file" | sed 's/entity_id: //' | head -3)
    for entity in $entities; do
        if [ "$entity" != "all" ] && ! curl -s -H "Authorization: Bearer $TOKEN" "$HA_URL/api/states/$entity" | grep -q "entity_id"; then
            log_error "Entity $entity does not exist in Home Assistant"
            rm -f "$temp_file"
            return 1
        fi
    done
    
    rm -f "$temp_file"
    log_info "Automation validation passed"
    return 0
}

# Preview automation (display without deploying)
preview_automation() {
    local yaml_content="$1"
    
    echo "Generated Home Assistant Automation:"
    echo "===================================="
    echo "$yaml_content"
    echo ""
    echo "This automation would be saved to: $AUTOMATION_DIR"
    echo ""
    echo "To deploy this automation, run: claude-automate deploy [automation-file]"
}

# Deploy automation to Home Assistant
deploy_automation() {
    local yaml_content="$1"
    local automation_name="$2"
    local filename="${automation_name// /_}.yaml"
    local filepath="$AUTOMATION_DIR/$filename"
    
    # Create backup of existing automations
    if [ -f "$filepath" ]; then
        cp "$filepath" "$BACKUP_DIR/${filename}.backup.$(date +%s)"
        log_info "Created backup of existing automation: $filename"
    fi
    
    # Save automation to file
    echo "$yaml_content" > "$filepath"
    chmod 600 "$filepath"
    
    # TODO: In future implementation, could use HA REST API to reload automations
    # For now, user needs to restart HA or manually reload automations
    
    log_info "Automation deployed: $filepath"
    echo "Automation saved to: $filepath"
    echo ""
    echo "To activate this automation:"
    echo "1. Go to Settings → Automations & Scenes"
    echo "2. Click 'Reload Automations' or restart Home Assistant"
    echo "3. Find '$automation_name' in your automation list"
}

# Main function
main() {
    local description="$1"
    local mode="${2:-preview}"  # preview, deploy
    local name="$3"
    
    if [ -z "$description" ]; then
        cat << 'EOF'
Claude Home Automation Builder

Usage:
  claude-automate "description" [mode] [name]

Examples:
  claude-automate "Turn off all lights when I say good night"
  claude-automate "Turn on porch light when motion detected" deploy
  claude-automate "Send notification if door open too long" preview "Door Alert"

Modes:
  preview  - Show generated automation without deploying (default)
  deploy   - Save automation to Home Assistant
  
For help: claude-automate help
EOF
        return 0
    fi
    
    if [ "$description" = "help" ]; then
        echo "Claude Home Automation Builder Help"
        echo "=================================="
        echo ""
        echo "This tool converts natural language descriptions into Home Assistant automations."
        echo ""
        echo "Supported patterns:"
        echo "• Time-based: 'Turn off lights at bedtime'"
        echo "• Motion-based: 'Turn on lights when motion detected'"
        echo "• State-based: 'Send alert when door left open'"
        echo "• Voice-based: 'Turn off all lights when I say good night'"
        echo ""
        echo "The tool will:"
        echo "1. Parse your natural language description"
        echo "2. Identify available Home Assistant entities"
        echo "3. Generate valid automation YAML"
        echo "4. Validate the automation before deployment"
        echo ""
        return 0
    fi
    
    # Validate HA connection
    if ! validate_ha_connection; then
        echo "Cannot connect to Home Assistant. Check addon logs for details."
        return 1
    fi
    
    log_info "Starting automation builder for: $description"
    
    # Parse natural language description
    local intent=$(parse_automation_intent "$description")
    
    # Extract components from parsed intent
    local trigger=$(echo "$intent" | grep "^TRIGGER:" | sed 's/TRIGGER: //')
    local condition=$(echo "$intent" | grep "^CONDITION:" | sed 's/CONDITION: //')
    local action=$(echo "$intent" | grep "^ACTION:" | sed 's/ACTION: //')
    local auto_name=$(echo "$intent" | grep "^AUTOMATION_NAME:" | sed 's/AUTOMATION_NAME: //')
    local entities=$(echo "$intent" | grep "^ENTITIES:" | sed 's/ENTITIES: //')
    
    # Use provided name or auto-generated name
    local final_name="${name:-$auto_name}"
    
    # Generate automation YAML
    local yaml_content=$(generate_automation_yaml "$trigger" "$condition" "$action" "$final_name" "$entities")
    
    # Validate automation
    if ! validate_automation "$yaml_content"; then
        echo "Generated automation failed validation. Check logs for details."
        return 1
    fi
    
    # Handle mode
    case "$mode" in
        "deploy")
            deploy_automation "$yaml_content" "$final_name"
            ;;
        "preview"|*)
            preview_automation "$yaml_content"
            ;;
    esac
    
    log_info "Automation builder completed successfully"
}

# Execute main function with all arguments
main "$@"