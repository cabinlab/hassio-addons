# Home Assistant Add-ons

This repository contains custom Home Assistant add-ons that extend your system's functionality.

## Installation

To add this repository to your Home Assistant instance:

1. Go to **Settings** → **Add-ons** → **Add-on Store**
2. Click the three dots menu in the top right corner
3. Select **Repositories**
4. Add the URL: `https://github.com/heytcass/home-assistant-addons`
5. Click **Add**

## Add-ons

### Claude Terminal

A web-based terminal interface with Claude Code CLI pre-installed. This add-on provides a terminal environment directly in your Home Assistant dashboard, allowing you to use Claude's powerful AI capabilities for coding, automation, and configuration tasks.

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

[Documentation](claude-terminal/DOCS.md)

### Access Point

Turn your Home Assistant device into a Wi-Fi access point, allowing other devices to connect and providing internet access through your device's connection.

Features:
- Create a Wi-Fi hotspot from your Home Assistant device
- Configure SSID and password
- DHCP server functionality
- DNS forwarding
- Configurable network settings

[Documentation](hassio-access-point/README.md)

## Support

If you have any questions or issues with these add-ons, please create an issue in this repository.

## Credits

This add-on was created with the assistance of Claude Code itself! The development process, debugging, and documentation were all completed using Claude's AI capabilities.

## License

This repository is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
