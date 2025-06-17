# Claude Home Configuration Redesign Proposal

## Executive Summary

This redesign focuses on creating a smarter, more user-friendly configuration system that optimizes token usage and leverages Home Assistant's native capabilities. The key improvements include intelligent context selection, progressive disclosure of options, and better integration with HA's organizational features.

## Core Design Principles

1. **Progressive Disclosure** - Show basic options first, advanced options on demand
2. **Smart Defaults** - Optimize for common use cases out of the box
3. **Token Awareness** - Help users understand and control token usage
4. **Native Integration** - Leverage HA's built-in features wherever possible
5. **Task-Based Context** - Adjust context based on what the user is trying to do

## Configuration Structure Redesign

### Basic Configuration (Always Visible)

```yaml
options:
  # Model Selection with Clear Cost Indicators
  claude_model: "haiku"  # Default to most cost-effective
  
  # Preset Context Mode
  context_mode: "smart"  # New field replacing context_integration
  
  # Auto-start preference
  auto_claude: true
  
  # Notification preference
  enable_notifications: false
```

### Context Modes (Replaces current context system)

```yaml
context_mode:
  name: "Context Mode"
  description: "How Claude accesses your Home Assistant data"
  options:
    none: "No Context - Claude works without HA data"
    minimal: "Minimal - Only critical entities (lights, locks, alarms)"
    smart: "Smart - Intelligently selected based on activity"
    automation: "Automation Helper - Entities useful for creating automations"
    full: "Full Access - All entities (high token usage)"
    custom: "Custom - Configure specific domains and filters"
```

### Advanced Configuration (Conditionally Shown)

Only shown when `context_mode` is set to "custom":

```yaml
# Custom Context Configuration
context_config:
  # Primary Filters
  domains: ["light", "switch", "climate", "sensor"]
  
  # Smart Filters
  include_areas: []  # Empty = all areas
  include_labels: ["claude_important", "claude_context"]
  exclude_labels: ["claude_ignore"]
  
  # Entity Scoring Weights
  scoring:
    recency_weight: 0.4  # How recently entity changed
    area_weight: 0.2     # If in user's primary areas
    label_weight: 0.3    # If labeled for Claude
    domain_weight: 0.1   # Domain priority
  
  # Limits
  max_entities: 100
  max_tokens: 5000  # Estimated token limit for context
  
  # Update Strategy
  update_frequency: "conversation_start"  # or "every_turn", "manual"
```

### Model-Aware Configuration

```yaml
# Model-specific optimizations (hidden, auto-applied)
model_presets:
  haiku:
    default_max_entities: 50
    token_budget: 3000
    context_format: "concise"
  sonnet:
    default_max_entities: 100
    token_budget: 8000
    context_format: "detailed"
  opus:
    default_max_entities: 200
    token_budget: 15000
    context_format: "comprehensive"
```

### Notification Configuration

Only shown when `enable_notifications` is true:

```yaml
notification_config:
  service: "persistent_notification"  # Auto-discovered
  events:
    - conversation_start
    - high_token_usage
    - error_occurred
  token_threshold: 10000  # Warn when conversation exceeds this
```

## UI/UX Improvements

### 1. Configuration Sections

Group related options visually:
- **Essentials** (always visible)
  - Model selection with cost indicator
  - Context mode
  - Auto-start preference
  
- **Notifications** (collapsible)
  - Enable/disable
  - Service selection (only if enabled)
  - Event triggers
  
- **Advanced Context** (only for custom mode)
  - Domain selection
  - Filtering options
  - Token limits

### 2. Dynamic Field Updates

- When `context_mode` changes, show/hide relevant fields
- When `enable_notifications` changes, show/hide notification options
- Validate selections against available HA features

### 3. Helper Text Improvements

```yaml
claude_model:
  name: "AI Model"
  description: |
    💰 Cost Impact:
    • Haiku: ~$0.25/day typical usage
    • Sonnet: ~$1.00/day (4x Haiku)
    • Opus: ~$5.00/day (20x Haiku)
    
    Choose based on your needs and budget.
```

## Implementation Details

### 1. Smart Context Selection Algorithm

```python
def score_entity(entity, config):
    score = 0.0
    
    # Recency score (exponential decay)
    hours_since_change = (now - entity.last_changed).hours
    recency_score = exp(-hours_since_change / 24)
    score += recency_score * config.scoring.recency_weight
    
    # Area score (is entity in important area?)
    if entity.area_id in user_primary_areas:
        score += 1.0 * config.scoring.area_weight
    
    # Label score
    if "claude_important" in entity.labels:
        score += 1.0 * config.scoring.label_weight
    elif "claude_ignore" in entity.labels:
        return 0  # Skip entirely
    
    # Domain priority
    domain_priorities = {
        "light": 0.8,
        "switch": 0.8,
        "climate": 0.9,
        "lock": 1.0,
        "alarm_control_panel": 1.0,
        "sensor": 0.5,
        "binary_sensor": 0.6
    }
    score += domain_priorities.get(entity.domain, 0.3) * config.scoring.domain_weight
    
    return score
```

### 2. Context Presets

**Minimal Context**:
- Domains: light, switch, lock, alarm_control_panel
- Max entities: 20
- Only entities changed in last 24 hours

**Smart Context**:
- All domains
- Max entities: Based on model
- Scored by importance algorithm
- Excludes diagnostic entities

**Automation Helper**:
- Domains: All actuators (light, switch, cover, etc.)
- Includes: Recently triggered automations
- Includes: Related entities from same device/area
- Max entities: 75

### 3. Token Estimation

```python
def estimate_tokens(entities):
    # Rough estimation: 
    # - Entity ID: ~5 tokens
    # - State: ~2 tokens
    # - Attributes: ~20 tokens average
    # - Formatting: ~3 tokens
    
    tokens_per_entity = 30
    return len(entities) * tokens_per_entity
```

## Migration Strategy

1. **Backward Compatibility**
   - Map old fields to new structure
   - `context_integration: true` → `context_mode: smart`
   - `context_domains` → `context_config.domains`
   - `context_max_entities` → `context_config.max_entities`

2. **Gradual Rollout**
   - Phase 1: Add new fields alongside old ones
   - Phase 2: Deprecate old fields with warnings
   - Phase 3: Remove old fields

## Benefits

1. **Better UX**
   - Clearer cost implications
   - Simpler for beginners
   - Powerful for advanced users

2. **Smarter Context**
   - Relevant entities prioritized
   - Token usage optimized
   - Task-appropriate context

3. **Native Integration**
   - Uses HA areas and labels
   - Respects entity categories
   - Leverages HA's organization

4. **Token Efficiency**
   - 50-70% reduction in context size
   - Model-aware limits
   - User-controllable budgets

## Open Questions

1. Should we add a "context preview" feature to show what entities would be included?
2. Should context update during long conversations or stay static?
3. Should we support custom scoring functions for power users?
4. How do we handle entities without areas assigned?

## Next Steps

1. Implement entity scoring algorithm
2. Create context preset logic
3. Update configuration schema
4. Design UI mockups for settings page
5. Test with various HA setups