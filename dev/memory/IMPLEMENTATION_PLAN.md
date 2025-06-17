# Claude Home Context Implementation Plan

Based on the excellent analysis provided, here's our implementation plan:

## Phase 1: Core Context System (v1.5.0)

### 1. Update Configuration Schema

```yaml
# config.yaml changes
options:
  claude_model: "haiku"
  context_mode: "smart"  # NEW - replaces context_integration
  auto_claude: false
  enable_notifications: false  # Renamed from ha_notifications
  
schema:
  claude_model: "list(haiku|sonnet|opus)"
  context_mode: "list(none|minimal|smart|full)"  # Start without 'custom'
  auto_claude: "bool?"
  enable_notifications: "bool?"
```

### 2. Implement Entity Scoring

Create `/scripts/context-manager.sh`:
```bash
#!/usr/bin/with-contenv bashio

# Fetch all states
fetch_states() {
    bashio::api.supervisor GET /core/api/states false
}

# Score entities based on relevance
score_entities() {
    # Implementation based on the scoring algorithm
    # Output: sorted list of entity IDs with scores
}

# Build context string with token limit
build_context() {
    local mode=$1
    local max_tokens=$2
    
    case "$mode" in
        "minimal")
            # Only critical entities
            ;;
        "smart")
            # Use scoring algorithm
            ;;
        "full")
            # All entities up to token limit
            ;;
    esac
}
```

### 3. Update run-simple.sh

Add context fetching:
```bash
# Get context mode
CONTEXT_MODE=$(bashio::config 'context_mode' 'smart')

if [ "$CONTEXT_MODE" != "none" ]; then
    bashio::log.info "Fetching Home Assistant context..."
    
    # Determine token budget based on model
    case "$CLAUDE_MODEL" in
        "claude-3-5-haiku-20241022")
            TOKEN_BUDGET=3000
            ;;
        "sonnet")
            TOKEN_BUDGET=8000
            ;;
        "default")
            TOKEN_BUDGET=15000
            ;;
    esac
    
    # Fetch and prepare context
    HA_CONTEXT=$(./scripts/context-manager.sh "$CONTEXT_MODE" "$TOKEN_BUDGET")
    
    # Save context to file for Claude to access
    echo "$HA_CONTEXT" > /tmp/ha_context.txt
    
    # Set environment variable
    export CLAUDE_HA_CONTEXT="/tmp/ha_context.txt"
fi
```

### 4. Migration Logic

Add to run-simple.sh:
```bash
# Migrate old configuration
if bashio::config.exists 'context_integration'; then
    if [ "$(bashio::config 'context_integration')" = "true" ]; then
        CONTEXT_MODE="smart"
        bashio::log.warning "Migrated context_integration to context_mode: smart"
    else
        CONTEXT_MODE="none"
    fi
fi
```

## Phase 2: Enhanced UX (v1.6.0)

### 1. Update Translations

```yaml
# translations/en.yaml
configuration:
  context_mode:
    name: "Home Assistant Context"
    description: "How much of your HA data Claude can access"
    options:
      none: "No Access - Claude works without HA data"
      minimal: "Minimal - Only essential devices (lights, locks, climate)"
      smart: "Smart - Automatically selected relevant entities (Recommended)"
      full: "Full Access - All entities (high token usage)"
```

### 2. Add Token Usage Indicator

Show estimated token usage in startup banner:
```bash
echo "             Context: $CONTEXT_MODE (~$ESTIMATED_TOKENS tokens)"
```

### 3. Add Context Preview Command

Create a bash function users can run:
```bash
# In startup script
claude_context() {
    echo "Current context mode: $CONTEXT_MODE"
    echo "Entities included: $(cat /tmp/ha_context.txt | grep -c 'entity_id')"
    echo "Estimated tokens: $ESTIMATED_TOKENS"
    echo ""
    echo "First 10 entities:"
    head -20 /tmp/ha_context.txt
}
```

## Phase 3: Testing Plan

### 1. Test Scenarios

1. **Small Setup** (10 entities)
   - Verify all entities included in minimal mode
   - Check smart mode doesn't over-filter

2. **Medium Setup** (100 entities)
   - Verify smart selection works
   - Check token limits enforced

3. **Large Setup** (500+ entities)
   - Verify performance is acceptable
   - Check memory usage
   - Verify token limits prevent overload

### 2. Test Script

Create `test-context.sh`:
```bash
#!/bin/bash
# Test context generation with different modes

for mode in none minimal smart full; do
    echo "Testing mode: $mode"
    time ./scripts/context-manager.sh "$mode" 5000
    echo "---"
done
```

## Implementation Timeline

- **Week 1**: Implement basic context modes and scoring
- **Week 2**: Add migration and token counting
- **Week 3**: Testing and refinement
- **Week 4**: Documentation and release prep

## Success Criteria

1. Context generation < 2 seconds for 500 entities
2. Token usage reduced by 50% in smart mode vs full
3. Zero breaking changes for existing users
4. Clear documentation for new context modes

This plan implements the MVP while laying groundwork for future enhancements.