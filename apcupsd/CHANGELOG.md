# Changelog
All notable changes to this project will be documented in this file.

## [2.0.19] - 2025-01-08

### 🔧 PERMISSIONS FIX: Device Access Rights
- **Device Permissions Fix**: Automatically fix hiddev device permissions before daemon startup
- **Root Cause Resolution**: Address device permission issues that prevent daemon communication
- **Comprehensive Fix**: Fix permissions for both specific devices and all hiddev devices
- **Enhanced Logging**: Show device permissions before and after fix attempts
- **Targeted Solution**: Based on analysis showing consistent permission issues in logs

### Technical Details
- Change device permissions from 600 (crw-------) to 666 (crw-rw-rw-)
- Ensure proper ownership (root:root) for all hiddev devices
- Fix permissions for specific DEVICE setting and all /dev/usb/hiddev* devices
- This addresses the consistent "Device permissions issue" warnings in logs

**This should resolve the core permissions barrier preventing daemon UPS communication!**

## [2.0.18] - 2025-01-08

### 🔧 TARGETED FIX: apctest vs Daemon Device Discovery Gap
- **Bridge apctest/daemon gap**: When apctest succeeds with blank device but daemon fails
- **Device Discovery**: Extract actual device path that apctest uses successfully  
- **Hybrid Approach**: Use apctest success to configure daemon with specific device
- **Verbose Device Detection**: Enhanced logging to show which device apctest discovers
- **Fallback Logic**: Default to /dev/usb/hiddev0 if device extraction fails

### Problem Analysis
- apctest consistently works with blank device configuration
- apcupsd daemon fails with same blank device configuration  
- Root cause: Different device access methods between apctest and daemon
- Solution: Use apctest to discover working device, then configure daemon specifically

This addresses the specific scenario where auto-detection works for testing but not for the running daemon.

## [2.0.17] - 2025-01-08

### 🔧 CRITICAL FIX: USB Device Configuration
- **Blank Device Setting**: Implement apcupsd best practice of leaving DEVICE blank for USB connections
- **Auto-Detection Priority**: For USB and apcsmart+USB, try blank device first before specific paths  
- **Follows Documentation**: Aligns with official apcupsd guidance that USB devices should auto-detect
- **Permissions Fix**: Resolves device permission issues by letting apcupsd handle USB detection
- **Research-Based Solution**: Implements fix discovered from apcupsd community troubleshooting

### Technical Changes
- USB type: Always use blank DEVICE setting for auto-detection
- apcsmart+USB: Try blank device first, fallback to specific paths if needed
- Improved logging to show when using auto-detection vs specific device paths
- Based on extensive research showing COMMLOST issues caused by explicit device paths

**This should resolve the persistent COMMLOST communication issues!**

## [2.0.16] - 2025-01-08

### Enhanced Debugging
- **Daemon Initialization Monitoring**: Added detailed monitoring of apcupsd daemon startup process
- **Configuration Verification**: Final configuration check before daemon startup with device permissions
- **Debug Mode Startup**: Start apcupsd with debug level 10 for enhanced logging
- **Immediate Status Testing**: Test UPS communication immediately after daemon startup
- **Process Monitoring**: Track daemon PID and verify it stays running during initialization
- **Enhanced Error Detection**: Better detection of daemon startup failures and crashes

### Technical Improvements
- Added pre-startup device permission verification and logging
- Enhanced daemon startup sequence with debug mode and process monitoring
- Immediate post-startup communication testing to identify timing issues
- Better error detection for daemon initialization failures

## [2.0.15] - 2025-01-08

### Enhanced
- **Advanced Communication Testing**: Enhanced device testing to verify actual UPS communication before startup
- **Smart Cable Auto-Detection**: Automatically tests smart cable configuration if standard methods fail
- **Real UPS Response Validation**: Uses apctest with actual query commands to verify device compatibility
- **Intelligent Configuration Switching**: Automatically suggests and tests smart cable configuration
- **Enhanced Debugging Output**: Shows actual UPS response data during device testing

### Technical Improvements
- Replaced basic apctest existence check with actual UPS communication testing
- Added smart cable configuration fallback for devices that need specific cable settings
- Enhanced device testing with UPS response validation and detailed logging
- Improved configuration recommendations based on actual device response testing

