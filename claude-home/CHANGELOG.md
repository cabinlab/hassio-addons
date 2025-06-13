# Changelog

## 2.2.5 - 2025-06-13

### MCP (Model Context Protocol) Integration Fixed
- **FIXED**: Home Assistant MCP server connection issues resolved
- **FIXED**: hass-mcp now properly launches with correct working directory
- **IMPROVED**: Simplified MCP configuration - removed non-working native HA MCP
- **NEW**: Full access to Home Assistant entities, automations, and services via MCP
- Users with ha_url and ha_token configured can now use Claude Code with Home Assistant

## 2.2.0 - 2025-06-13

### Home Assistant Integration
- **NEW**: Added MCP (Model Context Protocol) support for Home Assistant
- **NEW**: Configuration options for custom Home Assistant URL and token
- **NEW**: Integrated hass-mcp for entity and automation access
- **NEW**: Context7 documentation server included
- **IMPROVED**: Added homeassistant_api permission for better integration

## 2.0.0 - 2025-06-12

### Major Platform Change
- **BREAKING**: Migrated from Alpine Linux to Debian base for improved compatibility
- **NEW**: Full support for standard Claude Code installation via npm
- **NEW**: Native ttyd web terminal without Alpine-specific workarounds
- **FIXED**: All authentication and startup issues from Alpine limitations

### Configuration Improvements
- **NEW**: Simplified model selection to three clear options (Haiku, Sonnet, Opus)
- **NEW**: Auto-start Claude option for immediate access
- **IMPROVED**: Better configuration validation and error messages

### Bug Fixes
- **FIXED**: Startup script variable errors causing boot loops
- **FIXED**: Model selection now properly persists across restarts
- **FIXED**: Authentication detection works reliably
- **FIXED**: Terminal color rendering and UI display issues

## 1.4.14 - 2025-06-06

### Critical Fixes
- **FIXED: Model selection bug** - Claude now correctly uses configured model (Haiku) instead of defaulting to Opus (60x cost savings!)
  - Settings.json now created at correct location: `~/.claude/settings.json`
  - Environment variable properly persisted to terminal session
  - Explicit --model parameter used when auto-starting Claude
- **FIXED: Authentication detection** - Reliable auth status checking
  - Now checks correct auth file location: `~/.config/claude/auth.json`
  - Uses --no-update-check flag to avoid timeout issues
  - Properly distinguishes between missing and invalid credentials
- **FIXED: BusyBox compatibility** - Claude auth now works properly
  - Created wrapper script to bypass env -S issue
  - Dynamically finds Claude CLI in npx cache
  - Transparent replacement via symlink

### Improvements
- Model information displayed in terminal header
- Increased auth check timeout for reliability
- Better logging of authentication status

### Technical Details
- Wrapper installed at `/usr/local/bin/claude`
- Settings created in both locations for compatibility
- Auth checks multiple credential locations with fallbacks

## 1.4.0 - 2025-06-06

**Home Assistant Context Integration**
- **NEW**: Added comprehensive Home Assistant context integration for Claude
- **NEW**: `ha` command provides direct access to HA entities and state from Claude terminal
- **NEW**: Entity listing by domain: `ha entities climate`, `ha entities sensor`, etc.
- **NEW**: Individual entity state access: `ha state sensor.living_room_temperature`
- **NEW**: System overview with entity counts: `ha summary`
- **NEW**: Configurable domain filtering - choose which entity types Claude can access
- **NEW**: Entity limit controls to prevent information overload
- **NEW**: Intelligent caching of HA API responses for performance
- **NEW**: Bash-only JSON parsing - no external dependencies required
- **SECURITY**: Read-only access with comprehensive input validation
- **SECURITY**: Domain filtering prevents access to sensitive entity types
- **SECURITY**: Rate limiting and caching prevent API abuse
- Welcome screen now shows available HA context commands when enabled
- All context data automatically available to Claude for enhanced automation assistance
- Perfect integration with existing security framework and configuration system

## 1.3.1 - 2025-06-06

**Configuration System Refactoring**
- **IMPROVEMENT**: Refactored configuration system to use Claude's native settings.json format
- **IMPROVEMENT**: Simplified startup process by removing complex CLI flag building
- **IMPROVEMENT**: More maintainable configuration management with direct HA config → settings.json mapping
- **IMPROVEMENT**: Cleaner terminal output without verbose environment variable logging
- **IMPROVEMENT**: Better alignment with Claude Code's intended configuration patterns
- Configuration changes still take effect immediately after addon restart
- All existing configuration options remain fully supported
- Improved startup reliability and reduced complexity

