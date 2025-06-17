# Claude Home Configuration Analysis Task Package

## Objective
Analyze the Claude Home addon configuration holistically to optimize UX and token usage, focusing on how fields interrelate and leveraging Home Assistant native capabilities.

## Primary Questions to Answer

1. **Context Integration Architecture**
   - How should context_integration, context_domains, and context_max_entities work together?
   - What's the optimal way to select "important" entities rather than arbitrary limits?
   - How can we leverage HA's Areas, Labels, and entity importance indicators?

2. **Notification System Design**
   - How should ha_notifications and notification_service interact?
   - What events/activities should trigger notifications?
   - How can we use HA's native notification groups and channels?

3. **Token Optimization**
   - How do max_turns, context_max_entities, and context_domains affect token usage?
   - What's the relationship between model selection and these limits?
   - How can we intelligently reduce context based on the task at hand?

4. **Configuration Field Relationships**
   - Which fields should enable/disable others?
   - What are the logical groupings of configuration options?
   - How can we use HA's configuration schemas more effectively?

## Required Context Files

### From This Repository
```
/home/andrew/hassio-addons/claude-home/config.yaml
/home/andrew/hassio-addons/claude-home/translations/en.yaml
/home/andrew/hassio-addons/claude-home/run-simple.sh
/home/andrew/hassio-addons/claude-home/DOCS.md
/home/andrew/hassio-addons/claude-home/README.md
/home/andrew/hassio-addons/apcupsd/config.yaml  # Reference for good HA patterns
/home/andrew/hassio-addons/apcupsd/translations/en.yaml
```

### External Documentation to Research

1. **Claude Code Capabilities** (docs.anthropic.com/claude-code)
   - Memory management and context handling
   - Cost optimization strategies
   - Integration capabilities
   - Token usage patterns

2. **Home Assistant Core Documentation**
   - Entity Registry and importance: https://developers.home-assistant.io/docs/entity_registry_index
   - Context objects: https://developers.home-assistant.io/docs/dev_101_hass_components#context
   - Areas and Labels: https://www.home-assistant.io/docs/organizing/
   - Notification integrations: https://www.home-assistant.io/integrations/#notifications

3. **Home Assistant Addon Development**
   - Schema configuration: https://developers.home-assistant.io/docs/add-ons/configuration
   - Supervisor API: https://developers.home-assistant.io/docs/api/supervisor/endpoints
   - Best practices: https://developers.home-assistant.io/docs/add-ons/

4. **Research Sources** (in order of preference)
   - Home Assistant Community Forums (community.home-assistant.io)
   - Reddit r/homeassistant
   - Search for: "home assistant context api", "addon entity access", "supervisor api states"

## Specific Analysis Tasks

### 1. Context System Redesign
- Investigate how to query entity metadata (friendly_name, area_id, labels, last_changed)
- Design a scoring system for entity importance based on:
  - Recency of state changes
  - User-defined labels/areas
  - Entity domain priorities
  - Historical interaction patterns

### 2. Smart Context Reduction
- Design strategies to dynamically adjust context based on:
  - Current task type (automation, query, control)
  - Available tokens for selected model
  - Time of day / usage patterns

### 3. Configuration Schema Optimization
- Identify which options should be:
  - Required vs optional
  - Conditionally displayed
  - Grouped in the UI
  - Validated against HA state

### 4. Native Integration Points
- Map out all available Supervisor API endpoints we can use
- Identify what requires hassio_api vs homeassistant permissions
- Document any limitations or workarounds needed

## Deliverables

Create the following files in `/home/andrew/hassio-addons/dev-workspace/memory/`:

1. **CONFIG_REDESIGN.md** - Your complete configuration redesign proposal
2. **CONTEXT_ARCHITECTURE.md** - Detailed design for the context system
3. **API_INTEGRATION_MAP.md** - All HA APIs we should use and how
4. **TOKEN_OPTIMIZATION_GUIDE.md** - Strategies for reducing token usage
5. **QUESTIONS.md** - Any questions or clarifications needed

## Implementation Notes

- Prioritize Home Assistant native solutions over custom implementations
- Consider backward compatibility with existing configurations
- Think about progressive disclosure - basic vs advanced options
- Remember this runs in a Docker container with limited permissions

## Example Analysis: Max Context Entities

Current issue: "context_max_entities: 100" is arbitrary and doesn't consider:
- Which entities matter to the user
- How they relate to context_domains selection
- Token costs for different entity types
- Whether 100 climate entities provides less value than 20 mixed critical entities

Better approach might be:
- Score entities by importance
- Allow user to tag/label entities for Claude
- Dynamic limits based on model and task
- Context templates for common scenarios

## Final Notes

- Use Opus model for deep analysis
- Think holistically about the entire user journey
- Consider both new and experienced HA users
- Document any HA limitations you discover
- If something seems impossible, document the limitation and suggest alternatives

Place all findings in `/home/andrew/hassio-addons/dev-workspace/memory/` for review.