# Configuration File Structure

## The Problem

Claude Code configuration files (settings.json, .mcp.json) appear to be duplicated in multiple locations, which initially seems like poor design or "configuration sprawl."

## The Solution

This apparent duplication is actually intentional and necessary due to:

1. **User-configurable working directory** - Users can select where the terminal starts:
   - `/config`
   - `/config/claude-workspace`
   - `/root`
   - `/config/custom_components`

2. **Claude Code's config search pattern** - Claude Code looks for configuration in:
   - Current working directory (for .mcp.json)
   - User config directory (~/.claude/)
   - Various fallback locations

3. **Container restart persistence** - Configs must survive container restarts

## Implementation

### Persistent Storage
- `/config/claude-config/` - Main persistent storage that survives container restarts

### Symlinks for Persistence
- `/root/.claude` → `/config/claude-config/.claude`
- `/root/.config/claude` → `/config/claude-config/.config/claude`

### Config File Locations

#### .mcp.json (MCP server configuration)
Created in multiple locations because Claude Code checks the current directory:
1. `/config/claude-config/.mcp.json` - Persistent storage
2. `/root/.mcp.json` - For when working directory is /root
3. `$WORKING_DIR/.mcp.json` - For user's selected working directory
4. `/config/claude-config/.config/claude/.mcp.json` - Additional fallback

#### settings.json (Claude settings)
1. `/root/.claude/settings.json` - Primary location (via symlink)
2. `/config/claude-config/settings.json` - Backup/reference copy

## Why This Works

- **Flexibility**: Supports any working directory the user chooses
- **Persistence**: Survives container restarts via /config mount
- **Compatibility**: Works with Claude Code's various config search paths
- **User Experience**: "Just works" regardless of where user starts

## Alternative Considered

Single config location with environment variables pointing to it - but this doesn't work well with Claude Code's hardcoded search paths.

## Conclusion

The "messy" multiple config files are a feature, not a bug. They ensure Claude Code can find its configuration regardless of the user's working directory choice while maintaining persistence across container restarts.