# Changelog
All notable changes to this project will be documented in this file.

## [2.1.0] - 2025-01-08

### 🎨 MAJOR UX IMPROVEMENT: Simplified Connection Configuration
- **Single Connection Type Dropdown**: Replace confusing separate Cable/Protocol dropdowns with unified selection
- **Pre-tested Combinations**: Only show working cable/protocol combinations that are known to function
- **Clear Descriptions**: Each option explains what hardware setup it supports with emoji icons
- **Recommended Default**: Set `smart_usb` as default (the proven working configuration)
- **Eliminates Confusion**: No more guessing which cable+protocol combinations work together

### Available Connection Types
- 🔌 **Smart Cable + USB Protocol** (RECOMMENDED - proven working)
- 🔌 **USB Cable + USB Protocol** (Standard consumer UPS)
- 📡 **Smart Cable + APC Smart Protocol** (Enterprise/serial UPS)
- 📡 **USB Cable + APC Smart Protocol** (Hybrid configuration)
- 🔗 **Simple Cable + Dumb Protocol** (Basic serial UPS)
- 🌐 **Ethernet + Network Protocol** (Network UPS)
- 📊 **SNMP + SNMP Protocol** (Enterprise SNMP UPS)

## [2.0.20] - 2025-01-08

### 🔧 CRITICAL FIX: Container Permissions for USB Devices
- **Added `full_access: true`**: Enables proper USB device access in container environment
- **Resolved "Read-only file system" errors**: Fixed the core issue preventing daemon communication
- **Restored original functionality**: Matches the hardware access that made the pre-fork version work

### Root Cause & Solution
The modernized add-on had restrictive container security that prevented USB device write access. After extensive troubleshooting including device auto-detection, permissions fixes, and protocol testing, the issue was identified as missing container privileges. Adding `full_access: true` restored the hardware access needed for USB UPS communication.

### What We Learned
- **Strategies that didn't work**: Device path auto-detection, permission changes, protocol switching
- **Root cause**: Container filesystem restrictions preventing daemon USB access  
- **Solution**: Container-level privilege escalation (`full_access: true`)
- **Key insight**: apctest worked (read-only) but daemon failed (needed write access)

## [2.0.6] - 2025-01-07

### Added Auto-Discovery Integration
- **Automatic Home Assistant Integration**: Sets up native APC UPS Daemon integration automatically
- **Dynamic Hostname Detection**: Discovers correct add-on hostname with repository hash
- **Seamless Setup**: No manual integration configuration required
- **UPS Power Control Services**: Added remote power management commands
  - Graceful shutdown with auto-restart, load control, reboot, emergency kill
  - Safety validation and comprehensive logging

## [2.0.2] - 2025-01-07

### Enhanced Configuration UI
- **Improved User Experience**: Clear visual indicators for required vs optional fields
- **Better Field Organization**: Logical grouping with helpful descriptions and examples
- **Enhanced Translations**: Comprehensive help text for each configuration option
- **Refined Defaults**: Optimized battery level (10%) and timeout (5 minutes) settings

## [2.0.0] - 2025-06-06

### Modernized and Integrated
- **SECURITY**: Complete security overhaul with comprehensive input validation
- **SECURITY**: Sanitized all configuration value injections to prevent command injection
- **SECURITY**: Added validation for UPS names, cable types, device paths, and configuration keys
- **SECURITY**: Limited extra configuration options to 50 items with size constraints
- **SECURITY**: File size limits for scripts (64KB) and config files (4KB email config, 1KB aliases)
- **SECURITY**: Proper file permissions and access controls

### Updated
- Modernized Dockerfile with latest Alpine base images and security best practices
- Updated Home Assistant API integration to use modern Supervisor API endpoints
- Converted configuration from JSON to YAML format with build.yaml support
- Enhanced logging with bashio integration for better Home Assistant compatibility
- Updated documentation with comprehensive configuration examples and troubleshooting

### Added
- Input validation for all apcupsd configuration parameters
- Better error handling and user feedback
- Support for all 22 apcupsd event types with documentation
- Modern Home Assistant integration examples
- Comprehensive DOCS.md with advanced configuration scenarios
- Migration guide from original add-on

### Fixed
- Updated API authentication to use SUPERVISOR_TOKEN instead of legacy headers
- Improved error handling for Host control operations
- Better script validation and security checks

## FORK - Integrated into cabinlab/hassio-addons

## [1.9] - 2019-06-02
### Updated
- Updated base image to latest version (based on Alpine 3.10)
- Updated apcupsd to 3.14.14-r1

## [1.8] - 2019-03-09
### Added
- Added new armv7 Docker Hub build

### Updated
- Updated base image to latest version (based on Alpine 3.9)

## [1.7] - 2018-11-24
### Fixed
- Update add-on to support newer Hass.io API authentication

## [1.6] - 2018-11-23
### Added
- Added apcupsd_net add-on for network UPSs

### Fixed
- Fixed not allowing network-only UPSs (Issue #7)

### Updated
- Updated add-on base image and apcupsd to latest version

## [1.5] - 2018-06-15
### Fixed
- Fixed adding all `/dev/usb` devices (Issue #5)

## [1.4] - 2018-01-22
### Fixed
- Fixed bug not setting DEVICE properly

## [1.3] - 2017-12-21
### Added
- Added Hass.io API based reboot and poweroff commands
- Added ability to customize apcupsd scripts
- Added curl, openssh, and mail commands to image for scripts

### Removed
- `mail` mock

## [1.2] - 2017-12-20
### Added
- Added syslog logging to the add-on log

## [1.1] - 2017-12-20
### Added
- Added mock `mail` command to prevent log messages

## [1.0] - 2017-12-08
### Added
- Initial Project

[1.9]: https://github.com/korylprince/hassio-apcupsd/compare/1.8...1.9
[1.8]: https://github.com/korylprince/hassio-apcupsd/compare/1.7...1.8
[1.7]: https://github.com/korylprince/hassio-apcupsd/compare/1.6...1.7
[1.6]: https://github.com/korylprince/hassio-apcupsd/compare/1.5...1.6
[1.5]: https://github.com/korylprince/hassio-apcupsd/compare/1.4...1.5
[1.4]: https://github.com/korylprince/hassio-apcupsd/compare/1.3...1.4
[1.3]: https://github.com/korylprince/hassio-apcupsd/compare/1.2...1.3
[1.2]: https://github.com/korylprince/hassio-apcupsd/compare/1.1...1.2
[1.1]: https://github.com/korylprince/hassio-apcupsd/compare/1.0...1.1
