# Bug Fixes Summary

## Critical Model Selection Bug (5x Cost Issue) - FIXED

### What was wrong:
- Settings.json was created at `/config/claude-config/settings.json` but Claude CLI expects it at `~/.claude/settings.json`
- Environment variable `ANTHROPIC_MODEL` was set in run.sh but not persisted to ttyd terminal session
- Without proper model config, Claude defaulted to Opus (most expensive) instead of Haiku

### Why previous fixes failed:
- They focused on setting the environment variable but didn't realize the settings.json location was wrong
- The environment variable wasn't being exported to the terminal session
- No explicit `--model` parameter was used when launching Claude

### How I fixed it:
1. **Created settings.json in correct location**: Now creates at `/root/.claude/settings.json` (Claude's expected location)
2. **Persist ANTHROPIC_MODEL to terminal**: Added export in terminal functions script
3. **Use explicit --model parameter**: When auto-starting Claude, now uses `claude --model "$ANTHROPIC_MODEL"`
4. **Display model info**: Shows current model in terminal header for transparency

### Test results:
- Settings.json now created at both locations for compatibility
- Model environment variable properly exported to terminal session
- Auto-start command includes explicit model parameter
- User can verify model selection in terminal output

## Authentication Detection Bug - FIXED

### What was wrong:
- Simple timeout test was unreliable
- Didn't check the actual auth file location (`~/.config/claude/auth.json`)
- No distinction between "missing" vs "invalid" credentials
- Update prompts during auth check caused timeouts

### Why previous fixes failed:
- Didn't know where Claude CLI actually stores auth
- Used too short timeout (3 seconds)
- Didn't use `--no-update-check` flag

### How I fixed it:
1. **Check correct auth location**: Primary check for `/root/.config/claude/auth.json`
2. **Multiple fallback locations**: Still checks legacy locations for compatibility
3. **Better status reporting**: Distinguishes between missing/invalid/authenticated
4. **Avoid update prompts**: Uses `--no-update-check` flag during auth test
5. **Longer timeout**: Increased to 5 seconds for reliability

## BusyBox env -S Issue - FIXED

### What was wrong:
- Claude CLI uses `#!/usr/bin/env -S node` shebang
- BusyBox doesn't support `-S` flag
- This prevented `claude auth` from working

### How I fixed it:
1. **Created wrapper script**: `/usr/local/bin/hiclaude` that executes claude.js with node directly
2. **Dynamic path detection**: Searches for claude.js in npx cache locations
3. **Symlinked as claude**: `ln -s hiclaude claude` for transparent usage
4. **Model injection**: Wrapper also ensures ANTHROPIC_MODEL is set

## Remaining Issues to Address

1. **Terminal UI centering**: ASCII art needs proper centering
2. **Color codes**: Ensure ANSI codes work properly in ttyd
3. **Core scripts**: Need to complete modular scripts for new architecture

## Version Recommendation
Bump to v1.4.14 with these critical fixes