#!/bin/bash

# Ensure credential directory exists
mkdir -p /config/claude-config

# Function to check if a file looks like valid credential data
is_valid_credential() {
    local file=$1
    
    # Input validation
    if [ -z "$file" ] || [ ! -f "$file" ]; then
        return 1
    fi
    
    # Check if it's a non-empty file and readable
    if [ ! -s "$file" ] || [ ! -r "$file" ]; then
        return 1
    fi
    
    # Check file size (should be reasonable for credential files, max 10KB)
    local file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
    if [ "$file_size" -gt 10240 ]; then
        return 1
    fi
    
    # Check if the file contains credential data patterns
    if grep -q "token\|key\|auth\|cred\|api" "$file" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to safely copy credential file with validation
safe_copy_credential() {
    local src="$1"
    local filename="$2"
    
    # Validate inputs
    if [ -z "$src" ] || [ -z "$filename" ]; then
        return 1
    fi
    
    # Validate filename (only allow known credential file names)
    case "$filename" in
        .claude|.claude.json|credentials.json|auth.json)
            ;;
        *)
            return 1
            ;;
    esac
    
    # Copy and set permissions
    if cp -f "$src" "/config/claude-config/$filename" 2>/dev/null; then
        chmod 600 "/config/claude-config/$filename" 2>/dev/null
        return 0
    fi
    return 1
}

# Function to find and save credentials
save_credentials() {
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
}

# Function to clear credentials
logout() {
    echo "Clearing all credentials..."
    rm -rf /config/claude-config/.claude* /root/.claude*
    rm -rf /root/.config/anthropic /config/claude-config/credentials.json
    echo "Credentials cleared. Please restart to re-authenticate."
}

# Process commands with input validation
case "$1" in
    save)
        save_credentials
        echo "Credentials saved to persistent storage"
        ;;
    logout)
        logout
        ;;
    ""|*)
        # Default behavior: save credentials (empty or invalid input)
        save_credentials
        ;;
esac