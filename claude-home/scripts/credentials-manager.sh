#!/bin/bash

# Ensure credential directory exists
mkdir -p /config/claude-config

# Function to check if a file looks like valid credential data with advanced validation
is_valid_credential() {
    local file=$1
    local log_access=${2:-true}
    
    # Input validation
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        return 1
    fi
    
    # Log credential access for audit trail
    if [ "$log_access" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Validating credential file: $file" >> /config/claude-config/access.log
    fi
    
    # Check if it's a non-empty file and readable
    if [ ! -s "$file" ] || [ ! -r "$file" ]; then
        [ "$log_access" = "true" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: File empty or unreadable: $file" >> /config/claude-config/access.log
        return 1
    fi
    
    # Check file size bounds (min 10 bytes, max 10KB)
    local file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$file_size" -lt 10 ] || [ "$file_size" -gt 10240 ]; then
        [ "$log_access" = "true" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Invalid file size ($file_size bytes): $file" >> /config/claude-config/access.log
        return 1
    fi
    
    # Claude-specific pattern validation
    local has_claude_pattern=false
    local has_valid_structure=false
    
    # Check for Claude-specific credentials
    if grep -q "anthropic\|claude\|sk-ant-\|sessionKey\|api_key" "$file" 2>/dev/null; then
        has_claude_pattern=true
    fi
    
    # Check for general credential patterns
    if grep -q "token\|key\|auth\|cred\|api" "$file" 2>/dev/null; then
        has_claude_pattern=true
    fi
    
    # Validate JSON structure if file appears to be JSON
    if grep -q "^[[:space:]]*{" "$file" 2>/dev/null; then
        if jq empty "$file" 2>/dev/null; then
            has_valid_structure=true
            # Check for required Claude credential fields
            if jq -e '.sessionKey or .api_key or .token' "$file" >/dev/null 2>&1; then
                has_claude_pattern=true
            fi
        else
            [ "$log_access" = "true" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Invalid JSON structure: $file" >> /config/claude-config/access.log
            return 1
        fi
    else
        # For non-JSON files, check basic structure
        has_valid_structure=true
    fi
    
    # Validate credential integrity
    if [ "$has_claude_pattern" = "true" ] && [ "$has_valid_structure" = "true" ]; then
        [ "$log_access" = "true" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Valid credential file: $file" >> /config/claude-config/access.log
        return 0
    else
        [ "$log_access" = "true" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Invalid credential patterns: $file" >> /config/claude-config/access.log
        return 1
    fi
}

# Function to safely copy credential file with validation, backup, and integrity checking
safe_copy_credential() {
    local src="$1"
    local filename="$2"
    local create_backup=${3:-true}
    
    # Validate inputs
    if [ -z "$src" ] || [ -z "$filename" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Missing source or filename parameters" >> /config/claude-config/access.log
        return 1
    fi
    
    # Validate filename (only allow known credential file names)
    case "$filename" in
        .claude|.claude.json|credentials.json|auth.json)
            ;;
        *)
            echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Invalid filename: $filename" >> /config/claude-config/access.log
            return 1
            ;;
    esac
    
    local dest="/config/claude-config/$filename"
    local backup_dir="/config/claude-config/backups"
    
    # Create backup directory if needed
    if [ "$create_backup" = "true" ]; then
        mkdir -p "$backup_dir"
        chmod 700 "$backup_dir"
    fi
    
    # Create backup of existing credential if it exists
    if [ "$create_backup" = "true" ] && [ -f "$dest" ]; then
        local backup_file="$backup_dir/${filename}.$(date +%Y%m%d_%H%M%S).bak"
        if cp "$dest" "$backup_file" 2>/dev/null; then
            chmod 600 "$backup_file"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Backup created: $backup_file" >> /config/claude-config/access.log
            
            # Cleanup old backups (keep only last 5)
            ls -t "$backup_dir"/${filename}.*.bak 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
        fi
    fi
    
    # Copy new credential with integrity checking
    if cp -f "$src" "$dest" 2>/dev/null; then
        chmod 600 "$dest" 2>/dev/null
        
        # Calculate and store file hash for integrity verification
        local src_hash=$(sha256sum "$src" 2>/dev/null | cut -d' ' -f1)
        local dest_hash=$(sha256sum "$dest" 2>/dev/null | cut -d' ' -f1)
        
        if [ "$src_hash" = "$dest_hash" ] && [ -n "$src_hash" ]; then
            echo "$dest_hash" > "/config/claude-config/${filename}.hash"
            chmod 600 "/config/claude-config/${filename}.hash"
            echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Credential copied with integrity check: $filename (hash: ${src_hash:0:16}...)" >> /config/claude-config/access.log
            return 0
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Integrity check failed for: $filename" >> /config/claude-config/access.log
            rm -f "$dest" 2>/dev/null
            return 1
        fi
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: Could not copy credential: $src -> $dest" >> /config/claude-config/access.log
        return 1
    fi
}

# Function to verify credential integrity
verify_credential_integrity() {
    local filename="$1"
    local dest="/config/claude-config/$filename"
    local hash_file="/config/claude-config/${filename}.hash"
    
    if [ ! -f "$dest" ] || [ ! -f "$hash_file" ]; then
        return 1
    fi
    
    local stored_hash=$(cat "$hash_file" 2>/dev/null)
    local current_hash=$(sha256sum "$dest" 2>/dev/null | cut -d' ' -f1)
    
    if [ "$stored_hash" = "$current_hash" ] && [ -n "$stored_hash" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Integrity verified: $filename" >> /config/claude-config/access.log
        return 0
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Integrity check failed for: $filename" >> /config/claude-config/access.log
        return 1
    fi
}

# Function to find and save credentials
save_credentials() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting credential save operation" >> /config/claude-config/access.log
    
    # First, verify integrity of existing credentials
    for existing_cred in ".claude" ".claude.json" "credentials.json" "auth.json"; do
        if [ -f "/config/claude-config/$existing_cred" ]; then
            verify_credential_integrity "$existing_cred"
        fi
    done
    
    # Look in known credential locations with validation
    for location in "/root/.claude" "/root/.claude.json" "/root/.config/anthropic/credentials.json"; do
        if [ -f "$location" ] && is_valid_credential "$location"; then
            safe_copy_credential "$location" "$(basename "$location")"
        fi
    done
    
    # Search for credential files in specific safe locations only
    for search_dir in "/root/.config" "/root"; do
        if [ -d "$search_dir" ]; then
            while IFS= read -r -d '' file; do
                if [ -f "$file" ] && is_valid_credential "$file"; then
                    # Only copy files with known credential patterns using safe copy
                    safe_copy_credential "$file" "$(basename "$file")"
                fi
            done < <(find "$search_dir" -maxdepth 2 -type f \( -name ".claude*" -o -name "credentials.json" -o -name "auth.json" \) -print0 2>/dev/null)
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Credential save operation completed" >> /config/claude-config/access.log
}

# Function to initialize credential management with security checks
init_credential_security() {
    # Ensure secure credential directory structure
    mkdir -p /config/claude-config/backups
    chmod 700 /config/claude-config
    chmod 700 /config/claude-config/backups
    
    # Initialize audit log with secure permissions
    touch /config/claude-config/access.log
    chmod 600 /config/claude-config/access.log
    
    # Log startup
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Credential security initialization started" >> /config/claude-config/access.log
    
    # Verify integrity of all existing credentials
    local integrity_passed=0
    local integrity_failed=0
    
    for cred_file in ".claude" ".claude.json" "credentials.json" "auth.json"; do
        if [ -f "/config/claude-config/$cred_file" ]; then
            if verify_credential_integrity "$cred_file"; then
                integrity_passed=$((integrity_passed + 1))
            else
                integrity_failed=$((integrity_failed + 1))
            fi
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Startup integrity check: $integrity_passed passed, $integrity_failed failed" >> /config/claude-config/access.log
    
    # Clean up old audit logs (keep last 30 days)
    if [ -f /config/claude-config/access.log ]; then
        tail -n 10000 /config/claude-config/access.log > /config/claude-config/access.log.tmp 2>/dev/null
        mv /config/claude-config/access.log.tmp /config/claude-config/access.log 2>/dev/null
    fi
}

# Function to clear credentials
logout() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Credential logout initiated" >> /config/claude-config/access.log
    echo "Clearing all credentials..."
    rm -rf /config/claude-config/.claude* /root/.claude*
    rm -rf /root/.config/anthropic /config/claude-config/credentials.json
    rm -f /config/claude-config/*.hash
    echo "Credentials cleared. Please restart to re-authenticate."
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Credential logout completed" >> /config/claude-config/access.log
}

# Initialize security on first run or when explicitly called
if [ "$1" = "init" ] || [ ! -f "/config/claude-config/access.log" ]; then
    init_credential_security
fi

# Process commands with input validation
case "$1" in
    init)
        init_credential_security
        echo "Credential security initialized"
        ;;
    save)
        save_credentials
        echo "Credentials saved to persistent storage"
        ;;
    verify)
        echo "Verifying credential integrity..."
        verified=0
        failed=0
        for cred_file in ".claude" ".claude.json" "credentials.json" "auth.json"; do
            if [ -f "/config/claude-config/$cred_file" ]; then
                if verify_credential_integrity "$cred_file"; then
                    echo "✓ $cred_file: integrity verified"
                    verified=$((verified + 1))
                else
                    echo "✗ $cred_file: integrity check failed"
                    failed=$((failed + 1))
                fi
            fi
        done
        echo "Verification complete: $verified verified, $failed failed"
        ;;
    logout)
        logout
        ;;
    ""|*)
        # Default behavior: save credentials (empty or invalid input)
        save_credentials
        ;;
esac