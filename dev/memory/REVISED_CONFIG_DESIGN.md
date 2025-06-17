# Revised Configuration Design (Working Within HA Limitations)

## Acknowledgment

The Opus agent's analysis was excellent, but we need to adapt it to Home Assistant's configuration UI limitations. No conditional fields, no grouping, no dynamic content.

## Simplified Flat Configuration

```yaml
# config.yaml
options:
  # Model Selection
  claude_model: "haiku"
  
  # Context Mode - The KEY setting that changes behavior
  context_mode: "smart"
  
  # Simple Settings
  auto_start: false
  terminal_theme: "dark"
  
  # Custom Context Settings (always visible, note warns they're only for 'custom' mode)
  custom_domains: "all"
  custom_max_entities: 100
  custom_days_limit: 7
  custom_exclude_patterns: ""
  
  # Notification Settings (always visible)
  enable_notifications: false
  notification_service: "persistent_notification"

schema:
  claude_model: "list(haiku|sonnet|opus)"
  context_mode: "list(none|minimal|smart|full|custom)"
  auto_start: "bool?"
  terminal_theme: "list(dark|light|system)"
  custom_domains: "str?"
  custom_max_entities: "int(10,500)?"
  custom_days_limit: "int(1,30)?"
  custom_exclude_patterns: "str?"
  enable_notifications: "bool?"
  notification_service: "str?"
```

## Translations with Clear Guidance

```yaml
# translations/en.yaml
configuration:
  context_mode:
    name: "🏠 Home Assistant Context Mode"
    description: "How Claude accesses your HA data. Choose 'custom' to configure advanced settings below."
    
  custom_domains:
    name: "Custom: Domains [⚠️ ONLY used in 'custom' mode]"
    description: "Comma-separated list (e.g., 'light,switch,sensor') or 'all'"
    
  custom_max_entities:
    name: "Custom: Max Entities [⚠️ ONLY used in 'custom' mode]"
    description: "Maximum number of entities to include (affects token usage)"
```

## Runtime Intelligence

Since we can't make the UI smart, we make the code smart:

```bash
# In run-simple.sh

# Show configuration interpretation
show_config_summary() {
    echo "=== Claude Home Configuration ==="
    echo "Model: $CLAUDE_MODEL"
    echo "Context Mode: $CONTEXT_MODE"
    
    if [ "$CONTEXT_MODE" = "custom" ]; then
        echo "  Custom Domains: $CUSTOM_DOMAINS"
        echo "  Max Entities: $CUSTOM_MAX_ENTITIES"
        echo "  Days Limit: $CUSTOM_DAYS_LIMIT"
    else
        echo "  (Custom settings ignored - using $CONTEXT_MODE preset)"
    fi
    
    if [ "$ENABLE_NOTIFICATIONS" = "true" ]; then
        echo "Notifications: Enabled → $NOTIFICATION_SERVICE"
    else
        echo "Notifications: Disabled"
    fi
    echo "==============================="
}

# Warn about common misconfigurations
check_config_sanity() {
    # Warn if custom fields set but not in custom mode
    if [ "$CONTEXT_MODE" != "custom" ] && [ "$CUSTOM_DOMAINS" != "all" ]; then
        echo "⚠️  Custom domain settings are ignored in '$CONTEXT_MODE' mode"
    fi
    
    # Warn if notifications enabled but service might not exist
    if [ "$ENABLE_NOTIFICATIONS" = "true" ] && [ -n "$NOTIFY_SERVICES" ]; then
        if ! echo "$NOTIFY_SERVICES" | grep -q "$NOTIFICATION_SERVICE"; then
            echo "⚠️  Notification service '$NOTIFICATION_SERVICE' may not be available"
        fi
    fi
}
```

## Better Preset Definitions

Make the presets crystal clear in documentation:

```markdown
## Context Modes Explained

### none
- No Home Assistant data provided to Claude
- Use when you only need Claude for general programming help

### minimal  
- Only essential devices: lights, switches, locks, alarms
- Only includes recently changed entities (last 24 hours)
- Typically 10-20 entities, ~300-600 tokens

### smart (Recommended)
- Automatically selects relevant entities based on:
  - Recent activity (weighted by domain)
  - Domain importance (security > convenience)
  - State validity (excludes unknown/unavailable)
- Typically 30-75 entities, ~1000-2500 tokens

### full
- All valid entities in your Home Assistant
- Excludes only unknown/unavailable states
- Can be 100-500+ entities, 3000-15000+ tokens
- ⚠️ High token usage, especially with Sonnet/Opus

### custom
- You control everything via the custom_* settings
- Use when presets don't match your needs
- Requires understanding of domains and token implications
```

## User Commands for Config Management

Add helpful commands users can run:

```bash
# Show current configuration with explanations
claude_config() {
    show_config_summary
    echo ""
    echo "Run 'claude_help config' for detailed explanations"
}

# Estimate token usage
claude_tokens() {
    local entity_count=$(cat /tmp/ha_context.txt 2>/dev/null | grep -c "entity_id" || echo "0")
    local estimated_tokens=$((entity_count * 30))
    
    echo "Context Summary:"
    echo "  Entities included: $entity_count"
    echo "  Estimated tokens: ~$estimated_tokens"
    echo "  Model token budget: $TOKEN_BUDGET"
    
    if [ $estimated_tokens -gt $TOKEN_BUDGET ]; then
        echo "  ⚠️ WARNING: Context may be truncated!"
    fi
}

# Preview what entities would be included
claude_preview() {
    echo "First 20 entities in context:"
    head -40 /tmp/ha_context.txt | grep -E "(entity_id|state):"
    echo "..."
    echo "Run 'cat /tmp/ha_context.txt' to see full context"
}
```

## Documentation-Driven Design

Since we can't make the UI self-explanatory:

1. **DOCS.md** - Comprehensive explanation of each setting
2. **Terminal Help** - Built-in `claude_help` command
3. **Startup Messages** - Clear feedback about what settings are active
4. **Warning Messages** - Alert about misconfigurations
5. **Example Configs** - Show common configuration patterns

## The Path Forward

1. Accept the flat configuration structure
2. Use clear naming with prefixes (custom_*, notify_*)
3. Move all intelligence to runtime
4. Provide excellent documentation and in-terminal help
5. Consider building a simple web UI in the future if complexity grows

This approach maintains the spirit of the Opus agent's excellent design while working within HA's constraints.