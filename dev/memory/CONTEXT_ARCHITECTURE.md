# Claude Home Context Architecture Design

## Overview

This document details the complete architecture for intelligent context management in Claude Home, focusing on providing relevant Home Assistant data to Claude while optimizing token usage and maintaining security.

## Architecture Components

### 1. Context Pipeline

```
[HA State Machine] → [Entity Fetcher] → [Entity Scorer] → [Context Builder] → [Token Optimizer] → [Claude]
```

### 2. Core Components

#### A. Entity Fetcher
Retrieves entity data from Home Assistant via Supervisor API proxy.

```python
class EntityFetcher:
    def __init__(self, supervisor_token):
        self.token = supervisor_token
        self.base_url = "http://supervisor/core/api"
    
    async def fetch_all_states(self):
        """Fetch all entity states from HA"""
        headers = {"Authorization": f"Bearer {self.token}"}
        response = await http_get(f"{self.base_url}/states", headers)
        return response.json()
    
    async def fetch_areas(self):
        """Fetch area registry data"""
        response = await http_get(f"{self.base_url}/config", headers)
        # Extract area information from config
        return response.json().get("areas", [])
    
    async def fetch_device_registry(self):
        """Fetch device registry for entity relationships"""
        # Note: May need to use WebSocket API for this
        pass
```

#### B. Entity Scorer
Implements intelligent scoring algorithm to rank entities by relevance.

```python
class EntityScorer:
    def __init__(self, config):
        self.config = config
        self.weights = config.scoring
        
    def score_entity(self, entity, context):
        """Score an entity based on multiple factors"""
        score = 0.0
        
        # 1. Recency Score (0-1)
        score += self._recency_score(entity) * self.weights.recency
        
        # 2. Activity Score (0-1) 
        score += self._activity_score(entity) * self.weights.activity
        
        # 3. Location Score (0-1)
        score += self._location_score(entity, context) * self.weights.location
        
        # 4. Relationship Score (0-1)
        score += self._relationship_score(entity, context) * self.weights.relationship
        
        # 5. Label/Tag Score (0-1)
        score += self._label_score(entity) * self.weights.labels
        
        return score
    
    def _recency_score(self, entity):
        """Score based on how recently entity changed"""
        if not entity.last_changed:
            return 0.0
            
        hours_ago = (datetime.now() - entity.last_changed).total_seconds() / 3600
        
        # Exponential decay with different rates by domain
        decay_rates = {
            "sensor": 24,      # Sensors decay slower
            "binary_sensor": 12,
            "light": 6,       # Lights decay faster
            "switch": 6,
            "climate": 48,    # Climate changes slowly
            "weather": 72     # Weather even slower
        }
        
        decay_rate = decay_rates.get(entity.domain, 12)
        return math.exp(-hours_ago / decay_rate)
    
    def _activity_score(self, entity):
        """Score based on state change frequency"""
        # Would need historical data - for now use heuristics
        domain_activity = {
            "automation": 0.9,  # Automations are usually important
            "script": 0.9,
            "light": 0.7,
            "switch": 0.7,
            "sensor": 0.5,
            "binary_sensor": 0.6,
            "climate": 0.8
        }
        return domain_activity.get(entity.domain, 0.4)
    
    def _location_score(self, entity, context):
        """Score based on area/location relevance"""
        if not entity.area_id:
            return 0.3  # Entities without areas get low score
            
        # High score for primary areas (bedroom, living room, kitchen)
        primary_areas = context.get("primary_areas", [])
        if entity.area_id in primary_areas:
            return 1.0
            
        # Medium score for secondary areas
        if entity.area_id in context.get("secondary_areas", []):
            return 0.6
            
        return 0.3
    
    def _relationship_score(self, entity, context):
        """Score based on relationships to other important entities"""
        # Entities in same device get bonus
        # Entities in same area as recently changed entities get bonus
        # This requires device registry data
        return 0.5  # Placeholder
    
    def _label_score(self, entity):
        """Score based on user-defined labels"""
        if "claude_important" in entity.labels:
            return 1.0
        if "claude_ignore" in entity.labels:
            return -1.0  # Negative score to exclude
        if "claude_context" in entity.labels:
            return 0.8
        return 0.0
```

#### C. Context Builder
Assembles the final context with token awareness.

