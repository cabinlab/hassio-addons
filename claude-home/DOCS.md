# Claude Terminal

A terminal interface for Anthropic's Claude Code CLI in Home Assistant.

## About

This add-on provides a web-based terminal with Claude Code CLI pre-installed, allowing you to access Claude's powerful AI capabilities directly from your Home Assistant dashboard. The terminal provides full access to Claude's code generation, explanation, and problem-solving capabilities.

## Installation

1. Add this repository to your Home Assistant add-on store
2. Install the Claude Terminal add-on
3. Start the add-on
4. Click "OPEN WEB UI" to access the terminal
5. On first use, follow the OAuth prompts to log in to your Anthropic account

## Configuration

No configuration is needed! The add-on uses OAuth authentication, so you'll be prompted to log in to your Anthropic account the first time you use it.


For detailed information about authentication, see the [Authentication Guide](AUTHENTICATION.md).

## Usage

Claude can be configured to launch automatically when you open the terminal (set "Auto Claude" to true in configuration). You can also start Claude manually with:

```bash
claude
```

### Common Commands

- `claude` - Start Claude (will prompt for auth if needed)
- `claude --help` - See all available commands
- `claude "your prompt"` - Ask Claude a single question
- `claude code myfile.py` - Have Claude analyze a file
- `/mcp` - Connect to MCP servers for Home Assistant integration

The terminal starts directly in your `/config` directory, giving you immediate access to all your Home Assistant configuration files. This makes it easy to get help with your configuration, create automations, and troubleshoot issues.

## Features

- **Web Terminal**: Access a full terminal environment via your browser
- **Auto-Launching**: Claude starts automatically when you open the terminal
- **Claude AI**: Access Claude's AI capabilities for programming, troubleshooting and more
- **Direct Config Access**: Terminal starts in `/config` for immediate access to all Home Assistant files
- **Simple Setup**: Uses OAuth for easy authentication
- **Home Assistant Integration**: Access directly from your dashboard

## Troubleshooting

### Authentication Issues

**"Claude needs authentication" or login prompts:**
- This is normal after add-on restart due to OAuth session expiry
- Run `claude` and follow the OAuth flow to re-authenticate
- Your previous conversations and settings are preserved

**Claude won't start:**
- Check add-on logs for error messages
- Try restarting the add-on
- Ensure your Anthropic account has API access

**Permission errors:**
- Try restarting the add-on
- Check that Protection Mode is disabled if you need broader file access

**MCP connection issues:**
- Use `/mcp` command in Claude to connect to servers
- Check add-on logs for MCP server status
- Verify Home Assistant API access is enabled

### Common Error Messages

- **"Session expired"**: Re-run `claude` to re-authenticate
- **"API key not found"**: Claude uses OAuth, not API keys - run `claude` to log in
- **"Command not found"**: Make sure you're in the web terminal, not SSH

If problems persist, check the add-on logs in Home Assistant for detailed error information.

## Credits

This add-on was created with the assistance of Claude Code itself! The development process, debugging, and documentation were all completed using Claude's AI capabilities - a perfect demonstration of what this add-on can help you accomplish.