# Claude Home: Architecture & Future Directions

**Created:** June 13, 2025  
**Updated:** June 14, 2025
**Purpose:** A complete Home Assistant development environment combining Claude Code, SSH, chat UI, and multi-provider support

## Implementation Decision: Gateway + Anse

After evaluation, we're using:
- **Chat MCP Gateway** - Lightweight Python service providing OpenAI-compatible API with Claude/OpenAI fallback
- **Anse** - Production-ready chat UI with mobile PWA support, image uploads, and chat history

This approach minimizes development effort while providing all required features.

## Problems We're Solving

### 1. Authentication Mismatch
- HA users pay for Claude subscriptions ($20-$200/month) but can't use them with HA
- HA Anthropic integration requires expensive API keys
- Users frustrated: "I'm already paying for Claude, why doesn't it work?"

### 2. Terminal UX on Mobile
- Terminal-in-iframe-in-HA is unusable on mobile
- Most HA debugging happens on phones
- Current addon essentially desktop-only

### 3. Rate Limit Cliff
- Claude Pro users hit rate limits quickly with Opus
- No graceful fallback when limits hit
- 2am broken automation = angry spouse + rate limited Claude

### 4. Internet Dependency
- No offline fallback for off-grid/unreliable connections
- Complete failure when internet drops

### 5. Container Access Limitations
- Need to install Node+Claude in every container for debugging
- No way to reach into lightweight containers
- Duplicated tooling across containers

## Core Features Needed

### 1. Dual Interface
- **Terminal**: Keep existing for power users
- **Chat**: New mobile-friendly interface for common tasks

### 2. Smart Provider Fallback
```yaml
providers:
  1. Claude OAuth (existing subscription)
  2. OpenAI-compatible endpoint (covers everything):
     - OpenAI API
     - OpenRouter (100+ models)
     - Local models (Ollama/LM Studio)
     - Any compatible endpoint
```

### 3. WebSocket-Based Schema Caching
- Use HA WebSocket API to cache schema structure
- Claude Code builds pseudo-GraphQL queries against cached data
- Schema updates automatically when structure changes

### 4. Smart Context Management
The HA API returns massive amounts of data. We need intelligent filtering:

**Query-Aware Context Selection**
```python
# Pseudo-code
if "light" in user_question:
    context.add(get_entities(domain="light"))
elif "automation" in user_question and "bedroom" in user_question:
    context.add(get_automations(filter="bedroom"))
elif error_detected:
    context.add(get_recent_logs(minutes=5))
```

**Progressive Disclosure**
```python
# Start minimal
entity_data = {
    "entity_id": entity.id,
    "state": entity.state,
    "last_changed": entity.last_changed
}

# Expand if needed
if needs_attributes:
    entity_data["attributes"] = filter_relevant_attributes(entity)
```

**Token Budget Management**
- Set max context size (e.g., 2000 tokens)
- Prioritize most relevant data
- Summarize when needed (e.g., "147 more sensors available")
- Let user request specific expansions

**Smart Defaults by Query Type**
- "Fix this automation" → Include YAML, recent logs, related entities
- "Why is X unavailable?" → Include entity history, related devices, errors
- "How do I..." → Minimal context, mostly instructional

**GraphQL-like Approach**
Instead of fetching everything and filtering, request exactly what's needed:

```javascript
// Build query based on user's question
const query = {
  entities: {
    filter: { domain: "light", area: "bedroom" },
    fields: ["entity_id", "state", "attributes.brightness"]
  },
  logs: {
    filter: { level: "ERROR", last: "5m" },
    fields: ["timestamp", "message"]
  }
};

// Returns only requested data
const context = await haQuery(query);
```

**Real-world Implementation Options:**

**Option 1: GraphQL-to-WebSocket Adapter (Lightest)**
```javascript
// Not actual GraphQL, just GraphQL-like syntax
async function haQuery(query) {
  const results = {};
  
  if (query.entities) {
    // Use cached schema to build efficient WebSocket queries
    const entities = await queryCachedEntities(query.entities);
    results.entities = entities;
  }
  
  if (query.logs) {
    const logs = await queryCachedLogs(query.logs);
    results.logs = logs;
  }
  
  return results;
}
```

