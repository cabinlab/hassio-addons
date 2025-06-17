# Token Optimization Guide for Claude Home

## Overview

This guide provides comprehensive strategies for reducing token usage in Claude Home while maintaining context quality. Based on Claude Code's average cost of $6/developer/day, optimization is crucial for Home Assistant users who may have hundreds of entities.

## Token Usage Breakdown

### 1. Context Components and Their Costs

```
Typical HA Context Token Usage:
- Entity ID: 3-5 tokens
- Entity State: 1-3 tokens  
- Friendly Name: 2-5 tokens
- Attributes: 10-50 tokens per entity
- Formatting/Structure: 2-3 tokens per entity
- Total per entity: 20-65 tokens average
```

### 2. Model-Specific Considerations

| Model | Context Window | Cost Multiplier | Recommended Entity Limit |
|-------|---------------|-----------------|-------------------------|
| Haiku | Smaller | 1x | 50 entities |
| Sonnet | Medium | 4x | 100 entities |
| Opus | Large | 19x | 200 entities |

## Optimization Strategies

### Strategy 1: Smart Entity Selection

#### A. Relevance Scoring
```python
def calculate_entity_relevance(entity):
    """Score entity relevance to reduce context size"""
    score = 0
    
    # Recency bonus (exponential decay)
    hours_since_change = (now - entity.last_changed).hours
    if hours_since_change < 1:
        score += 10
    elif hours_since_change < 24:
        score += 5
    elif hours_since_change < 168:  # 1 week
        score += 1
    
    # Domain importance
    critical_domains = ['lock', 'alarm_control_panel', 'climate']
    important_domains = ['light', 'switch', 'cover', 'media_player']
    
    if entity.domain in critical_domains:
        score += 8
    elif entity.domain in important_domains:
        score += 5
    
    # State importance
    if entity.state not in ['unknown', 'unavailable']:
        score += 2
    
    return score
```

#### B. Dynamic Filtering
```python
def filter_entities_by_context(entities, user_query):
    """Filter entities based on user's query"""
    query_lower = user_query.lower()
    
    # Domain hints in query
    if 'light' in query_lower or 'lamp' in query_lower:
        return prioritize_domains(entities, ['light', 'switch'])
    
    if 'temperature' in query_lower or 'climate' in query_lower:
        return prioritize_domains(entities, ['climate', 'sensor'])
    
    if 'security' in query_lower or 'lock' in query_lower:
        return prioritize_domains(entities, ['lock', 'binary_sensor', 'alarm_control_panel'])
    
    # Default: balanced selection
    return smart_selection(entities)
```

### Strategy 2: Efficient Data Formatting

#### A. Concise State Representation
```python
# BEFORE (65 tokens):
{
  "entity_id": "light.living_room_ceiling",
  "state": "on",
  "attributes": {
    "brightness": 254,
    "color_mode": "brightness",
    "friendly_name": "Living Room Ceiling Light",
    "supported_features": 44,
    "supported_color_modes": ["brightness"],
    "icon": "mdi:ceiling-light"
  },
  "last_changed": "2024-01-09T15:30:45.123456+00:00",
  "last_updated": "2024-01-09T15:30:45.123456+00:00"
}

# AFTER (15 tokens):
living_room_ceiling: on (100% brightness, 30min ago)
```

#### B. Attribute Filtering
```python
def filter_attributes(attributes):
    """Remove redundant attributes to save tokens"""
    # Always exclude
    exclude_always = {
        'icon', 'entity_picture', 'supported_features',
        'supported_color_modes', 'attribution', 'device_class',
        'state_class', 'unit_of_measurement'  # Include in state instead
    }
    
    # Conditionally include
    filtered = {}
    for key, value in attributes.items():
        if key not in exclude_always and not key.startswith('_'):
            # Include only if informative
            if key == 'friendly_name' and value != entity_id:
                filtered['name'] = value
            elif key == 'temperature' and 'climate' in entity_id:
                filtered['temp'] = f"{value}°"
            elif key == 'brightness':
                filtered['brightness'] = f"{int(value/255*100)}%"
            # Add more conditional includes
    
    return filtered
```

