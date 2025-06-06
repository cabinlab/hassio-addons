# Claude Home for Home Assistant

An AI-powered web-based terminal with Claude Code CLI pre-installed for Home Assistant.

![Claude Home Screenshot](https://github.com/heytcass/home-assistant-addons/raw/main/claude-terminal/screenshot.png)

*Claude Home running in Home Assistant*

## What is Claude Home?

This add-on provides an AI-powered web-based terminal interface with Claude Code CLI pre-installed, allowing you to use Claude's powerful AI capabilities directly from your Home Assistant dashboard. It gives you direct access to Anthropic's Claude AI assistant through a terminal, ideal for:

- Writing and editing code
- Debugging problems
- Learning new programming concepts
- Creating Home Assistant scripts and automations

## Features

- **Web Terminal Interface**: Access Claude through a browser-based terminal
- **Auto-Launch**: Claude starts automatically when you open the terminal
- **Latest Claude Code CLI**: Pre-installed with Anthropic's official CLI
- **No Configuration Needed**: Uses OAuth authentication for easy setup
- **Direct Config Access**: Terminal starts in your `/config` directory for immediate access to all Home Assistant files
- **Home Assistant Integration**: Access directly from your dashboard
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

Claude Home provides comprehensive configuration options through the Home Assistant add-on interface. Configuration is automatically converted to Claude's native settings.json format for optimal performance and compatibility:

### Available Configuration Options

| Setting | Description | Default | Options |
|---------|-------------|---------|---------|
| **Claude Model** | AI model to use for conversations | `claude-3-5-sonnet-20241022` | Sonnet, Haiku, Opus variants |
| **Theme** | Terminal color scheme | `dark` | dark, light, light-daltonized, dark-daltonized |
| **Verbose Logging** | Show detailed Claude operation logs | `false` | true/false |
| **Max Turns** | Limit conversation turns to prevent runaway | `10` | 1-50 |
| **Disable Telemetry** | Turn off Claude usage analytics | `false` | true/false |
| **Terminal Bell** | Audio feedback on completion | `true` | true/false |
| **HA Notifications** | Send completion notices to HA | `false` | true/false |
| **Notification Service** | Which HA service to use for notifications | `persistent_notification` | Any HA notify service |
| **Context Integration** | Enable HA entity access from Claude | `true` | true/false |
| **Context Domains** | Entity domains Claude can access | `climate,sensor,binary_sensor,light,switch,weather` | Comma-separated list |
| **Context Max Entities** | Maximum entities to display | `100` | 10-500 |

### Claude Model Options

- **Claude 3.5 Sonnet** (default) - Most capable, best for complex tasks
- **Claude 3.5 Haiku** - Fastest, good for simple tasks  
- **Claude 3 Opus** - Previous generation, very capable
- **Claude 3 Sonnet** - Balanced performance
- **Claude 3 Haiku** - Previous generation, fast

### Theme Options

- **dark** - Standard dark theme
- **light** - Standard light theme
- **light-daltonized** - Light theme optimized for color vision differences
- **dark-daltonized** - Dark theme optimized for color vision differences

### Home Assistant Context Integration

- **Context Integration**: When enabled, Claude has access to your Home Assistant entities and can help with automation tasks
- **Context Domains**: Control which entity types Claude can see (e.g., climate, sensor, light, switch)
- **Context Max Entities**: Limit the number of entities displayed to prevent information overload

**Available Context Commands:**
```bash
ha entities [domain]     # List HA entities (optionally by domain)
ha state <entity_id>     # Get specific entity state and attributes  
ha summary              # Show system overview with entity counts
ha help                 # Show all available commands
```

**Example Usage:**
```bash
# List all climate entities
ha entities climate

# Get detailed state of a sensor
ha state sensor.living_room_temperature

# See system overview
ha summary
```

### Privacy & Performance Settings

- **Disable Telemetry**: Prevents Claude from sending usage analytics to Anthropic
- **Max Turns**: Safety limit to prevent infinite conversation loops
- **Verbose Logging**: Shows detailed turn-by-turn output for debugging

### How to Configure

1. Go to **Settings** → **Add-ons** → **Claude Home**
2. Click the **Configuration** tab
3. Adjust your preferred settings
4. Click **Save** and restart the add-on

Configuration changes take effect after restarting the add-on. Settings are automatically converted to Claude's native settings.json format for optimal integration with Claude Code CLI.

## Documentation

For detailed usage instructions, see the [documentation](DOCS.md).

## Useful Links

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Get an Anthropic API Key](https://console.anthropic.com/)
- [Claude Code GitHub Repository](https://github.com/anthropics/claude-code)
- [Home Assistant Add-ons](https://www.home-assistant.io/addons/)

## Credits

Originally forked from: https://github.com/heytcass/home-assistant-addons