**Option 2: GraphQL Schema with WebSocket Resolver**
```javascript
// Using graphql-js or similar lightweight lib
const schema = buildSchema(`
  type Query {
    entities(filter: EntityFilter, fields: [String]): [Entity]
    logs(filter: LogFilter): [LogEntry]
  }
`);

// Resolvers use cached WebSocket data
const resolvers = {
  entities: async (args) => {
    const cached = await getCachedEntities();
    return filter(cached, args);
  }
};
```

**Option 3: JSON Query Language (Simplest)**
```javascript
// Skip GraphQL entirely, use simple JSON queries
const query = {
  "entities": ["light.bedroom", "sensor.bedroom_motion"],
  "logs": { "level": "error", "count": 10 },
  "automations": { "contains": "bedroom" }
};

// Simple function maps to cached WebSocket data
const data = await queryCachedData(query);
```

**Recommendation: GraphQL Syntax Without the Library**

Use GraphQL syntax (which both Claude Code and OpenAI understand) but skip the heavyweight libraries:

```javascript
// Both Claude Code and OpenAI write GraphQL using cached schema structure
const query = `{
  entities(domain: "light", area: "bedroom") {
    entity_id
    state
    attributes {
      brightness
      color_temp
    }
  }
  automations(contains: "bedroom") {
    alias
    last_triggered
  }
}`;

// Simple parser converts to JSON (100 lines, not 500KB)
const jsonQuery = parseGraphQLSyntax(query);

// Process with cached WebSocket data
const data = await queryCachedData(jsonQuery);
```

**The Token Efficiency Problem Solved:**

Current approaches are inefficient:
- **hass-mcp**: Fixed 4 properties, can't customize what you get
- **Direct HA REST API**: ~20 properties per entity, massive token waste

Our approach: **Choose exactly what you need from cached schema**
```javascript
// User: "Why is my bedroom light dim?"
// Provider knows from schema that lights have brightness attribute
// Provider requests exactly what's needed:
{
  entities(entity_id: "light.bedroom_main") {
    state
    attributes {
      brightness
      friendly_name
    }
  }
}
// Returns only those 3 fields → efficient + targeted
```

**HA-Generated Schema for Discovery**

Home Assistant generates a lightweight **structure schema** (not individual entities):

```javascript
// /config/claude-config/ha-schema.json (auto-generated structure)
{
  "generated": "2025-06-13T10:00:00Z",
  "domains": {
    "light": {
      "common_attributes": ["brightness", "color_temp", "rgb_color", "supported_features"],
      "naming_pattern": "light.{area}_{function}"
    },
    "sensor": {
      "common_attributes": ["unit_of_measurement", "device_class", "state_class"],
      "naming_pattern": "sensor.{area}_{type}"
    },
    "climate": {
      "common_attributes": ["temperature", "target_temperature", "hvac_mode", "hvac_action"],
      "naming_pattern": "climate.{area}"
    }
  },
  "areas": ["bedroom", "kitchen", "living_room", "garage", "outdoor"],
  "websocket_types": ["get_states", "call_service", "get_history", "get_logbook"]
}
```