## [2.0.14] - 2025-01-08

### Enhanced
- **Proactive Device Testing**: Enhanced auto-detection logic to test both hiddev0 and hiddev1 during initial setup
- **Smart Device Selection**: For apcsmart protocol, test device compatibility using apctest before daemon startup
- **Improved Fallback Logic**: Better device preference handling with accessibility testing
- **Enhanced Debugging**: More detailed logging for device selection and compatibility testing
- **Reduced COMMLOST Issues**: Proactive device testing reduces communication failures

### Technical Improvements
- Replaced simple device existence check with actual compatibility testing
- Added apctest integration for device validation before daemon startup
- Enhanced device auto-detection with preference-based testing
- Improved error handling and fallback mechanisms for device selection

## [2.0.8] - 2025-01-07

### Fixed
- **Dynamic hostname detection**: Auto-discover the correct full add-on slug (e.g., "12862deb-apcupsd")
- Query Supervisor API to get the actual add-on hostname with repository hash
- Update both API config flow and configuration.yaml methods to use detected hostname
- Improve error messages to show the correct hostname for manual setup
- Documentation updated with example of full hostname format

## [2.0.7] - 2025-01-07

### Fixed
- Fix auto-discovery to use correct hostname "apcupsd" instead of "localhost"
- Prioritize configuration.yaml method over API config flow (more reliable)
- Update documentation to clarify manual integration setup with correct hostname
- Improve auto-discovery notifications and error handling

## [2.0.6] - 2025-01-07

### Added
- **Auto-Discovery Integration**: Automatically sets up Home Assistant's native APC UPS Daemon integration
  - Auto-configures integration via Supervisor API with host: "apcupsd", port: 3551
  - Falls back to configuration.yaml method if API unavailable
  - Sends notification when integration is configured
  - New `auto_discovery` configuration option (default: enabled)
- Integration health monitoring and conflict detection
- Wait for Home Assistant readiness before attempting discovery

### Enhanced
- Seamless integration with Home Assistant's built-in apcupsd sensors
- No manual integration setup required - works out of the box
- Comprehensive logging for auto-discovery process

## [2.0.5] - 2025-01-07

### Fixed
- Remove invalid `services:` section from config.yaml that prevented add-on from appearing in store
- Add-on should now be visible and installable again

## [2.0.4] - 2025-01-07

### Added (Experimental)
- **UPS Power Control Services**: Remote power management via Home Assistant (testing)
  - `ups_shutdown_return` - Graceful shutdown with auto-restart on power return
  - `ups_load_off` - Cut power to outlets with configurable delay
  - `ups_load_on` - Restore power to outlets with configurable delay  
  - `ups_reboot` - Power cycle UPS with configurable off/on delays
  - `ups_emergency_kill` - Immediate emergency power cut
- Power control script with safety validation and logging
- Service parameter validation (0-7200 second delays)
- Comprehensive documentation with automation examples

### Enhanced
- Service monitoring loop for Home Assistant API integration
- Improved logging with power control operation tracking
- Safety warnings for destructive power operations

## [2.0.3] - 2025-01-07

### Enhanced
- Moved UPS Display Name back to the top of configuration fields
- Added clear visual indicators for required vs optional fields:
  - Required fields marked with 🔴 emoji and [REQUIRED] tag
  - Optional fields marked with [OPTIONAL] tag
- Improved field labeling for better clarity at a glance
- Created alternative translation without emojis for compatibility

## [2.0.2] - 2025-01-07

### Enhanced
- Improved configuration UI with clearer field organization
- Added "Required" and "Optional" labels to field descriptions for better UX
- Reorganized fields to show required settings (cable, type) first
- Updated field names to be more concise and user-friendly
- Enhanced help text with practical examples and recommendations
- Made cable and type fields properly required (removed optional ? suffix)
- Improved default values: battery_level 5% → 10%, timeout_minutes 3 → 5

## [2.0.1] - 2025-06-06

### Fixed
- Add apk update before package installation to resolve installation failures
- Fix apcupsd script placement - copy to /etc/apcupsd/ instead of overwriting system binaries
- Ensure package repository index is current before installing apcupsd

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
