#!/bin/bash
# Claude wrapper script to handle authentication better

# Function to extract token from credentials file
extract_token() {
    if [ -f "/root/.claude/.credentials.json" ]; then
        # Extract access token using grep and sed (jq might not be available)
        token=$(grep -o '"accessToken":"[^"]*"' /root/.claude/.credentials.json 2>/dev/null | sed 's/"accessToken":"//' | sed 's/"$//')
        if [ -n "$token" ]; then
            echo "$token"
            return 0
        fi
    fi
    return 1
}

# Function to check if we need auth
check_auth_needed() {
    # Try a quick non-interactive command
    if timeout 2 /usr/local/bin/claude --version >/dev/null 2>&1; then
        return 1  # Auth not needed
    fi
    return 0  # Auth needed
}

# Main wrapper logic
case "$1" in
    auth)
        # For auth command, just pass through
        exec /usr/local/bin/claude "$@"
        ;;
    *)
        # For other commands, check auth first
        if check_auth_needed; then
            echo "Checking stored credentials..."
            
            echo "Authentication required after container restart"
            echo "This is a known limitation with Claude Code in containers"
            echo ""
            echo "OAuth session state cannot be restored from credential files alone."
            echo "Please run 'claude auth' to re-authenticate"
            exit 1
        fi
        
        # Execute the actual command
        exec /usr/local/bin/claude "$@"
        ;;
esac