#!/bin/bash

# Application security controls for Node.js/npm and Claude CLI
# This script implements application-level security restrictions

# Function to configure npm security settings
configure_npm_security() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring npm security settings" >> /config/claude-config/security.log
    
    # Set npm security configuration
    npm config set audit-level moderate 2>/dev/null || true
    npm config set fund false 2>/dev/null || true
    npm config set update-notifier false 2>/dev/null || true
    
    # Disable npm automatic package installation
    npm config set save-exact true 2>/dev/null || true
    npm config set package-lock true 2>/dev/null || true
    
    # Set secure registry (use HTTPS)
    npm config set registry https://registry.npmjs.org/ 2>/dev/null || true
    
    # Disable scripts from untrusted packages
    npm config set ignore-scripts true 2>/dev/null || true
    
    # Log configuration
    echo "$(date '+%Y-%m-%d %H:%M:%S') - npm security configuration applied" >> /config/claude-config/security.log
}

# Function to configure Node.js security settings
configure_nodejs_security() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Configuring Node.js security settings" >> /config/claude-config/security.log
    
    # Set Node.js security environment variables
    export NODE_ENV=production
    export NODE_OPTIONS="--max-old-space-size=256 --max-semi-space-size=64"
    
    # Disable Node.js deprecation warnings in production
    export NODE_NO_WARNINGS=1
    
    # Set TLS security settings
    export NODE_TLS_REJECT_UNAUTHORIZED=1
    
    # Disable automatic update checks
    export NO_UPDATE_NOTIFIER=1
    export DISABLE_OPENCOLLECTIVE=1
    
    # Log environment variables
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Node.js security environment configured" >> /config/claude-config/security.log
}

