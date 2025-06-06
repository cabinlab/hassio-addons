#!/bin/bash

# Home Assistant Context Integration for Claude Home
# Provides bash commands to access HA entities and state from Claude terminal

# Configuration
CACHE_DIR="/config/claude-config/ha-cache"
CACHE_DURATION=30  # seconds

# Get max entities from configuration (bash parsing)
get_max_entities() {
    # Try to read from Claude settings.json with bash parsing
    if [ -f "/config/claude-config/settings.json" ]; then
        local max_entities=$(grep -o '"contextMaxEntities":[[:space:]]*[0-9]\+' /config/claude-config/settings.json 2>/dev/null | sed 's/.*://' | tr -d ' ')
        if [ -n "$max_entities" ] && [ "$max_entities" -gt 0 ] 2>/dev/null; then
            echo "$max_entities"
            return 0
        fi
    fi
    
    # Fallback to default
    echo "100"
}

MAX_ENTITIES=$(get_max_entities)
HA_URL="http://supervisor/core"
TOKEN="${SUPERVISOR_TOKEN:-$HASSIO_TOKEN}"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Logging functions
log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - INFO: $1" >> /config/claude-config/ha-context.log
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> /config/claude-config/ha-context.log
    echo "Error: $1" >&2
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

# Check cache freshness
is_cache_fresh() {
    local cache_file="$1"
    local max_age="$2"
    
    if [ ! -f "$cache_file" ]; then
        return 1
    fi
    
    local file_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
    [ "$file_age" -lt "$max_age" ]
}

# Fetch all entities with caching
fetch_entities() {
    local cache_file="$CACHE_DIR/entities.json"
    
    if is_cache_fresh "$cache_file" "$CACHE_DURATION"; then
        cat "$cache_file"
        return 0
    fi
    
    log_info "Fetching entities from Home Assistant API"
    
    local response=$(curl -s -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$HA_URL/api/states")
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        echo "$response" > "$cache_file"
        echo "$response"
        log_info "Entities cached successfully ($(echo "$response" | grep -o '"entity_id"' | wc -l) entities)"
    else
        log_error "Failed to fetch entities from HA API"
        return 1
    fi
}

# Get allowed domains from Claude settings.json configuration (bash parsing)
get_allowed_domains() {
    # Try to read from Claude settings.json with bash parsing
    if [ -f "/config/claude-config/settings.json" ]; then
        local domains=$(grep -o '"contextDomains":[[:space:]]*"[^"]*"' /config/claude-config/settings.json 2>/dev/null | sed 's/"contextDomains":[[:space:]]*"//' | sed 's/"$//')
        if [ -n "$domains" ]; then
            echo "$domains" | tr ',' ' '
            return 0
        fi
    fi
    
    # Fallback to default domains
    echo "climate sensor binary_sensor light switch weather automation script input_boolean input_number input_text"
}

# Extract entity IDs from JSON using bash parsing
extract_entity_ids() {
    local entities="$1"
    # Extract entity_id values using grep and sed
    echo "$entities" | grep -o '"entity_id":"[^"]*"' | sed 's/"entity_id":"//' | sed 's/"//'
}

# Filter entities by allowed domains
filter_entities_by_domain() {
    local entities="$1"
    local allowed_domains="$2"
    local target_domain="$3"
    
    local entity_ids=$(extract_entity_ids "$entities")
    
    if [ -n "$target_domain" ]; then
        # Filter by specific domain
        echo "$entity_ids" | grep "^${target_domain}\."
    else
        # Filter by all allowed domains
        local filtered_entities=""
        for domain in $allowed_domains; do
            local domain_entities=$(echo "$entity_ids" | grep "^${domain}\.")
            if [ -n "$domain_entities" ]; then
                if [ -n "$filtered_entities" ]; then
                    filtered_entities="$filtered_entities"$'\n'"$domain_entities"
                else
                    filtered_entities="$domain_entities"
                fi
            fi
        done
        echo "$filtered_entities"
    fi
}

# Validate entity ID format
validate_entity_id() {
    local entity_id="$1"
    
    # Basic validation: domain.entity format, alphanumeric and underscores only
    if [[ ! "$entity_id" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z0-9_]+$ ]]; then
        log_error "Invalid entity ID format: $entity_id"
        return 1
    fi
    
    return 0
}

