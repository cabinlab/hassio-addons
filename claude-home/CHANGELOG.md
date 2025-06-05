# Changelog

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