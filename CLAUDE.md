# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a Home Assistant add-ons repository containing multiple add-ons that follow the Home Assistant add-on specification. Each add-on is a self-contained directory with required files:

- `config.yaml` or `config.json` - Add-on metadata and configuration schema
- `Dockerfile` - Container build instructions
- `run.sh` - Main entry point script
- Documentation files (README.md, DOCS.md)

### Add-ons Structure

**Claude Terminal** (`claude-terminal/`): Web-based terminal with Claude Code CLI pre-installed
- Uses ingress for Home Assistant UI integration (port 7681)
- Maps `/config` and `/addons` directories for development access
- OAuth authentication with credentials stored in `/config/claude-config`
- Auto-launches Claude CLI on terminal startup

**Access Point** (`hassio-access-point/`): WiFi hotspot functionality
- Requires host networking and NET_ADMIN privileges
- Uses hostapd for AP management and dnsmasq for DHCP/DNS
- Extensive configuration options for network settings

## Build Commands

- Build add-on: `docker build -t local/claude-terminal ./claude-terminal`
- Run add-on locally: `docker run -p 7681:7681 -v $(pwd)/config:/config local/claude-terminal`
- Validate add-on: `docker run --rm -v $(pwd):/data homeassistant/amd64-builder --validate`
- Lint Dockerfile: `hadolint ./claude-terminal/Dockerfile`

## Test Commands

- Basic functionality test: `curl -X GET http://localhost:7681/`
- Web terminal test: Open browser to `http://localhost:7681/` to verify web terminal loads

## Code Style Guidelines

- **Indentation**: 2 spaces for YAML, 4 spaces for shell scripts
- **Naming**: Use snake_case for variables, functions, and file names
- **Docker**: Include comments for complex RUN commands and use single RUN statements for package installation
- **Shell Scripts**: Use `#!/usr/bin/with-contenv bashio` for add-on scripts
- **Error Handling**: Use bashio::log.error for error reporting in scripts
- **YAML**: Keep configuration files well-documented with comments
- **Add-on Structure**: Follow Home Assistant add-on specification with all required files

## Home Assistant Add-on Conventions

- Add-on slugs use underscores (e.g., `claude_terminal`)
- Version format: semantic versioning (major.minor.patch)
- Support multiple architectures: aarch64, amd64, armhf, armv7, i386
- Use Home Assistant base images via BUILD_FROM arg
- Map only necessary directories and use appropriate permissions (rw/ro)