### Strategy 3: Context Compression Techniques

#### A. Group Similar Entities
```python
# BEFORE (150 tokens):
"""
light.bedroom_1: on
light.bedroom_2: on  
light.bedroom_3: off
light.bedroom_4: on
switch.bedroom_fan: on
sensor.bedroom_temp: 72
sensor.bedroom_humidity: 45
"""

# AFTER (50 tokens):
"""
Bedroom: 3/4 lights on, fan on, 72°F/45% humidity
"""
```

#### B. State Summarization
```python
def summarize_domain_states(entities_by_domain):
    """Create concise domain summaries"""
    summaries = []
    
    for domain, entities in entities_by_domain.items():
        if domain == 'light':
            on_count = sum(1 for e in entities if e.state == 'on')
            total = len(entities)
            summaries.append(f"Lights: {on_count}/{total} on")
            
        elif domain == 'binary_sensor':
            active = [e for e in entities if e.state == 'on']
            if active:
                summaries.append(f"Active sensors: {', '.join(e.name for e in active[:5])}")
                if len(active) > 5:
                    summaries.append(f"  ...and {len(active)-5} more")
                    
        elif domain == 'climate':
            for e in entities:
                current = e.attributes.get('current_temperature', '?')
                target = e.attributes.get('temperature', '?') 
                summaries.append(f"{e.name}: {current}°/{target}° ({e.state})")
    
    return '\n'.join(summaries)
```

### Strategy 4: Smart Context Templates

#### A. Task-Specific Templates
```python
CONTEXT_TEMPLATES = {
    'automation_helper': {
        'domains': ['light', 'switch', 'script', 'automation', 'scene'],
        'attributes': ['brightness', 'color_temp'],
        'format': 'concise',
        'max_entities': 50
    },
    
    'diagnostic': {
        'domains': 'all',
        'attributes': 'all',
        'format': 'detailed',
        'include_unchanged': True,
        'max_entities': 100
    },
    
    'status_check': {
        'domains': ['binary_sensor', 'lock', 'climate', 'alarm_control_panel'],
        'attributes': ['battery_level', 'temperature'],
        'format': 'summary',
        'max_entities': 30
    }
}
```

#### B. Progressive Context Loading
```python
class ProgressiveContextManager:
    """Load context in stages based on token budget"""
    
    def __init__(self, token_budget=5000):
        self.token_budget = token_budget
        self.used_tokens = 0
        
    def build_context(self, entities):
        context = []
        
        # Stage 1: Critical entities (20% budget)
        critical = self.add_critical_entities(entities, self.token_budget * 0.2)
        context.extend(critical)
        
        # Stage 2: Recent changes (30% budget)
        recent = self.add_recent_changes(entities, self.token_budget * 0.3)
        context.extend(recent)
        
        # Stage 3: User favorites (20% budget)
        favorites = self.add_user_favorites(entities, self.token_budget * 0.2)
        context.extend(favorites)
        
        # Stage 4: Fill remaining budget
        remaining = self.fill_remaining_budget(entities, self.token_budget - self.used_tokens)
        context.extend(remaining)
        
        return context
```

### Strategy 5: Caching and Deduplication

#### A. Context Caching
```python
class ContextCache:
    """Cache formatted context to avoid reprocessing"""
    
    def __init__(self, ttl=300):  # 5 minutes
        self.cache = {}
        self.ttl = ttl
        
    def get_or_build(self, cache_key, builder_func):
        if cache_key in self.cache:
            entry, timestamp = self.cache[cache_key]
            if time.time() - timestamp < self.ttl:
                return entry
        
        # Build new context
        result = builder_func()
        self.cache[cache_key] = (result, time.time())
        return result
```