## 1.3.0 - 2025-06-06

**Comprehensive Configuration Enhancement**
- **NEW**: Add native Home Assistant configuration option for Claude model selection
- **NEW**: Support for multiple Claude models via dropdown configuration UI
- **NEW**: Theme selection (dark, light, daltonized variants) for better accessibility
- **NEW**: Verbose logging toggle for detailed Claude operation visibility
- **NEW**: Max turns limit to prevent runaway conversations (safety feature)
- **NEW**: Telemetry control to disable Claude usage analytics
- **NEW**: Terminal bell audio feedback configuration
- **NEW**: Home Assistant notifications integration (future feature)
- **NEW**: Configurable notification service selection
- Available models: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus, Claude 3 Sonnet, Claude 3 Haiku
- Default model: claude-3-5-sonnet-20241022 (latest and most capable)
- Enhanced startup configuration display in terminal
- Comprehensive configuration documentation and examples
- All settings persist across addon restarts with immediate effect

## 1.2.3 - 2025-06-06

**Node.js Warning Suppression**
- **FIX**: Suppress Node.js MaxListenersExceededWarning from Claude CLI
- Add --max-listeners=20 to NODE_OPTIONS to prevent memory leak warnings
- Improve console output cleanliness for better user experience

## 1.2.2 - 2025-06-06

**Web UI Access Fix**
- **FIX**: Resolved web UI accessibility issue by binding to 0.0.0.0 instead of localhost
- **FIX**: Fixed BusyBox pgrep compatibility issue causing command errors
- Web terminal now properly accessible from Home Assistant ingress
- Improved network configuration for container environment

## 1.2.1 - 2025-06-06

**Startup Reliability Fix**
- **FIX**: Resolved script module loading failure during container startup
- **FIX**: Added robust fallback script creation when security modules are missing
- **FIX**: Improved error handling for script copying and permission setting
- **FIX**: Added individual script validation and graceful degradation
- Enhanced logging for better troubleshooting of startup issues
- Ensured backward compatibility with minimal fallback implementations

## 1.2.0 - 2025-06-06

**Major Security Enhancement Update**
- **SECURITY**: Implemented comprehensive container security framework
- **SECURITY**: Enhanced credential validation with advanced pattern checking and integrity verification
- **SECURITY**: Added automatic credential backup and hash-based integrity checking
- **SECURITY**: Implemented process resource limits (ulimit controls) for file descriptors, memory, CPU time, and processes
- **SECURITY**: Added application security controls for Node.js/npm with secure configurations
- **SECURITY**: Implemented comprehensive container activity monitoring with anomaly detection
- **SECURITY**: Added filesystem access controls with permission auditing and access restrictions
- **SECURITY**: Created modular security script architecture for maintainability
- **SECURITY**: Added comprehensive audit logging for all security events
- **SECURITY**: Implemented security status verification and reporting
- **SECURITY**: Added automatic cleanup and log rotation for security logs
- **SECURITY**: Created secure credential access patterns with monitoring
- **MONITORING**: Real-time monitoring of processes, network connections, filesystem changes, and resource usage
- **MONITORING**: Anomaly detection for suspicious activities and resource violations
- **MONITORING**: Separate log files for different security aspects (access, activity, integrity, etc.)
- Enhanced startup sequence with comprehensive security initialization
- Added convenience aliases for all security tools
- Improved error handling and fallback mechanisms throughout

## 1.1.0 - 2025-06-06

**Rebranding and Name Change**
- Renamed from "Claude Terminal" to "Claude Home"
- Updated all references and branding to reflect new name
- No functional changes from previous version

## 1.0.2 - 2025-06-06

**Security Improvements**
- **SECURITY**: Removed unnecessary file system access to other add-ons directory
- **SECURITY**: Limited credential search to specific safe locations only (/root, /root/.config)
- **SECURITY**: Bound web terminal to localhost instead of all network interfaces
- **SECURITY**: Added comprehensive input validation to credential management scripts
- **SECURITY**: Restricted credential file operations to known file types only
- **SECURITY**: Added file size limits for credential files (max 10KB)
- **SECURITY**: Improved error handling and path validation throughout

## 1.0.1 - 2025-06-06

- Minor bug fixes and stability improvements

## 1.0.0 - 2025-06-06

- First stable release of Claude Terminal add-on:
  - Web-based terminal interface using ttyd
  - Pre-installed Claude Code CLI
  - User-friendly interface with clean welcome message
  - Simple claude-logout command for authentication
  - Direct access to Home Assistant configuration
  - OAuth authentication with Anthropic account
  - Auto-launches Claude in interactive mode