# Parse JSON field using bash
parse_json_field() {
    local json="$1"
    local field="$2"
    local default="$3"
    
    # Extract field value, handling nested objects for attributes
    if [ "$field" = "attributes.friendly_name" ]; then
        local friendly_name=$(echo "$json" | grep -o '"friendly_name":"[^"]*"' | sed 's/"friendly_name":"//' | sed 's/"//' | head -1)
        echo "${friendly_name:-${default:-N/A}}"
    else
        local value=$(echo "$json" | grep -o "\"$field\":\"[^\"]*\"" | sed "s/\"$field\":\"//" | sed 's/"//' | head -1)
        if [ -z "$value" ]; then
            # Try without quotes for numeric/boolean values
            value=$(echo "$json" | grep -o "\"$field\":[^,}]*" | sed "s/\"$field\"://" | sed 's/[,}].*//' | head -1)
        fi
        echo "${value:-${default:-N/A}}"
    fi
}

# Extract attribute keys from JSON
extract_attribute_keys() {
    local json="$1"
    # Extract the attributes object and then find all keys
    local attrs=$(echo "$json" | sed -n 's/.*"attributes":\({[^}]*}\).*/\1/p')
    if [ -n "$attrs" ]; then
        echo "$attrs" | grep -o '"[^"]*":' | sed 's/"//g' | sed 's/://' | tr '\n' ',' | sed 's/,$//'
    else
        echo "none"
    fi
}

# Get entity state
get_entity_state() {
    local entity_id="$1"
    
    if ! validate_entity_id "$entity_id"; then
        return 1
    fi
    
    log_info "Getting state for entity: $entity_id"
    
    local response=$(curl -s -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        "$HA_URL/api/states/$entity_id")
    
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        local state=$(parse_json_field "$response" "state")
        local friendly_name=$(parse_json_field "$response" "attributes.friendly_name" "N/A")
        local last_changed=$(parse_json_field "$response" "last_changed")
        local attributes=$(extract_attribute_keys "$response")
        
        echo "State: $state"
        echo "Friendly Name: $friendly_name"
        echo "Last Changed: $last_changed"
        echo "Attributes: $attributes"
    else
        log_error "Failed to get state for entity: $entity_id"
        return 1
    fi
}

# Main command router
main() {
    if ! validate_ha_connection; then
        echo "Cannot connect to Home Assistant. Check addon logs for details."
        exit 1
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        "entities"|"list")
            local domain="$1"
            local entities=$(fetch_entities)
            if [ $? -eq 0 ]; then
                local allowed_domains=$(get_allowed_domains)
                filter_entities_by_domain "$entities" "$allowed_domains" "$domain" | head -n "$MAX_ENTITIES"
            fi
            ;;
        "state"|"get")
            local entity_id="$1"
            if [ -z "$entity_id" ]; then
                echo "Usage: ha-context state <entity_id>"
                exit 1
            fi
            get_entity_state "$entity_id"
            ;;
        "summary")
            echo "Home Assistant System Summary"
            echo "============================="
            local entities=$(fetch_entities)
            if [ $? -eq 0 ]; then
                # Count total entities by counting entity_id occurrences
                local total=$(echo "$entities" | grep -o '"entity_id"' | wc -l)
                echo "Total entities: $total"
                echo ""
                echo "By domain:"
                # Extract entity IDs, get domains, count and sort
                extract_entity_ids "$entities" | cut -d. -f1 | sort | uniq -c | sort -nr
            fi
            ;;
        "help"|"--help"|"-h"|"")
            cat << EOF
Home Assistant Context Integration for Claude

Commands:
  ha-context entities [domain]  - List entities (optionally filtered by domain)
  ha-context state <entity_id>  - Get entity state and attributes
  ha-context summary           - Show system overview
  ha-context help              - Show this help

Examples:
  ha-context entities climate
  ha-context state sensor.living_room_temperature  
  ha-context summary

Allowed domains: $(get_allowed_domains)
EOF
            ;;
        *)
            echo "Unknown command: $command"
            echo "Run 'ha-context help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"