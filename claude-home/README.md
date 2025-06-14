# Claude Home for Home Assistant

An AI-powered web-based terminal with Claude Code CLI pre-installed for Home Assistant.

![Claude Home Screenshot](screenshot.png)

*Claude Home running in Home Assistant*

## What is Claude Home?

This add-on provides an AI-powered web-based terminal interface with Claude Code CLI pre-installed, allowing you to use Claude's powerful AI capabilities directly from your Home Assistant dashboard. It gives you direct access to Anthropic's Claude AI assistant through a terminal, ideal for:

- Writing and editing code
- Debugging problems
- Learning new programming concepts
- Creating Home Assistant scripts and automations

## Features

- **Web Terminal Interface**: Access Claude through a browser-based terminal
- **Auto-Launch Option**: Claude can start automatically when you open the terminal
- **Latest Claude Code CLI**: Pre-installed with Anthropic's official CLI
- **OAuth Authentication**: Simple setup with persistent credentials
- **Flexible Working Directory**: Choose where Claude starts (/config, /root, etc.)
- **MCP Integration**: Home Assistant integration via MCP servers
- **Panel Icon**: Quick access from the sidebar with the code-braces icon

## Quick Start

The terminal automatically starts Claude when you open it. You can immediately start using commands like:

```bash
# Ask Claude a question directly
claude "How can I write a Python script to control my lights?"

# Start an interactive session
claude -i

# Get help with available commands
claude --help
```

## Installation

### Quick Install
[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=claude_home&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

### Manual Installation
1. Add this repository to your Home Assistant add-on store:

   [![Open your Home Assistant instance and show the add add-on repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

2. Install the Claude Home add-on
3. Start the add-on
4. Click "OPEN WEB UI" or the sidebar icon to access
5. On first use, follow the OAuth prompts to log in to your Anthropic account

## Configuration

Claude Home provides several configuration options through the Home Assistant add-on interface:

### Available Configuration Options

| Setting | Description | Default | Options |
|---------|-------------|---------|---------|
| **Claude Model** | AI model to use | `haiku` | haiku, sonnet, opus |
| **Theme** | Terminal color scheme | `dark` | dark, light, system, high-contrast, auto |
| **Auto Claude** | Start Claude automatically | `false` | true/false |
| **Verbose Logging** | Show detailed operation logs | `false` | true/false |
| **Disable Telemetry** | Turn off usage analytics | `false` | true/false |
| **Terminal Bell** | Audio feedback on completion | `true` | true/false |
| **HA Notifications** | Send completion notices to HA | `false` | true/false |
| **Notification Service** | Which HA service to use | `persistent_notification` | Various notify services |
| **Working Directory** | Where Claude starts | `/config` | /config, /config/claude-workspace, /root, /config/custom_components |
| **HA URL** | Custom Home Assistant URL | `` | Optional for MCP |
| **HA Token** | Custom Home Assistant token | `` | Optional for MCP |

### Claude Model Options

- **haiku** - Claude 3.5 Haiku, fastest and most cost-effective
- **sonnet** - Claude Sonnet 4, most capable for complex tasks
- **opus** - Claude 3 Opus, balanced performance

### Working Directory Options

- **/config** (default) - Start in your Home Assistant config directory
- **/config/claude-workspace** - Dedicated workspace for Claude projects
- **/root** - Start in the container root directory
- **/config/custom_components** - Start in your custom components directory

### MCP Integration

Claude Home includes MCP (Model Context Protocol) servers for Home Assistant integration:
- **hass-mcp**: Provides access to Home Assistant entities and services
- **context7**: Documentation and context server

Use the `/mcp` command in Claude to connect to these servers.

### Authentication Notes

⚠️ **Important**: Claude uses OAuth authentication that cannot persist across container restarts. You'll need to re-authenticate each time the add-on restarts. This is a limitation of Claude Code itself, not the add-on.

### How to Configure

1. Go to **Settings** → **Add-ons** → **Claude Home**
2. Click the **Configuration** tab
3. Adjust your preferred settings
4. Click **Save** and restart the add-on

Configuration changes take effect after restarting the add-on.

## Documentation

For detailed usage instructions, see the [documentation](DOCS.md).

## Useful Links

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Get an Anthropic API Key](https://console.anthropic.com/)
- [Claude Code GitHub Repository](https://github.com/anthropics/claude-code)
- [Home Assistant Add-ons](https://www.home-assistant.io/addons/)

## Credits

Originally forked from: https://github.com/heytcass/home-assistant-addons