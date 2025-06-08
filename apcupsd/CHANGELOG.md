# Changelog
All notable changes to this project will be documented in this file.

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
