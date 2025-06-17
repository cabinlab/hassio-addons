# Current Claude Home Configuration State

## Implemented Features

### Working
1. **Model Selection** - Maps display names to Claude CLI values
2. **Theme Selection** - Terminal themes (not yet connected to actual theme engine)
3. **Auto-start Claude** - Launches Claude CLI automatically vs bash shell
4. **Notification Service** - Dropdown selection with service discovery on startup

### Partially Implemented
1. **HA Notifications** - Boolean flag exists but no notification logic implemented
2. **Service Discovery** - Queries /core/api/services for notify domain services

### Not Implemented
1. **Context Integration** - Boolean flag with no functionality
2. **Context Domains** - String field storing comma-separated domains
3. **Context Max Entities** - Integer limit with no actual limiting logic
4. **Verbose Logging** - Boolean with no effect on logging
5. **Max Turns** - Integer with no enforcement
6. **Disable Telemetry** - Boolean not passed to Claude
7. **Terminal Bell** - Boolean with no terminal configuration

## Current Permissions
- `hassio_api: true` - Can access Supervisor API endpoints
- No `homeassistant` permission - Cannot directly access HA API

## Available APIs (with hassio_api)
- `/core/api/services` - Get service list (currently used)
- `/core/api/states` - Get entity states (not used yet)
- `/core/api/config` - Get HA configuration (not used)
- `/core/api/events` - WebSocket for events (not used)
- `/core/api/error_log` - Get HA logs (not used)

## Current UX Issues
1. Radio buttons show for ≤5 options (HA default behavior)
2. Dropdowns show for >5 options
3. No conditional field visibility
4. No field grouping in UI
5. Mix of critical and optional fields at same level

## Token Usage Concerns
1. No awareness of token costs per model
2. Context could include hundreds of entities
3. No filtering of stale/unchanging entities
4. No task-based context adjustment
5. Full entity state objects vs summaries

## Configuration Philosophy Questions
1. Should we hide advanced options by default?
2. How much should we automate vs expose?
3. What's the balance between power and simplicity?
4. Should context be automatic or manually configured?