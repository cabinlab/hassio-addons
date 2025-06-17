# Claude Home Authentication Guide

## Understanding Claude's OAuth Authentication

Claude Code uses OAuth 2.0 authentication to securely connect to Anthropic's services. This provides better security than API keys but has specific limitations in containerized environments.

## Why Re-authentication is Required

### The OAuth Session Problem

When you authenticate with Claude, several things happen:
1. **Access Token**: Granted for making API calls
2. **Refresh Token**: Used to get new access tokens
3. **Internal Session State**: Maintained by Claude Code process

**The Issue**: When the add-on restarts (container restart), the Claude Code process ends and all internal session state is lost. While the tokens are saved to disk, Claude Code cannot restore its internal session from these files alone.

### What Happens During Container Restart

✅ **Preserved**:
- Your saved tokens in `/config/claude-config/.claude/`
- Your conversation history and settings
- Your Claude model preferences
- Your working directory and files

❌ **Lost**:
- Claude Code's internal session state
- Active OAuth session context
- Running process memory

## Authentication Flow

### First-Time Setup

1. **Open Claude Home** via Home Assistant web UI
2. **Run Claude** by typing `claude` in the terminal
3. **Browser Opens** for OAuth authentication
4. **Log in** to your Anthropic account
5. **Grant Permission** to Claude Code
6. **Return to Terminal** - Claude is now authenticated

### After Add-on Restart

1. **Open Claude Home** - you'll see "Authentication needed" message
2. **Run Claude** by typing `claude` 
3. **Follow OAuth prompts** (same as first-time setup)
4. **Complete authentication** - your previous settings and conversations return

## Step-by-Step Re-authentication

### When You See "Authentication needed"

```bash
# In the Claude Home terminal:
claude
```

### The OAuth Process

1. **Claude opens browser tab** automatically
2. **If already logged in to Anthropic**: Click "Authorize"
3. **If not logged in**: 
   - Enter your email/password
   - Complete any 2FA if enabled
   - Click "Authorize"
4. **Return to terminal** - Claude starts automatically

### If Browser Doesn't Open

```bash
# Claude will show a URL like:
# Go to: https://auth.anthropic.com/oauth/authorize?...

# Copy the URL and open it manually in your browser
```

## Troubleshooting Authentication

### Common Issues

**"Browser won't open"**
- Copy the URL from terminal and paste in browser manually
- Ensure pop-up blocker isn't preventing the browser tab

**"Already authorized but still asked to authenticate"**
- This is normal - container restart requires re-authorization
- Complete the OAuth flow as usual

**"Invalid credentials" or "Unauthorized"**
- Your Anthropic account may not have Claude Code access
- Check your Anthropic account status
- Try logging out and back in to Anthropic

**"Command not found: claude"**
- Ensure you're using the Claude Home web terminal
- Don't use SSH or other terminal access methods

### Checking Authentication Status

```bash
# Check if Claude is authenticated
claude --help

# If authenticated: Shows Claude help
# If not authenticated: Prompts for OAuth
```

### Advanced Debugging

```bash
# Check stored authentication files
ls -la /config/claude-config/.claude/

# Check for credentials file
cat /config/claude-config/.claude/.credentials.json

# View authentication debug info
check-auth
```

## What's Preserved Across Restarts

### ✅ Your Data Remains Safe

- **Conversation History**: All your Claude conversations
- **Model Settings**: Your preferred Claude model
- **Working Directory**: Files and projects in your workspace
- **MCP Configurations**: Home Assistant integrations
- **Add-on Settings**: All Home Assistant configuration

### ⚠️ Authentication Session is Reset

- **OAuth Session**: Must be re-established
- **Active Connections**: MCP servers need reconnection
- **Running Processes**: Any background tasks stop

## Best Practices

### Minimize Re-authentication

- **Avoid Unnecessary Restarts**: Only restart when needed
- **Use Auto-start**: Enable "Auto Claude" in configuration
- **Stay Logged In**: Keep your Anthropic account session active

### Smooth Re-authentication

- **Keep Browser Open**: Makes OAuth flow faster
- **Save Bookmarks**: Bookmark Anthropic login page
- **Use Password Manager**: For quick Anthropic login

## Security Notes

- **OAuth is Secure**: More secure than API keys
- **Tokens are Encrypted**: Stored securely in persistent storage
- **No Passwords Stored**: Only OAuth tokens are saved
- **Automatic Expiry**: Tokens expire and refresh automatically

## Getting Help

If authentication continues to fail:

1. **Check Add-on Logs**: Look for error messages in Home Assistant
2. **Verify Account**: Ensure your Anthropic account has Claude Code access
3. **Try Different Browser**: Sometimes browser issues affect OAuth
4. **Restart Add-on**: Fresh start can resolve stuck authentication

For more help, see [DOCS.md](DOCS.md) or check the add-on logs in Home Assistant.