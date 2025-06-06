# Changelog

## 1.2.1

**Startup Reliability Fix**
- **FIX**: Resolved script module loading failure during container startup
- **FIX**: Added robust fallback script creation when security modules are missing
- **FIX**: Improved error handling for script copying and permission setting
- **FIX**: Added individual script validation and graceful degradation
- Enhanced logging for better troubleshooting of startup issues
- Ensured backward compatibility with minimal fallback implementations

## 1.2.0

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

## 1.1.0

**Rebranding and Name Change**
- Renamed from "Claude Terminal" to "Claude Home"
- Updated all references and branding to reflect new name
- No functional changes from previous version

## 1.0.2

**Security Improvements**
- **SECURITY**: Removed unnecessary file system access to other add-ons directory
- **SECURITY**: Limited credential search to specific safe locations only (/root, /root/.config)
- **SECURITY**: Bound web terminal to localhost instead of all network interfaces
- **SECURITY**: Added comprehensive input validation to credential management scripts
- **SECURITY**: Restricted credential file operations to known file types only
- **SECURITY**: Added file size limits for credential files (max 10KB)
- **SECURITY**: Improved error handling and path validation throughout

## 1.0.1

- Minor bug fixes and stability improvements

## 1.0.0

- First stable release of Claude Terminal add-on:
  - Web-based terminal interface using ttyd
  - Pre-installed Claude Code CLI
  - User-friendly interface with clean welcome message
  - Simple claude-logout command for authentication
  - Direct access to Home Assistant configuration
  - OAuth authentication with Anthropic account
  - Auto-launches Claude in interactive mode