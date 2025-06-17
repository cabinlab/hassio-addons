# Home Assistant API Integration Map for Claude Home

## Overview

This document maps all Home Assistant APIs that Claude Home can access with `hassio_api: true` permission, detailing endpoints, usage patterns, and implementation strategies.

## API Access Architecture

```
Claude Home Add-on
       ↓
   Supervisor API (`hassio_api: true`)
       ↓
   Proxy to Core API (`/core/api/*`)
       ↓
   Home Assistant Core
```

## Available API Endpoints

### 1. Supervisor Direct Endpoints

Base URL: `http://supervisor`
Authentication: `Authorization: Bearer ${SUPERVISOR_TOKEN}`

#### A. Add-on Self Information
```bash
GET /addons/self/info
```
- Returns: Current add-on configuration, version, state
- Use case: Verify Claude Home configuration at runtime

#### B. Core System Information
```bash
GET /core/info
```
- Returns: Home Assistant version, base_url, location info
- Use case: Adapt behavior based on HA version

```json
{
  "version": "2024.1.0",
  "version_latest": "2024.1.0",
  "update_available": false,
  "arch": "amd64",
  "machine": "qemux86-64",
  "ip_address": "172.30.32.1",
  "wait_boot": 600,
  "port": 8123,
  "ssl": true,
  "watchdog": true,
  "audio_input": null,
  "audio_output": null
}
```

#### C. Supervisor Information
```bash
GET /supervisor/info
```
- Returns: Supervisor version, diagnostics
- Use case: Check API compatibility

#### D. Host System Information
```bash
GET /host/info
```
- Returns: OS info, hardware details
- Use case: Understand system capabilities

### 2. Core API via Supervisor Proxy

Base URL: `http://supervisor/core/api`
Authentication: Same as Supervisor

#### A. Entity States
```bash
GET /core/api/states
```
- Returns: All entity states with attributes
- Use case: Primary source for context data

Response format:
```json
[
  {
    "entity_id": "light.living_room",
    "state": "on",
    "attributes": {
      "brightness": 254,
      "color_mode": "brightness",
      "friendly_name": "Living Room Light",
      "supported_features": 44
    },
    "last_changed": "2024-01-09T10:30:00+00:00",
    "last_updated": "2024-01-09T10:30:00+00:00",
    "context": {
      "id": "01HK3M4N5P6Q7R8S9T0UVWXYZ",
      "parent_id": null,
      "user_id": null
    }
  }
]
```

#### B. Single Entity State
```bash
GET /core/api/states/{entity_id}
```
- Returns: Specific entity state
- Use case: Refresh single entity without full fetch

#### C. Available Services
```bash
GET /core/api/services
```
- Returns: All available services by domain
- Use case: Service discovery for notifications

Response format:
```json
[
  {
    "domain": "notify",
    "services": {
      "persistent_notification": {
        "name": "Send a persistent notification",
        "description": "Show a notification...",
        "fields": {
          "message": {
            "name": "Message",
            "description": "Message body",
            "required": true
          }
        }
      }
    }
  }
]
```

#### D. Configuration
```bash
GET /core/api/config
```
- Returns: Core configuration including location, unit system
- Use case: Understand user preferences

Response includes:
```json
{
  "latitude": 32.87336,
  "longitude": 117.22743,
  "elevation": 430,
  "unit_system": {
    "length": "mi",
    "mass": "lb",
    "temperature": "°F",
    "volume": "gal"
  },
  "location_name": "Home",
  "time_zone": "America/Los_Angeles",
  "components": ["sensor.mqtt", "light.hue"],
  "config_dir": "/config",
  "whitelist_external_dirs": ["/config/www"],
  "version": "2024.1.0"
}
```

#### E. Error Log
```bash
GET /core/api/error_log
```
- Returns: Recent HA error logs
- Use case: Help debug user issues

#### F. Service Calls
```bash
POST /core/api/services/{domain}/{service}
```
- Body: Service data as JSON
- Use case: Send notifications, control entities

Example notification:
```json
{
  "message": "Claude Home: Task completed successfully",
  "title": "Claude Home"
}
```

### 3. WebSocket API (Advanced)

Connection: `ws://supervisor/core/api/websocket`
Authentication: After connection, send auth message

#### A. Subscribe to Events
```json
{
  "id": 1,
  "type": "subscribe_events",
  "event_type": "state_changed"
}
```
- Use case: Real-time context updates

#### B. Get Areas
```json
{
  "id": 2,
  "type": "config/area_registry/list"
}
```
- Returns: All areas with IDs and names
- Use case: Group entities by location

#### C. Get Devices
```json
{
  "id": 3,
  "type": "config/device_registry/list"
}
```
- Returns: Device registry with entity relationships
- Use case: Understand entity relationships

#### D. Get Entity Registry
```json
{
  "id": 4,
  "type": "config/entity_registry/list"
}
```
- Returns: Extended entity information including labels
- Use case: Access entity metadata not in states

### 4. Implementation Patterns

#### A. Bashio Library Usage
```bash
#!/usr/bin/with-contenv bashio

# Get all states
STATES=$(bashio::api.supervisor GET /core/api/states false)

# Get specific config value
UNIT_SYSTEM=$(bashio::api.supervisor GET /core/api/config false | jq -r '.unit_system.temperature')

# Call a service
bashio::api.supervisor POST /core/api/services/notify/persistent_notification \
  '{"message": "Hello from Claude Home"}'
```

#### B. Direct HTTP from Scripts
```bash
# Using curl with token
curl -X GET \
  -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  -H "Content-Type: application/json" \
  http://supervisor/core/api/states

# Using wget
wget -qO- \
  --header="Authorization: Bearer ${SUPERVISOR_TOKEN}" \
  http://supervisor/core/api/states
```

#### C. Python Implementation
```python
import os
import aiohttp

class HAApiClient:
    def __init__(self):
        self.token = os.environ.get('SUPERVISOR_TOKEN')
        self.base_url = 'http://supervisor'
        
    async def get_states(self):
        headers = {'Authorization': f'Bearer {self.token}'}
        async with aiohttp.ClientSession() as session:
            async with session.get(
                f'{self.base_url}/core/api/states',
                headers=headers
            ) as response:
                return await response.json()
    
    async def call_service(self, domain, service, data):
        headers = {
            'Authorization': f'Bearer {self.token}',
            'Content-Type': 'application/json'
        }
        async with aiohttp.ClientSession() as session:
            async with session.post(
                f'{self.base_url}/core/api/services/{domain}/{service}',
                headers=headers,
                json=data
            ) as response:
                return await response.json()
```

### 5. Rate Limiting and Best Practices

#### A. API Limits
- No documented hard rate limits
- Be respectful: ~1 request per second for states
- Batch operations when possible

#### B. Caching Strategy
```python
class CachedHAClient:
    def __init__(self, cache_duration=60):
        self.cache = {}
        self.cache_duration = cache_duration
        
    async def get_states_cached(self):
        cache_key = 'all_states'
        now = time.time()
        
        if cache_key in self.cache:
            cached_data, timestamp = self.cache[cache_key]
            if now - timestamp < self.cache_duration:
                return cached_data
        
        # Fetch fresh data
        data = await self.get_states()
        self.cache[cache_key] = (data, now)
        return data
```

#### C. Error Handling
```python
async def safe_api_call(self, endpoint):
    try:
        response = await self.session.get(endpoint)
        response.raise_for_status()
        return await response.json()
    except aiohttp.ClientError as e:
        logger.error(f"API call failed: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return None
```

### 6. Limitations with hassio_api

#### What We CAN Access:
- All entity states and attributes
- Service discovery and execution
- Core configuration
- Error logs
- System information
- Real-time events (via WebSocket)

#### What We CANNOT Access:
- Direct database queries
- User management (beyond read)
- Integration configuration
- Add-on management (other add-ons)
- Backup creation (need hassio_role: backup)
- System restart (need hassio_role: manager)

### 7. Security Considerations

1. **Token Management**
   - Never log or expose SUPERVISOR_TOKEN
   - Token rotates on add-on restart
   - Valid only within add-on container

2. **Data Sanitization**
   - Filter sensitive attributes (passwords, tokens)
   - Don't expose internal IPs or paths
   - Respect user privacy

3. **Input Validation**
   - Validate entity_ids before API calls
   - Sanitize service call data
   - Handle untrusted user input carefully

### 8. Advanced Use Cases

#### A. Entity Relationship Discovery
```python
async def get_related_entities(self, entity_id):
    # Get entity's device
    entity_reg = await self.get_entity_registry()
    entity = next((e for e in entity_reg if e['entity_id'] == entity_id), None)
    
    if not entity or not entity.get('device_id'):
        return []
    
    # Find all entities on same device
    related = [
        e['entity_id'] for e in entity_reg 
        if e.get('device_id') == entity['device_id']
    ]
    
    return related
```

#### B. Smart Notification Routing
```python
async def send_notification(self, message, priority='normal'):
    # Discover available services
    services = await self.get_services()
    notify_services = services.get('notify', {})
    
    # Priority routing
    if priority == 'critical' and 'mobile_app' in notify_services:
        service = 'mobile_app'
    elif 'notify' in notify_services:
        service = 'notify'
    else:
        service = 'persistent_notification'
    
    await self.call_service('notify', service, {'message': message})
```

#### C. Context-Aware API Calls
```python
async def get_active_entities(self, domains=None, areas=None):
    states = await self.get_states()
    
    # Filter by domain
    if domains:
        states = [s for s in states if s['entity_id'].split('.')[0] in domains]
    
    # Filter by area (requires entity registry)
    if areas:
        entity_reg = await self.get_entity_registry()
        area_entities = {
            e['entity_id'] for e in entity_reg 
            if e.get('area_id') in areas
        }
        states = [s for s in states if s['entity_id'] in area_entities]
    
    # Filter by activity (changed in last hour)
    one_hour_ago = datetime.now(UTC) - timedelta(hours=1)
    active_states = [
        s for s in states 
        if datetime.fromisoformat(s['last_changed']) > one_hour_ago
    ]
    
    return active_states
```

## Summary

The hassio_api permission provides comprehensive access to Home Assistant's state and configuration through the Supervisor proxy. While we cannot directly modify system configuration or manage other add-ons, we have everything needed to:

1. Build intelligent context from entity states
2. Discover and use notification services
3. Monitor system health and errors
4. React to real-time state changes
5. Group and filter entities intelligently

The key is to use these APIs efficiently with proper caching, error handling, and respect for system resources.