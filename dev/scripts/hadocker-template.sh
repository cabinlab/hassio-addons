#!/bin/bash
# Template processing functions for hadocker deployment

generate_hadocker_compose() {
    local addon_name="$1"
    local dev_version="$2" 
    local addon_dir="$3"
    local hadocker_dir="$4"
    
    # Read config.yaml to extract port information
    local config_file="$addon_dir/config.yaml"
    if [ ! -f "$config_file" ]; then
        echo "Error: config.yaml not found in $addon_dir"
        return 1
    fi
    
    # Read compose template
    local template_file="$addon_dir/compose.yaml"
    if [ ! -f "$template_file" ]; then
        echo "Error: compose.yaml template not found in $addon_dir"
        return 1
    fi
    
    # Create target directory
    local target_dir="$hadocker_dir/addons/$addon_name"
    mkdir -p "$target_dir/data"
    
    # Generate configuration YAML file from config.yaml defaults
    generate_config_yaml "$config_file" "$target_dir/config.yaml"
    
    # Generate port assignments (avoid conflicts)
    local port_8080=$(find_available_port 8080)
    local port_7681=$(find_available_port 7681) 
    local port_3000=$(find_available_port 3000)
    local port_8001=$(find_available_port 8001)
    
    # Set variables for substitution
    local ha_config_dir="$hadocker_dir/config"
    local container_name="${addon_name}-${dev_version}"
    
    # Perform variable substitution
    sed \
        -e "s|{{VERSION}}|$dev_version|g" \
        -e "s|{{CONTAINER_NAME}}|$container_name|g" \
        -e "s|{{HA_CONFIG_DIR}}|$ha_config_dir|g" \
        -e "s|{{PORT_8080}}|$port_8080|g" \
        -e "s|{{PORT_7681}}|$port_7681|g" \
        -e "s|{{PORT_3000}}|$port_3000|g" \
        -e "s|{{PORT_8001}}|$port_8001|g" \
        "$template_file" > "$target_dir/compose.yaml"
    
    echo "Generated compose file at $target_dir/compose.yaml"
    echo "Ports assigned: 8080->$port_8080, 7681->$port_7681, 3000->$port_3000, 8001->$port_8001"
}

generate_config_yaml() {
    local config_file="$1"
    local output_file="$2"
    
    # Extract default options from config.yaml and create standalone config
    # This is a simplified version - would need proper YAML parsing
    cat > "$output_file" << 'EOF'
claude_model: haiku
theme: dark
auto_claude: false
verbose_logging: false
chat_interface: true
gateway_port: 8001
terminal_bell: true
ha_notifications: false
notification_service: persistent_notification
working_directory: /config
EOF
}

find_available_port() {
    local preferred_port="$1"
    local port=$preferred_port
    
    # Simple port availability check
    while netstat -tuln 2>/dev/null | grep -q ":$port "; do
        port=$((port + 1))
    done
    
    echo $port
}

# Check if Docker network exists, create if not
ensure_homeassistant_network() {
    if ! docker network ls | grep -q homeassistant; then
        echo "Creating homeassistant Docker network..."
        docker network create homeassistant
    fi
}