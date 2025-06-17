# CRITICAL MODEL FIX READY

## Root Cause (Found by Terminal 3)
Claude was looking for settings.json at `~/.claude/settings.json` but we were creating it at `/config/claude-config/settings.json`

## Solution Implemented
The terminal-init.sh script now:
1. Creates settings.json in the CORRECT location (`~/.claude/settings.json`)
2. Exports ANTHROPIC_MODEL environment variable
3. Ensures it persists across the session

## Integration Required
Update the main addon's run.sh to use the new terminal-init.sh script when launching ttyd.

## This Fixes the 60x Cost Issue!
- User will get Haiku as configured
- Not Opus by accident
- Immediate cost savings