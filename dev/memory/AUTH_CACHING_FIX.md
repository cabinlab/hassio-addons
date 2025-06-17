# Authentication Caching Fix for Claude Home

## Problem Summary

Authentication is not persisting between container restarts because:
1. Auth files are stored in `/root/.config/claude/` (container filesystem)
2. No mechanism copies them to `/config/claude-config/` (persistent volume)
3. Container restarts wipe `/root/` directory

## Current Behavior

```bash
# What happens now:
1. User authenticates with `claude login`
2. OAuth flow completes, auth stored in /root/.config/claude/
3. User restarts addon
4. /root/ is fresh, auth is lost
5. User must login again
```

## Proposed Fix

### Option 1: Symlink Approach (Simplest)
```bash
# In run-simple.sh, after creating directories:
mkdir -p /config/claude-config/.config/claude
mkdir -p /root/.config

# Symlink the entire claude config directory
ln -sf /config/claude-config/.config/claude /root/.config/claude

# This way auth.json saves directly to persistent storage
```

### Option 2: Copy on Startup/Shutdown
```bash
# On startup - restore auth if exists
if [ -f "/config/claude-config/.config/claude/auth.json" ]; then
    mkdir -p /root/.config/claude
    cp /config/claude-config/.config/claude/auth.json /root/.config/claude/
fi

# Need mechanism to copy back on shutdown (harder with Docker)
```

### Option 3: Environment Variable Approach
```bash
# Claude Code might respect these:
export CLAUDE_CONFIG_DIR="/config/claude-config/.config/claude"
export CLAUDE_AUTH_DIR="/config/claude-config/.config/claude"
```

## Recommended Implementation

Use Option 1 (symlink) because:
- Simplest to implement
- No need for shutdown hooks
- Auth saves directly to persistent volume
- Works transparently with Claude Code

## Implementation Steps

1. Update `run-simple.sh` to create symlink
2. Ensure `/config/claude-config/.config/claude` directory exists
3. Update auth check to look in correct location
4. Test auth persistence across restarts

## Additional Considerations

- Claude Code uses OAuth, not API keys
- Auth location may vary by Claude Code version
- Need to handle migration from old auth locations
- Consider security implications of persistent auth