```python
class ContextBuilder:
    def __init__(self, token_limit=5000):
        self.token_limit = token_limit
        
    def build_context(self, scored_entities, mode="smart"):
        """Build context based on mode and token limits"""
        
        # Sort entities by score
        sorted_entities = sorted(scored_entities, key=lambda x: x.score, reverse=True)
        
        # Apply mode-specific filters
        filtered_entities = self._apply_mode_filters(sorted_entities, mode)
        
        # Build context with token counting
        context = {
            "timestamp": datetime.now().isoformat(),
            "mode": mode,
            "areas": {},
            "entities": {},
            "summary": {}
        }
        
        token_count = 0
        for entity in filtered_entities:
            entity_tokens = self._estimate_entity_tokens(entity)
            
            if token_count + entity_tokens > self.token_limit:
                break
                
            # Add to context with appropriate formatting
            formatted = self._format_entity(entity, mode)
            context["entities"][entity.entity_id] = formatted
            
            # Group by area
            if entity.area_id:
                if entity.area_id not in context["areas"]:
                    context["areas"][entity.area_id] = []
                context["areas"][entity.area_id].append(entity.entity_id)
            
            token_count += entity_tokens
        
        # Add summary statistics
        context["summary"] = {
            "total_entities": len(context["entities"]),
            "estimated_tokens": token_count,
            "areas_covered": len(context["areas"]),
            "primary_domains": self._get_domain_counts(context["entities"])
        }
        
        return context
    
    def _apply_mode_filters(self, entities, mode):
        """Apply mode-specific filtering"""
        if mode == "minimal":
            # Only critical domains
            critical_domains = ["light", "switch", "lock", "alarm_control_panel", "climate"]
            return [e for e in entities if e.domain in critical_domains and e.score > 0.5]
            
        elif mode == "automation":
            # Focus on controllable entities and sensors
            automation_domains = ["light", "switch", "cover", "climate", "fan", "lock", 
                                "media_player", "vacuum", "script", "automation", "scene"]
            return [e for e in entities if e.domain in automation_domains or 
                   (e.domain in ["sensor", "binary_sensor"] and e.score > 0.7)]
            
        elif mode == "diagnostic":
            # Include more sensors and diagnostic entities
            return [e for e in entities if e.score > 0.3]
            
        else:  # smart mode
            # Use scoring only, but exclude very low scores
            return [e for e in entities if e.score > 0.2]
    
    def _format_entity(self, entity, mode):
        """Format entity for context based on mode"""
        if mode == "minimal":
            # Just state and basic info
            return {
                "state": entity.state,
                "last_changed": entity.last_changed
            }
        else:
            # Include more details
            formatted = {
                "state": entity.state,
                "attributes": self._filter_attributes(entity.attributes),
                "last_changed": entity.last_changed,
                "area": entity.area_name
            }
            
            # Add friendly name if different from entity_id
            if entity.attributes.get("friendly_name"):
                formatted["name"] = entity.attributes["friendly_name"]
                
            return formatted
    
    def _filter_attributes(self, attributes):
        """Filter out noisy attributes"""
        exclude = ["icon", "entity_picture", "supported_features", 
                  "attribution", "restored", "supported_color_modes"]
        
        return {k: v for k, v in attributes.items() 
                if k not in exclude and not k.startswith("_")}
    
    def _estimate_entity_tokens(self, entity):
        """Estimate tokens for an entity"""
        # Basic estimation
        base_tokens = 10  # entity_id + state
        
        # Add for attributes
        attr_tokens = len(entity.attributes) * 5
        
        # Add for formatting
        format_tokens = 5
        
        return base_tokens + attr_tokens + format_tokens
```

### 3. Context Formats

#### A. Minimal Format
```yaml
context:
  living_room_light:
    state: "on"
    brightness: 254
  
  front_door_lock:
    state: "locked"
  
  thermostat:
    state: "heat"
    temperature: 72
    target_temp: 70
```

#### B. Smart Format
```yaml
context:
  areas:
    living_room:
      lights:
        - living_room_light: "on (100%)"
        - living_room_lamp: "off"
      climate:
        - thermostat: "heating to 70°F (currently 72°F)"
    
  recent_changes:
    - front_door_lock: "locked 5 minutes ago"
    - motion_sensor: "detected 2 minutes ago"
  
  automations:
    - sunset_lights: "will trigger in 2 hours"
```

#### C. Diagnostic Format
```yaml
context:
  summary:
    total_entities: 247
    active_automations: 12
    recent_errors: 0
    
  by_domain:
    lights: 23 (18 on)
    switches: 15 (5 on)
    sensors: 125
    binary_sensors: 48
    
  important_states:
    security:
      - all doors: "locked"
      - alarm: "armed_home"
    climate:
      - average_temp: "71°F"
      - humidity: "45%"
```

### 4. Update Strategies

#### A. Static Context (Default)
- Context built once at conversation start
- Remains unchanged throughout conversation
- Most token-efficient

#### B. Dynamic Context
- Updates every N turns
- Or when explicitly requested
- Useful for long conversations

#### C. Event-Driven Context
- Updates when significant events occur
- Subscribes to state_changed events
- More complex but most accurate

### 5. Security Considerations

1. **Data Filtering**
   - Never include passwords or tokens
   - Filter out sensitive attributes
   - Respect user privacy settings

2. **Access Control**
   - Only access what hassio_api permits
   - No direct database access
   - Use official API endpoints only

3. **Data Minimization**
   - Only include necessary data
   - Summarize when possible
   - Respect token limits

## Implementation Phases

### Phase 1: Basic Implementation
- Simple domain filtering
- Static context at conversation start
- Basic token counting

### Phase 2: Smart Scoring
- Implement entity scoring
- Add area grouping
- Smarter attribute filtering

### Phase 3: Advanced Features
- Dynamic updates
- Custom scoring functions
- Context templates

### Phase 4: Optimization
- Caching layer
- Batch API requests
- Performance tuning

## Performance Considerations

1. **API Calls**
   - Batch requests when possible
   - Cache area and device registry
   - Minimize repeated calls

2. **Memory Usage**
   - Stream large responses
   - Limit in-memory entity count
   - Use generators for processing

3. **Token Optimization**
   - Pre-calculate token estimates
   - Use compression techniques
   - Cache formatted contexts

## Testing Strategy

1. **Unit Tests**
   - Entity scorer logic
   - Token estimation accuracy
   - Format conversions

2. **Integration Tests**
   - API communication
   - Full pipeline flow
   - Error handling

3. **Performance Tests**
   - Large entity counts (1000+)
   - Token limit compliance
   - Response time targets

## Future Enhancements

1. **Machine Learning**
   - Learn user preferences
   - Predict important entities
   - Optimize scoring weights

2. **Natural Language**
   - Context in plain English
   - Summarization techniques
   - Intent detection

3. **Visualization**
   - Context preview UI
   - Token usage graphs
   - Entity importance map