# Claude Home Configuration Redesign V2: Simplified for HA UI Reality

## Overview

This revised design adapts our sophisticated context system to Home Assistant's flat configuration UI constraints while maintaining the intelligent features users need.

## Core Principles

1. **Maximum 7 visible fields** - Prevent overwhelm
2. **Smart defaults** - Work perfectly out of the box
3. **Runtime intelligence** - Complexity hidden from configuration
4. **Progressive disclosure** - Advanced features via terminal commands

## Simplified Configuration Structure

### config.yaml
```yaml
options:
  # Essential Settings (Always Visible)
  model: "haiku"
  context_mode: "smart"
  context_filter: ""
  auto_start: true
  notifications: false
  notification_service: "persistent_notification"
  debug_mode: false

schema:
  model: "list(haiku|sonnet|opus)"
  context_mode: "list(none|minimal|smart|full|custom)"
  context_filter: "str?"
  auto_start: "bool?"
  notifications: "bool?"
  notification_service: "str?"
  debug_mode: "bool?"
```

### Field Definitions

#### 1. Model Selection
```yaml
model:
  name: "AI Model"
  description: "Haiku=$0.25/day, Sonnet=$1/day, Opus=$5/day typical cost"
```

**Runtime Behavior**:
- Auto-applies optimal token limits
- Adjusts context formatting
- Sets appropriate scoring thresholds

#### 2. Context Mode
```yaml
context_mode:
  name: "Home Assistant Context"
  description: "How much HA data to include. Smart mode recommended."
```

**Mode Behaviors**:
- `none`: No HA data included
- `minimal`: Only critical entities (locks, alarms, climate)
- `smart`: Intelligent selection based on activity (default)
- `full`: All entities (high token usage)
- `custom`: Use context_filter field

#### 3. Context Filter
```yaml
context_filter:
  name: "Context Filter (Optional)"
  description: "Limit to areas or domains: 'bedroom,kitchen' or 'light,switch'"
```

**Smart Parsing**:
```python
def parse_context_filter(filter_string):
    if not filter_string:
        return {}
    
    parts = [p.strip() for p in filter_string.split(',')]
    
    # Detect if domains or areas
    known_domains = ['light', 'switch', 'sensor', 'climate', ...]
    
    domains = [p for p in parts if p in known_domains]
    areas = [p for p in parts if p not in known_domains]
    
    return {
        'domains': domains,
        'areas': areas
    }
```

#### 4. Auto Start
```yaml
auto_start:
  name: "Auto-start Claude"
  description: "Start Claude automatically when opening terminal"
```

#### 5. Notifications
```yaml
notifications:
  name: "Enable Notifications"
  description: "Send activity alerts to Home Assistant"
```

#### 6. Notification Service
```yaml
notification_service:
  name: "Notification Service"
  description: "Leave empty for auto-detection"
```

#### 7. Debug Mode
```yaml
debug_mode:
  name: "Debug Mode"
  description: "Show token usage and context details"
```

## Hidden Intelligence

### 1. Adaptive Scoring Algorithm

The scoring system from V1 remains but is completely hidden:

```python
class SmartContextSelector:
    def __init__(self, mode, model, filter_string):
        self.mode = mode
        self.model = model
        self.filters = parse_context_filter(filter_string)
        
        # Model-aware limits
        self.token_limits = {
            'haiku': 3000,
            'sonnet': 8000,
            'opus': 15000
        }
        
        # Preset scoring weights by mode
        self.weights = self._get_mode_weights(mode)
    
    def _get_mode_weights(self, mode):
        """Hidden complexity: different modes use different scoring"""
        if mode == 'minimal':
            return {
                'recency': 0.2,
                'domain': 0.6,    # Domain matters most
                'activity': 0.2
            }
        elif mode == 'smart':
            return {
                'recency': 0.4,   # Recent changes important
                'domain': 0.2,
                'activity': 0.3,
                'location': 0.1
            }
        # ... etc
```

### 2. Automatic Service Discovery

```python
async def auto_configure_notifications():
    """Automatically find best notification service"""
    services = await get_notification_services()
    
    # Priority order
    priority = [
        'notify.mobile_app',    # Best: goes to phone
        'notify.notify',        # Good: default service
        'persistent_notification'  # Fallback: always works
    ]
    
    for service in priority:
        if service in services:
            return service
    
    return 'persistent_notification'
```

### 3. Context Mode Intelligence

```python
def enhance_smart_mode(entities, user_history=None):
    """Make 'smart' mode truly smart"""
    
    # Time-based adjustments
    hour = datetime.now().hour
    if 22 <= hour or hour <= 6:
        # Nighttime: prioritize bedroom, security
        boost_areas(['bedroom', 'hallway'])
        boost_domains(['light', 'lock', 'binary_sensor'])
    
    # Learn from past queries (if available)
    if user_history:
        frequently_accessed = analyze_query_patterns(user_history)
        boost_entities(frequently_accessed)
    
    # Seasonal adjustments
    month = datetime.now().month
    if month in [12, 1, 2]:  # Winter
        boost_domains(['climate', 'sensor.temperature'])
    
    return apply_scoring(entities)
```

## Migration from V1 Design

### What Changes