# Function to validate Claude CLI installation integrity
validate_claude_installation() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Validating Claude CLI installation" >> /config/claude-config/security.log
    
    # Check if Claude CLI is properly installed
    local claude_path=$(which claude 2>/dev/null)
    if [ -z "$claude_path" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Claude CLI not found" >> /config/claude-config/security.log
        return 1
    fi
    
    # Verify Claude CLI is executable
    if [ ! -x "$claude_path" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Claude CLI not executable: $claude_path" >> /config/claude-config/security.log
        return 1
    fi
    
    # Check package integrity (basic check)
    local claude_dir=$(dirname "$claude_path")
    if [ ! -d "$claude_dir" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Claude CLI directory missing: $claude_dir" >> /config/claude-config/security.log
        return 1
    fi
    
    # Verify package.json exists and is readable
    local package_json=""
    for pkg_path in "$claude_dir/../package.json" "$claude_dir/../../package.json" "/usr/local/lib/node_modules/@anthropic-ai/claude-code/package.json"; do
        if [ -f "$pkg_path" ] && [ -r "$pkg_path" ]; then
            package_json="$pkg_path"
            break
        fi
    done
    
    if [ -n "$package_json" ]; then
        # Verify package.json is valid JSON
        if jq empty "$package_json" >/dev/null 2>&1; then
            local pkg_name=$(jq -r '.name // "unknown"' "$package_json" 2>/dev/null)
            local pkg_version=$(jq -r '.version // "unknown"' "$package_json" 2>/dev/null)
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Claude CLI validation: $pkg_name@$pkg_version at $claude_path" >> /config/claude-config/security.log
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Invalid package.json for Claude CLI" >> /config/claude-config/security.log
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: package.json not found for Claude CLI" >> /config/claude-config/security.log
    fi
    
    return 0
}

# Function to implement runtime security controls
implement_runtime_controls() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Implementing application runtime controls" >> /config/claude-config/security.log
    
    # Create secure wrapper for Claude CLI
    local claude_wrapper="/usr/local/bin/claude-secure"
    cat > "$claude_wrapper" << 'EOF'
#!/bin/bash

# Secure wrapper for Claude CLI execution
# Applies additional security controls before running Claude

# Set secure environment
export NODE_ENV=production
export NODE_OPTIONS="--max-old-space-size=256 --max-semi-space-size=64"
export NODE_NO_WARNINGS=1
export NODE_TLS_REJECT_UNAUTHORIZED=1
export NO_UPDATE_NOTIFIER=1

# Log command execution
echo "$(date '+%Y-%m-%d %H:%M:%S') - Claude CLI execution: $*" >> /config/claude-config/app-usage.log

# Apply additional resource limits for this process
ulimit -t 1800  # 30 minutes max execution time
ulimit -v 524288  # 512MB virtual memory
ulimit -f 51200   # 50MB max file size

# Execute Claude CLI with arguments
exec node $(which claude) "$@"
EOF
    
    chmod +x "$claude_wrapper"
    
    # Create application usage log
    touch /config/claude-config/app-usage.log
    chmod 600 /config/claude-config/app-usage.log
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Runtime security controls implemented" >> /config/claude-config/security.log
}

# Function to audit npm dependencies
audit_dependencies() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting npm dependency audit" >> /config/claude-config/security.log
    
    # Run npm audit for Claude CLI package
    local audit_output="/tmp/npm-audit.json"
    
    # Find Claude CLI package directory
    local claude_pkg_dir=""
    for pkg_dir in "/usr/local/lib/node_modules/@anthropic-ai/claude-code" "$(npm root -g)/@anthropic-ai/claude-code"; do
        if [ -d "$pkg_dir" ]; then
            claude_pkg_dir="$pkg_dir"
            break
        fi
    done
    
    if [ -n "$claude_pkg_dir" ] && [ -f "$claude_pkg_dir/package.json" ]; then
        cd "$claude_pkg_dir" || return 1
        
        # Run audit and capture results
        npm audit --json > "$audit_output" 2>/dev/null || true
        
        if [ -f "$audit_output" ]; then
            # Parse audit results
            local vulnerabilities=$(jq -r '.metadata.vulnerabilities // {} | to_entries | length' "$audit_output" 2>/dev/null || echo "0")
            local high_vulns=$(jq -r '.metadata.vulnerabilities.high // 0' "$audit_output" 2>/dev/null || echo "0")
            local critical_vulns=$(jq -r '.metadata.vulnerabilities.critical // 0' "$audit_output" 2>/dev/null || echo "0")
            
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Dependency audit: $vulnerabilities total, $high_vulns high, $critical_vulns critical" >> /config/claude-config/security.log
            
            # Log critical vulnerabilities
            if [ "$critical_vulns" -gt 0 ] || [ "$high_vulns" -gt 0 ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: High/critical vulnerabilities detected" >> /config/claude-config/security.log
                jq -r '.vulnerabilities // {} | to_entries[] | select(.value.severity == "high" or .value.severity == "critical") | "\(.key): \(.value.severity)"' "$audit_output" 2>/dev/null >> /config/claude-config/security.log || true
            fi
            
            rm -f "$audit_output"
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Claude CLI package directory not found for audit" >> /config/claude-config/security.log
    fi
}

# Function to monitor application performance
monitor_app_performance() {
    local log_file="/config/claude-config/app-performance.log"
    
    # Create performance log if it doesn't exist
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
        chmod 600 "$log_file"
    fi
    
    # Log Node.js process information
    {
        echo "$(date '+%Y-%m-%d %H:%M:%S') Application Performance:"
        echo "  Node.js processes: $(pgrep -c node)"
        echo "  npm processes: $(pgrep -c npm)"
        echo "  Total memory usage: $(ps aux | grep -E '(node|npm)' | awk '{sum+=$6} END {print sum/1024" MB"}')"
        echo "  Node.js version: $(node --version 2>/dev/null || echo 'unknown')"
        echo "  npm version: $(npm --version 2>/dev/null || echo 'unknown')"
        echo "---"
    } >> "$log_file"
    
    # Keep only last 50 entries
    tail -n 250 "$log_file" > "$log_file.tmp" 2>/dev/null
    mv "$log_file.tmp" "$log_file" 2>/dev/null
}

# Main execution based on command
case "$1" in
    configure)
        configure_npm_security
        configure_nodejs_security
        ;;
    validate)
        validate_claude_installation
        ;;
    runtime)
        implement_runtime_controls
        ;;
    audit)
        audit_dependencies
        ;;
    monitor)
        monitor_app_performance
        ;;
    all)
        configure_npm_security
        configure_nodejs_security
        validate_claude_installation
        implement_runtime_controls
        audit_dependencies
        monitor_app_performance
        ;;
    *)
        echo "Usage: $0 {configure|validate|runtime|audit|monitor|all}"
        echo "  configure - Configure npm and Node.js security settings"
        echo "  validate  - Validate Claude CLI installation integrity"
        echo "  runtime   - Implement runtime security controls"
        echo "  audit     - Audit npm dependencies for vulnerabilities"
        echo "  monitor   - Monitor application performance"
        echo "  all       - Run all application security functions"
        exit 1
        ;;
esac