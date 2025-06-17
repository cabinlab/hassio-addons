# Model Selection Bug Analysis

## Investigation Summary (Opus Analysis)

### Current Implementation
1. **Configuration**: Default model is correctly set to `claude-3-5-haiku-20241022` in config.yaml
2. **Environment Variable**: `ANTHROPIC_MODEL` is properly set from the config value
3. **Settings.json**: Model is correctly written to `/config/claude-config/settings.json`

### Key Findings

#### 1. Settings.json Creation
The settings.json file is created with the correct structure:
```json
{
  "env": {
    "ANTHROPIC_MODEL": "claude-3-5-haiku-20241022"
  },
  "theme": "dark",
  ...
}
```

#### 2. Environment Variable Setting
- The run.sh script sets `export ANTHROPIC_MODEL="$claude_model_config"`
- This happens BEFORE settings.json is created
- Both mechanisms should work to set the model

#### 3. Critical Issue: Claude CLI Invocation
- **NO MODEL PARAMETER**: The claude CLI is never invoked with a `--model` parameter
- When users run `claude` in the terminal, it relies on:
  1. Environment variable `ANTHROPIC_MODEL`
  2. Settings in settings.json
  3. Claude's internal defaults

### ROOT CAUSE FOUND: Why Opus is Being Used

1. **WRONG LOCATION**: We're creating settings.json at `/config/claude-config/settings.json` but Claude expects it at `~/.claude/settings.json`

2. **Environment Variable Not Persisted**: The `ANTHROPIC_MODEL` env var is set in run.sh but might not persist to the ttyd terminal session

3. **Claude CLI Default Behavior**: When neither correct settings location nor env var are found, Claude defaults to its most capable model (Opus)

### Solution Required
1. Create settings.json at `~/.claude/settings.json` (which is `/root/.claude/settings.json`)
2. Ensure ANTHROPIC_MODEL env var persists to terminal session
3. As fallback, use `--model` parameter when invoking claude
4. Fix the settings.json structure to match Claude's expectations

## Cost Impact
- User expects: Haiku ($0.25 per MTok)
- User gets: Opus ($15 per MTok)
- **60x cost difference!**