| V1 Field | V2 Approach |
|----------|-------------|
| `context_domains` | Part of smart mode or filter |
| `context_max_entities` | Auto-set by model |
| `scoring.recency_weight` | Hidden in smart algorithm |
| `verbose_logging` | Replaced by debug_mode |
| `max_turns` | Removed (Claude CLI handles) |

### Backward Compatibility

```python
def migrate_v1_config(old_config):
    """Convert old configuration to new format"""
    new_config = {
        'model': old_config.get('claude_model', 'haiku'),
        'context_mode': 'custom' if old_config.get('context_domains') else 'smart',
        'context_filter': old_config.get('context_domains', ''),
        'auto_start': old_config.get('auto_claude', True),
        'notifications': old_config.get('ha_notifications', False),
        'notification_service': old_config.get('notification_service', ''),
        'debug_mode': old_config.get('verbose_logging', False)
    }
    return new_config
```

## Runtime Configuration Experience

### 1. Startup Feedback

```bash
# When context_mode is "smart"
🤖 Claude Home: Smart Context Active
📊 Selected 47 relevant entities from 312 total
🏠 Prioritizing: Living Room, Kitchen (recent activity)
💡 Focusing on: lights, climate (based on time of day)
💰 Estimated tokens: 1,420 (well within Haiku limits)

# When context_filter is used
🤖 Claude Home: Custom Filter Active
🏠 Areas: bedroom, office
🔌 Domains: light, switch, sensor
📊 Selected 23 entities matching your filter
💰 Estimated tokens: 690

# When debug_mode is true
🤖 Claude Home: Debug Mode Active
📊 Context Details:
  - Scoring weights: recency=0.4, domain=0.2, activity=0.3
  - Top entities by score:
    1. light.bedroom (score: 0.89, changed 5 min ago)
    2. climate.living_room (score: 0.84, active)
    3. lock.front_door (score: 0.82, security)
```

### 2. Interactive Commands

```bash
# Check current configuration
$ claude-config status
Current Configuration:
  Model: haiku (cost-optimized)
  Context: smart mode
  Entities: 47 selected from 312 total
  Token estimate: 1,420
  
# Get recommendations
$ claude-config suggest
Based on your usage:
  ✓ Model 'haiku' is appropriate for your entity count
  💡 Consider adding filter 'bedroom,office' (your most active areas)
  💡 Enable notifications to track token usage

# Preview context
$ claude-config preview
Context Preview (smart mode):
=== Living Room (3 entities) ===
  light.living_room_lamp: on (75% brightness)
  climate.living_room: heating (72°F → 70°F)
  sensor.living_room_motion: clear (10 min ago)
  
=== Kitchen (2 entities) ===
  light.kitchen: off
  switch.coffee_maker: on (started 5 min ago)
[... truncated for preview ...]
```

## Advanced Features (Via Terminal)

### 1. CLAUDE.md Configuration

Users can create `/config/claude-config/CLAUDE.md`:

```markdown
# Claude Home Preferences

## Context Preferences
- Prefer areas: bedroom, office
- Ignore domains: sensor.weather_*
- Important entities: light.desk_lamp, switch.coffee_maker

## Custom Scoring (Advanced)
scoring:
  recency: 0.6  # I care about recent changes
  location: 0.3  # Area grouping important
  domain: 0.1   # Domain less important
```

### 2. Export/Import

```bash
# Export current configuration
$ claude-config export > my-claude-config.json

# Import configuration
$ claude-config import my-claude-config.json

# Share configuration
$ claude-config share
Configuration uploaded to: https://claude-home.io/configs/abc123
Share this URL to let others use your configuration
```

## Benefits of V2 Design

### 1. For New Users
- Only 7 fields to understand
- Smart defaults work immediately
- Clear cost indicators
- No overwhelming options

### 2. For Power Users
- Full control via terminal commands
- CLAUDE.md for persistent preferences
- Debug mode for transparency
- Export/share configurations

### 3. For Maintenance
- Fewer configuration fields to document
- Smart mode handles most use cases
- Runtime validation catches issues
- Reduced support burden

## Implementation Notes

### 1. Validation
```python
def validate_configuration(config):
    """Runtime validation with helpful messages"""
    issues = []
    
    if config['context_mode'] == 'custom' and not config['context_filter']:
        issues.append("Custom mode selected but no filter provided. Using smart mode instead.")
    
    if config['notifications'] and not config['notification_service']:
        service = auto_configure_notifications()
        issues.append(f"Auto-detected notification service: {service}")
    
    if config['model'] == 'opus' and config['context_mode'] == 'full':
        issues.append("Warning: Opus + full context may result in high costs!")
    
    return issues
```

### 2. Progressive Enhancement
```python
def check_advanced_config():
    """Check for advanced configuration files"""
    configs = []
    
    # Check for CLAUDE.md
    if os.path.exists('/config/claude-config/CLAUDE.md'):
        configs.append('CLAUDE.md preferences found')
    
    # Check for exported config
    if os.path.exists('/config/claude-config/advanced.json'):
        configs.append('Advanced configuration found')
    
    return configs
```

## Summary

V2 successfully adapts our sophisticated design to HA's constraints:
- **7 simple fields** instead of 20+ complex ones
- **Smart defaults** that genuinely work well
- **Hidden intelligence** that adapts to usage
- **Terminal commands** for advanced users
- **Same powerful backend** with better UX

The result is more approachable for beginners while maintaining full power for advanced users.