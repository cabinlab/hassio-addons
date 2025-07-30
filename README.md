# Cabin Assistant add-ons

![Discord](https://img.shields.io/discord/895569767757393941?style=flat&logo=discord&logoColor=white&label=discord&link=https%3A%2F%2Fdiscord.gg%2FaaSgZBgkCK)

This repository contains custom Home Assistant add-ons that extend your system's functionality.

## Installation

[![Open your Home Assistant instance and show the add add-on repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

**Manual Installation:**
1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu in the top right corner
3. Select **Repositories**
4. Add the URL: `https://github.com/cabinlab/hassio-addons`
5. Click **Add**

## Add-ons

### Claude Home

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=claude_home&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

An AI-powered web-based terminal interface with Claude Code CLI pre-installed. This add-on provides a terminal environment directly in your Home Assistant dashboard, allowing you to use Claude's powerful AI capabilities for coding, automation, and configuration tasks.

Features:
- Web terminal access through your Home Assistant UI
- Pre-installed Claude Code CLI that launches automatically
- Direct access to your Home Assistant config directory
- No configuration needed (uses OAuth)
- Access to Claude's complete capabilities including:
  - Code generation and explanation
  - Debugging assistance
  - Home Assistant automation help
  - Learning resources

[Documentation](claude-home/DOCS.md)

### Access Point

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=hassio-access-point&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

Turn your Home Assistant device into a Wi-Fi access point, allowing other devices to connect and providing internet access through your device's connection.

Features:
- Create a Wi-Fi hotspot from your Home Assistant device
- Configure SSID and password
- DHCP server functionality
- DNS forwarding
- Configurable network settings

[Documentation](hassio-access-point/README.md)

### APC UPS Daemon

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=apcupsd&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

Monitor and manage APC UPS devices with native apcupsd integration. This modernized add-on provides comprehensive UPS monitoring with advanced event handling and host control capabilities.

Features:
- Native apcupsd integration optimized for APC devices
- 22 UPS event types with custom script support
- Safe host shutdown/reboot through Home Assistant API
- Email notifications via msmtp
- USB and network UPS support
- Comprehensive input validation and security
- Modern Home Assistant integration

[Documentation](apcupsd/README.md)

### Claude Watchdog

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=claude_watchdog&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

Intelligent continuous monitoring for Home Assistant using Claude AI. Runs in the background analyzing state changes and providing proactive insights, security monitoring, and optimization recommendations.

Features:
- Continuous AI-powered analysis with Claude 3.5 Haiku
- Proactive insights and anomaly detection
- Multi-domain monitoring (climate, security, energy, automation)
- Cost-controlled with daily limits (~$0.36/day)
- Smart notifications and learning patterns
- Energy optimization and predictive maintenance

[Documentation](claude-watchdog/README.md)

## Support

These addons are currently experimental and unsupported. You can join the discussions with questions or suggestions.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