#### B. Delta Updates
```python
def get_context_delta(previous_context, current_states):
    """Only include changed entities to save tokens"""
    delta = {
        'changed': [],
        'summary': {}
    }
    
    for entity_id, current_state in current_states.items():
        if entity_id in previous_context:
            prev_state = previous_context[entity_id]
            if current_state != prev_state:
                delta['changed'].append({
                    'id': entity_id,
                    'old': prev_state,
                    'new': current_state
                })
        else:
            # New entity
            delta['changed'].append({
                'id': entity_id,
                'new': current_state
            })
    
    delta['summary'] = {
        'total_changes': len(delta['changed']),
        'timestamp': datetime.now().isoformat()
    }
    
    return delta
```

### Strategy 6: Natural Language Compression

#### A. Entity Descriptions
```python
def natural_language_state(entity):
    """Convert entity to natural language to save tokens"""
    domain = entity.entity_id.split('.')[0]
    name = entity.attributes.get('friendly_name', entity.entity_id)
    
    if domain == 'light':
        if entity.state == 'on':
            brightness = entity.attributes.get('brightness', 255)
            pct = int(brightness / 255 * 100)
            return f"{name} is on at {pct}%"
        return f"{name} is off"
    
    elif domain == 'climate':
        current = entity.attributes.get('current_temperature')
        target = entity.attributes.get('temperature')
        mode = entity.state
        return f"{name}: {current}° (target {target}°, {mode})"
    
    elif domain == 'binary_sensor':
        state_map = {
            'on': 'detected',
            'off': 'clear'
        }
        device_class = entity.attributes.get('device_class', '')
        if device_class == 'motion':
            return f"{name}: {'motion' if entity.state == 'on' else 'no motion'}"
        return f"{name} is {state_map.get(entity.state, entity.state)}"
    
    # Default
    return f"{name}: {entity.state}"
```

### Strategy 7: Implementation Best Practices

#### A. Token Budgeting
```python
class TokenBudget:
    """Manage token allocation across context components"""
    
    def __init__(self, total_budget):
        self.total = total_budget
        self.allocations = {
            'system_prompt': 0.1,    # 10% for system context
            'entity_context': 0.6,   # 60% for HA entities
            'conversation': 0.2,     # 20% for chat history
            'buffer': 0.1           # 10% safety buffer
        }
    
    def get_entity_budget(self):
        return int(self.total * self.allocations['entity_context'])
    
    def estimate_tokens(self, text):
        # Rough estimate: 1 token per 4 characters
        return len(text) / 4
```

#### B. Monitoring and Alerts
```python
async def monitor_token_usage(conversation_tokens, threshold=10000):
    """Alert when approaching token limits"""
    if conversation_tokens > threshold * 0.8:
        await send_notification(
            "Claude Home: High token usage detected",
            f"Current usage: {conversation_tokens} tokens"
        )
    
    if conversation_tokens > threshold:
        # Trigger context reduction
        return True
    return False
```

## Summary and Recommendations

### For New Users (Haiku Model)
1. Use "smart" context mode
2. Limit to 50 most relevant entities
3. Use concise formatting
4. Expected cost: ~$0.25/day

### For Power Users (Sonnet Model)  
1. Use custom context with scoring
2. 100 entity limit with smart filtering
3. Enable delta updates
4. Expected cost: ~$1.00/day

### For Advanced Users (Opus Model)
1. Full custom configuration
2. Dynamic context updates
3. Task-specific templates
4. Expected cost: ~$5.00/day

### Key Optimization Wins
1. **-70% tokens**: Smart entity selection vs all entities
2. **-40% tokens**: Concise formatting vs full JSON
3. **-30% tokens**: Attribute filtering vs all attributes
4. **-25% tokens**: Natural language vs structured data
5. **-20% tokens**: Caching and deduplication

### Implementation Priority
1. **High Impact**: Entity scoring and filtering
2. **Medium Impact**: Concise formatting
3. **Low Complexity**: Attribute filtering
4. **Advanced**: Natural language compression

By implementing these strategies, Claude Home can provide rich Home Assistant context while keeping token usage and costs under control.