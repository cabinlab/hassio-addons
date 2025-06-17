# Home Assistant Addon Configuration UI Limitations

## Reality Check

The HA addon configuration UI is much more limited than our proposals assume. Here's what we CANNOT do:

### 1. No Progressive Disclosure
- ❌ Cannot hide/show fields based on other fields
- ❌ Cannot have "if context_mode = custom, show these fields"
- ❌ All fields are always visible in a flat list

### 2. No Field Grouping
- ❌ Cannot create sections like "Basic" and "Advanced"
- ❌ Cannot visually group related fields
- ❌ Everything appears in one long list

### 3. No Dynamic Content
- ❌ Cannot show live token estimates
- ❌ Cannot preview what entities would be selected
- ❌ Cannot validate against current HA state

### 4. Limited Field Types
Available:
- `str` - Text input
- `bool` - Checkbox
- `int(min,max)` - Number with range
- `list(option1|option2|...)` - Dropdown (>5 items) or radio buttons (≤5)
- `password` - Hidden text

NOT available:
- Multi-select
- Nested configuration
- Custom validators
- Rich text/HTML
- Buttons or actions

### 5. Limited Text Display
- Field names: Short labels only
- Descriptions: Single line of plain text
- No markdown, no line breaks, no formatting
- No tooltips or expandable help

## What This Means for Our Design

### 1. Context Mode Approach Still Works
```yaml
context_mode: "list(none|minimal|smart|full|custom)"
```
But if user selects "custom", they'll see ALL the custom fields whether they need them or not.

### 2. Flatten Everything
Instead of:
```yaml
context_config:
  domains: ["light", "switch"]
  max_entities: 100
```

We need:
```yaml
context_domains: "light,switch,sensor"  # Comma-separated string
context_max_entities: 100
```

### 3. Use Naming to Create Visual Groups
Since we can't group fields, use prefixes:
```yaml
# Basic settings (name suggests grouping)
claude_model: "haiku"
context_mode: "smart"

# Notification settings
notify_enabled: false
notify_service: "persistent_notification"
notify_on_high_tokens: true

# Advanced context settings
advanced_context_domains: "all"
advanced_max_entities: 100
advanced_token_limit: 5000
```

### 4. Move Complexity to Runtime
Since we can't make the UI smart, make the runtime smart:
- Auto-detect if custom fields are actually customized
- Ignore advanced fields if using preset modes
- Show configuration summary in terminal at startup

### 5. Documentation Is Critical
Since we can't explain things in the UI:
- Put detailed docs in DOCS.md
- Show helpful messages in the terminal
- Create a `claude_config` command to show current settings

## Revised Configuration Approach

```yaml
options:
  # Essential (always visible)
  claude_model: "haiku"
  context_mode: "smart"
  auto_claude: false
  
  # Notifications (always visible, but ignored if false)
  notifications_enabled: false
  notification_service: "persistent_notification"
  
  # Custom Context (always visible, but ignored unless context_mode=custom)
  custom_domains: "all"  # or comma-separated list
  custom_max_entities: 100
  custom_include_areas: ""  # comma-separated
  custom_exclude_entities: ""  # comma-separated patterns

schema:
  claude_model: "list(haiku|sonnet|opus)"
  context_mode: "list(none|minimal|smart|full|custom)"
  auto_claude: "bool?"
  notifications_enabled: "bool?"
  notification_service: "str?"
  custom_domains: "str?"
  custom_max_entities: "int(10,500)?"
  custom_include_areas: "str?"
  custom_exclude_entities: "str?"
```

## Workarounds for Better UX

1. **Startup Banner**: Show configuration summary with helpful hints
2. **Commands**: Add `claude_config` to show/explain current settings
3. **Presets**: Do the progressive disclosure in code, not UI
4. **Warnings**: Alert when conflicting settings detected
5. **Help Command**: Add `claude_help config` for detailed guidance

## The Reality

HA's addon config UI is designed for simple key-value settings, not complex configuration. We need to:
1. Keep the schema simple and flat
2. Move intelligence to the runtime
3. Use clear naming and documentation
4. Accept that all fields will always be visible

This is why many addons (like ESPHome, Node-RED) build their own web UIs instead of relying on HA's config screen.