**Why Structure-Only Schema:**
- **Entities change frequently** (especially when Claude helps configure HA)
- **Structure is stable** (light domains don't suddenly get new attribute types)
- **Cached entity discovery** via WebSocket data using structure knowledge
- **Both providers know what's possible** without needing current entity lists
- **Schema updates automatically** when Claude actions modify HA structure

**HA Config Directory Tree**

Home Assistant also generates a directory structure overview:

```
# /config/claude-config/ha-tree.txt (auto-generated)
/config/
├── configuration.yaml (2.3KB)
├── automations.yaml (15.2KB)
├── scripts.yaml (8.7KB)
├── scenes.yaml (3.1KB)
├── secrets.yaml (exists)
├── customize.yaml (1.2KB)
├── groups.yaml (4.5KB)
├── .storage/
│   ├── lovelace (118.3KB)
│   ├── auth (exists)
│   └── core.entity_registry (245.7KB)
├── custom_components/
│   ├── hacs/ (integration)
│   ├── browser_mod/ (integration)
│   └── mushroom/ (integration)
├── packages/
│   ├── climate.yaml (5.2KB)
│   ├── security.yaml (8.9KB)
│   └── lighting.yaml (12.1KB)
├── www/
│   ├── community/
│   └── images/
└── blueprints/
    ├── automation/
    └── script/
```

**Context Generation for Standalone Mode**

Since HA can't see the container filesystem in standalone mode:

```javascript
// Container generates its own context on startup
async function generateContext() {
  const context = {};
  
  // If HA is accessible, connect WebSocket and cache schema
  if (HA_URL && HA_TOKEN) {
    await connectWebSocket();
    context.haSchema = await getCachedSchema();
  }
  
  // Generate local directory tree (container has filesystem access)
  if (WORKING_DIR === '/config') {
    context.configTree = await generateDirectoryTree('/config');
  }
  
  // Save combined context
  fs.writeFileSync('/tmp/context.json', JSON.stringify(context));
}

// Or split responsibilities:
// - WebSocket provides: entity schema, areas, automations list (cached)
// - Container generates: directory tree, file stats, config structure
// - Both saved to claude-config/ for persistence
```

**Multi-Provider Schema Usage**

Both Claude Code and OpenAI fallbacks use the same cached HA schema structure:

**Claude Code Flow:**
1. Reads cached WebSocket schema (knows light.brightness exists)
2. User asks about dim light → writes targeted pseudo-GraphQL query
3. System executes query against cached data → returns only brightness + state
4. Claude responds with specific diagnosis
5. If Claude modifies HA structure → WebSocket updates cached schema

**OpenAI Fallback Flow:**
1. Reads same cached WebSocket schema (same knowledge)
2. User asks about dim light → writes same targeted pseudo-GraphQL query  
3. System executes same query against cached data → returns same minimal data
4. OpenAI responds using efficient context
5. If OpenAI modifies HA structure → WebSocket updates cached schema

**Result:** Both providers are equally token-efficient because they both know the HA structure and can request exactly what they need.

**Complete Environment Context**

Fresh AI agents get comprehensive environment understanding through **two cached components**:

**1. HA Schema** (what's possible):
- Entity domains and their attributes
- Available APIs and endpoints  
- Areas and naming patterns

**2. Directory Tree** (what exists):
- Config file structure and sizes
- Custom components and integrations
- Package organization

**Result:** New agent understands environment in ~100 tokens instead of ~1000 tokens of exploration.

**Example Fresh Agent Context:**
```
From schema: "This HA has lights with brightness/color_temp, climate with hvac_mode"
From tree: "Config uses packages/, has browser_mod integration, 15KB automations.yaml"
Agent: "I understand the environment structure and can help efficiently"
```

**Benefits:**
- Both providers understand GraphQL syntax naturally
- No large GraphQL libraries needed
- Structure schema provides discovery without token waste
- Directory tree prevents filesystem exploration waste
- Simple parser is maintainable
- Context generation adapts to deployment mode
- **Token efficiency parity** between Claude Code and fallback providers

**Example Flow:**
```
User: "Why is my bedroom light not turning on?"

Claude: [Builds query]
{
  entities: {
    filter: { entity_id: "light.bedroom" },
    fields: ["state", "last_changed", "attributes.supported_features"]
  },
  related_entities: {
    filter: { area: "bedroom", domain: ["switch", "sensor"] },
    fields: ["entity_id", "state"]
  },
  automations: {
    filter: { references: "light.bedroom" },
    fields: ["alias", "last_triggered", "mode"]
  }
}

System: [Returns only that data]

Claude: "I see the issue. The light is unavailable because..."
```

**Benefits:**
- Claude knows what data it needs to answer the question
- No wasted tokens on irrelevant data
- Dynamic and contextual
- Claude can request more data if needed

### 5. Image Support
- Screenshots >>> lengthy explanations
- Essential for UI/dashboard debugging
- "This button is broken" + screenshot = instant fix

### 6. SSH Access
- Direct container debugging without installing Claude everywhere
- Reach into lightweight deployments for fixes
- Standard SSH key management
- Compatible with existing workflows

## Architecture Approach

### Gateway + Anse Architecture
Instead of building complex provider logic, we use a two-component approach:

1. **Chat MCP Gateway** - A lightweight Python service that:
   - Provides OpenAI-compatible API endpoint
   - Handles multi-provider logic (Claude Code → OpenAI fallback)
   - Runs alongside ttyd in the container (~10MB, <50MB RAM)
   - Spawns Claude CLI when available, falls back to OpenAI API

2. **Anse Chat UI** - A production-ready chat interface that:
   - Connects to the gateway's OpenAI endpoint
   - Provides beautiful mobile-first UI
   - Supports image uploads and markdown
   - Stores chat history locally
   - PWA-ready for mobile use

### How It Works

```
┌─────────────┐     HTTP/SSE      ┌──────────────┐
│   Anse UI   │ ───────────────> │ Chat Gateway │
│(Mobile PWA) │                   │              │
└─────────────┘                   │ • OpenAI API │
                                  │ • Fallback   │
                                  └──┬────────┬──┘
                                     │        │
                          Claude CLI │        │OpenAI API
                                     ▼        ▼
```

### Gateway Implementation
The gateway handles all provider complexity:

```python
# When Claude Code is available
if self.claude_available:
    # Use Anthropic SDK (available in Claude Code environment)
    from anthropic import AsyncAnthropic
    client = AsyncAnthropic()
    # Make request using Claude's native capabilities

# Fallback to OpenAI
else:
    # Standard OpenAI API call
    await httpx.post("https://api.openai.com/v1/chat/completions")
```

### Chat UI Integration
Anse configuration is simple:

```javascript
// Point Anse's OpenAI provider to local gateway
const config = {
  providers: {
    openai: {
      endpoint: "http://localhost:8000/v1/chat/completions",
      // No API key needed - gateway handles auth
    }
  }
}
```

### Implementation Strategy
1. **Add Chat MCP Gateway** - Minimal Python service in container
2. **Build Anse** - During container build, output ~20-30MB of static files
3. **Configure Anse** - Point to local gateway endpoint
4. **Serve alongside ttyd** - Both services in single container
5. **No custom development** - Both components work out of the box

### Benefits of Gateway + Anse Approach

**Separation of Concerns:**
- Gateway handles all provider complexity
- Anse focuses on excellent UI/UX
- Each component does one thing well

**Minimal Integration Work:**
- Anse already supports OpenAI endpoints
- Gateway provides OpenAI-compatible API
- No custom provider development needed

**Future Flexibility:**
- Can swap Anse for any OpenAI-compatible UI
- Gateway improvements benefit any connected UI
- Easy to add new providers to gateway

**Resource Efficiency:**
- Gateway: ~10MB container, <50MB RAM
- Anse: ~20-30MB static files
- Total overhead: ~30-40MB (vs 256MB for MongoDB)

**Production Quality:**
- Both components are tested and maintained
- Anse provides polished mobile experience
- Gateway handles edge cases and fallbacks

### What We're NOT Building
- Custom chat framework (using Anse)
- Complex provider logic (gateway handles it)
- Stream normalization code (gateway provides standard API)
- New authentication systems (reuse existing)
- Supervisor-dependent architecture
- Separate SSH addon (we ARE building SSH)

## Success Criteria

1. **Pro subscription users** can actually use their Claude for HA
2. **Mobile users** can debug without terminal frustration
3. **Rate-limited users** have automatic fallback options
4. **Offline users** can fall back to local models
5. **Power users** keep full terminal access

## Key Insights

### Chat Users (80%)
Just need:
- "Fix this YAML"
- "Why isn't this working?"
- "How do I make lights turn on at sunset?"

Not complex terminal sessions. A simple chat that understands HA context would transform the addon from "power user tool" to "everyone's HA assistant."

### Power Users (20%)
Need:
- Terminal access for deep dives
- SSH to debug other containers
- Direct filesystem access
- Full development environment

The "Dev Container" vision serves both audiences with mode switching.

## Standalone-First Architecture

### The Shift
**From:** Home Assistant Addon that only works in supervised environments  
**To:** Standalone container that adapts to HA when present

### Why Standalone-First
1. **Development** - Test without full HA stack
2. **Deployment flexibility** - Run on any Docker host
3. **No supervisor lock-in** - Direct HA API access
4. **Advanced deployments** - Kubernetes, Docker Compose, etc.
5. **Off-grid/resilient** - Power-aware scaling without supervisor constraints

### Implementation
```bash
# Environment detection
if [ -n "$SUPERVISOR_TOKEN" ]; then
    # Supervised addon mode
    HA_URL="http://supervisor/core"
    HA_TOKEN="$SUPERVISOR_TOKEN"
else
    # Standalone mode with direct HA access
    HA_URL="${HA_URL:-http://homeassistant.local:8123}"
    HA_TOKEN="${HA_TOKEN}"  # From env or config
fi
```

### Benefits
- **Same container** works everywhere
- **Direct HA API** instead of supervisor proxy
- **User controls deployment** (docker run, compose, k8s)
- **Simpler testing** and development
- **Enables resilient setups** (scaling, redundancy)

## Technical Implementation Notes

### Claude Code Native Capabilities
- **Built-in streaming**: `--output-format=stream-json --verbose` provides structured output
- **Session management**: Automatic session IDs and conversation tracking  
- **Tool integration**: MCP servers and native tools available to chat interface
- **Cost tracking**: Real-time token usage and cost information
- **Authentication**: Existing OAuth system works for chat interface

### Stream Processing Benefits
- **Real-time responses**: Both providers stream content progressively
- **Unified interface**: Same chat UI handles Claude Code and OpenAI formats
- **Cost transparency**: Claude Code provides detailed usage metrics
- **Error handling**: Structured JSON enables proper error processing
- **Provider switching**: Seamless fallback without UI changes

### Schema-Driven Context Efficiency  
- **Event-driven updates**: WebSocket automatically refreshes HA schema when integrations change
- **WebSocket caching**: Use HA WebSocket API for schema generation and maintenance
- **Targeted queries**: Both providers use same cached schema for efficient pseudo-GraphQL queries
- **Token optimization**: GraphQL-like syntax minimizes context size
- **Auto-update cycle**: Claude actions that modify HA structure trigger schema refresh

## Claude Code for Home: The Complete Vision

### Core Components

1. **Claude Code Terminal** (existing)
   - Full Claude CLI access
   - MCP integration
   - OAuth authentication
   - Terminal-based workflows

2. **Chat Interface** (Anse)
   - Beautiful mobile-first PWA UI
   - Quick Q&A for common tasks
   - Image upload support built-in
   - Chat history with IndexedDB
   - Connects to local gateway

3. **SSH Server** (new)
   - OpenSSH with key management
   - Reach into other containers
   - Standard port 22 access
   - Compatible with all SSH clients

4. **Chat MCP Gateway** (handles routing)
   - Provides OpenAI-compatible API
   - Claude Code → OpenAI fallback
   - Automatic switching on rate limits
   - Supports local models (Ollama)
   - ~10MB footprint

5. **Smart Context Engine** (new)
   - GraphQL-like query syntax
   - Token-efficient HA data access
   - Progressive disclosure
   - Query-aware filtering

### Use Cases

**"Fix my broken automation"**
- Chat: Upload screenshot, get fix
- Terminal: Deep dive with Claude Code
- SSH: Debug the container directly

**"Container X is misbehaving"**
- SSH into container
- Use Claude to analyze logs
- Fix without installing Node+Claude there

**"Build a new integration"**
- Terminal for development
- Chat for quick questions
- SSH for testing in other containers

**"3am emergency, internet is down"**
- Fallback to local Ollama
- Still get AI assistance
- Core functionality preserved

### Why This Makes Sense

1. **We already have Node.js** - Use it fully
2. **We already have ttyd** - Terminal is solved
3. **OpenSSH is tiny** - ~5MB addition
4. **Chat is Anse static files + gateway** - ~30-40MB total overhead
5. **One container > three containers** - Less resource usage
6. **Unified auth and config** - Better UX
7. **Power users get everything** - No compromises
8. **Casual users get simplicity** - Easy chat interface

### Implementation Priorities

**Phase 0: Schema System (Foundation)**
- WebSocket connection to HA for schema caching
- Auto-refresh schema when Claude modifies HA structure
- Directory tree caching
- Pseudo-GraphQL query parser against cached data (200-300 lines replaces 1200+ line hass-mcp-lite)

**Phase 1: Chat Interface (Core Value)**
- Add Chat MCP Gateway to container (~10MB)
- Build and integrate Anse UI (~20-30MB)
- Configure Anse to use local gateway endpoint
- Serve Anse alongside ttyd
- Test mobile PWA functionality

**Phase 2: Gateway Enhancement (Resilience)**
- Gateway already handles Claude → OpenAI fallback
- Add support for additional providers (OpenRouter, local models)
- Enhance rate limit detection
- Add cost tracking and optimization
- Improve error handling and retry logic

**Phase 3: SSH Integration (Power Users)**
- OpenSSH server with key management
- Container debugging capabilities
- Integration with existing workflows
- Completes dev environment vision

**Phase 4: Advanced Features (Polish)**
- Image upload support for chat interface
- Advanced context management
- Performance optimization
- Unified terminal/chat UI

## Future Directions & Challenges

### Chat Interface Approval Flow Challenge

**Current State (v2.3.4):**
- Claude Code requires interactive approval for file edits
- Chat interface can't handle these prompts yet
- Fallback providers (OpenAI) have no built-in safety

**Problem:** Users need emergency fixes on mobile when rate-limited, but can't safely make changes without approval flow.

### Potential Solutions

#### 1. PTY Wrapper with Approval Forwarding (Claude Only)
```python
# Intercept Claude's prompts and forward to chat UI
child = pexpect.spawn('claude "Fix my automation"')
# When "(y/n)" appears, send to chat for user approval
```
**Pros:** Works with existing Claude Code  
**Cons:** Only works for Claude, not fallbacks

#### 2. Universal Action Parser
```python
# Parse ALL provider responses for dangerous actions
actions = extract_file_edits(response)
approved = await get_user_approval(actions)
```
**Pros:** Works for all providers  
**Cons:** Complex parsing, might miss edge cases

#### 3. OpenCode Integration
[OpenCode](https://github.com/opencode-ai/opencode) is an open-source Claude Code alternative that:
- Works with multiple LLM providers (OpenAI, Anthropic, local)
- Has built-in approval flows
- Supports MCP servers
- Could be our fallback instead of raw OpenAI API

**Integration approach:**
```python
if rate_limited:
    # Use OpenCode with OpenAI backend
    cmd = ["opencode", "--model", "gpt-4", prompt]
else:
    # Use Claude Code
    cmd = ["claude", prompt]
```

**Pros:** 
- Consistent approval UX across providers
- Emergency fixes work safely
- Less code to maintain

**Cons:**
- Another dependency
- Need to verify PTY wrapper compatibility

#### 4. Structured Fix Format
Train fallback LLMs to return fixes in parseable format:
```
FIX_START
type: file_edit
path: /config/automations.yaml
line: 47
old: platfrom: state
new: platform: state  
FIX_END
```
Then show fixes with [Apply] buttons in chat UI.

**Pros:** Safe, clear, works with any LLM  
**Cons:** Requires prompt engineering, not as seamless

### Recommendation

Short term: Document current limitations  
Medium term: Implement structured fix format for fallbacks  
Long term: Evaluate OpenCode integration for consistent experience