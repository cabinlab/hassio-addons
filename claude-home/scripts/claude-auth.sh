#!/bin/bash

show_help() {
    echo "Claude Auth Tool - Manage Claude authentication"
    echo ""
    echo "Usage:"
    echo "  claude-auth debug     - Show debugging information"
    echo "  claude-auth find      - Search for credential files"
    echo "  claude-auth save      - Save credentials to persistent storage"
    echo "  claude-auth logout    - Clear credentials and force re-authentication"
    echo "  claude-auth help      - Show this help message"
}

find_credentials() {
    echo "Searching for credential files..."
    echo ""
    echo "Looking in safe locations:"
    for search_dir in "/root" "/root/.config" "/config/claude-config"; do
        if [ -d "$search_dir" ]; then
            echo "Checking $search_dir:"
            find "$search_dir" -maxdepth 2 -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | sort
        fi
    done
}

debug_info() {
    echo "===== CLAUDE AUTH DEBUG ====="
    echo "Directory contents of /config/claude-config:"
    ls -la /config/claude-config/
    echo ""
    echo "Default config directory contents:"
    ls -la /root/.config/anthropic/ 2>/dev/null || echo "Directory does not exist"
    echo ""
    echo "Home directory contents:"
    ls -la "$HOME/.config/" 2>/dev/null || echo "Directory does not exist"
    echo ""
    echo "Environment variables:"
    echo "CLAUDE_CREDENTIALS_DIRECTORY=$CLAUDE_CREDENTIALS_DIRECTORY"
    echo "ANTHROPIC_CONFIG_DIR=$ANTHROPIC_CONFIG_DIR"
    echo "HOME=$HOME"
    echo ""
    echo "Node executable path:"
    which node
    echo ""
    echo "Claude executable path:"
    which claude
    echo ""
}

save_credentials() {
    echo "Attempting to save credentials to persistent storage..."
    
    # Save the specific Claude credential files we've identified
    if [ -f "/root/.claude" ]; then
        echo "Copying /root/.claude to /config/claude-config/.claude"
        cp -v "/root/.claude" "/config/claude-config/.claude"
    else
        echo "Claude credential file not found at /root/.claude"
    fi
    
    if [ -f "/root/.claude.json" ]; then
        echo "Copying /root/.claude.json to /config/claude-config/.claude.json"
        cp -v "/root/.claude.json" "/config/claude-config/.claude.json"
    else
        echo "Claude JSON credential file not found at /root/.claude.json"
    fi
    
    # Search for credential files in safe locations only
    for search_dir in "/root/.config" "/root"; do
        if [ -d "$search_dir" ]; then
            cred_files=$(find "$search_dir" -maxdepth 2 -name "auth.json" -o -name "*claude*" -o -name "*anthropic*" 2>/dev/null | grep -v "bin/claude\|bin/claude-auth")
            if [ -n "$cred_files" ]; then
                echo "Found credential files in $search_dir:"
                for file in $cred_files; do
                    # Only copy known credential file types
                    case "$(basename "$file")" in
                        .claude|.claude.json|credentials.json|auth.json)
                            if [ -f "$file" ] && [ ! -x "$file" ]; then
                                dest="/config/claude-config/$(basename "$file")"
                                echo "Copying $file to $dest"
                                cp -v "$file" "$dest"
                            fi
                            ;;
                        *)
                            echo "Skipping unknown file type: $file"
                            ;;
                    esac
                done
            fi
        fi
    done
    
    echo "Setting permissions on credential files..."
    chmod -R 755 /config/claude-config/
    
    echo "Done saving credentials."
}

logout() {
    echo "Clearing credentials and symlinks..."
    rm -rf /config/claude-config/* /root/.config/anthropic/
    # Only remove credential files from safe locations
    for search_dir in "/root" "/root/.config"; do
        if [ -d "$search_dir" ]; then
            find "$search_dir" -maxdepth 2 \( -name ".claude" -o -name ".claude.json" -o -name "auth.json" -o -name "credentials.json" \) -type f -delete 2>/dev/null
        fi
    done
    echo "All credentials cleared. Please restart the add-on to re-authenticate."
}

case "$1" in
    debug)
        debug_info
        ;;
    find)
        find_credentials
        ;;
    save)
        save_credentials
        ;;
    logout)
        logout
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        ;;
esac