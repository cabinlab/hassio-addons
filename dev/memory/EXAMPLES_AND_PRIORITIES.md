# Examples and Priorities for Analysis

## Concrete Use Cases to Consider

### Use Case 1: "Help me debug why my heating isn't working"
- Needs: climate entities, recent automation traces, error logs
- Doesn't need: All 500 sensors in the house
- Token impact: High-value focused context

### Use Case 2: "Create an automation for my lights"
- Needs: light entities, areas/rooms, existing automations
- Doesn't need: Climate sensors, media players
- Token impact: Domain-specific context

### Use Case 3: "What's the status of my home?"
- Needs: Summary of important entities across domains
- Doesn't need: Deep historical data
- Token impact: Breadth over depth

## Priority Improvements

### HIGH Priority
1. **Smart Context Selection**
   - Use entity attributes like `last_changed`, `last_updated`
   - Prioritize entities that change frequently
   - Consider entity relationships (device -> area -> floor)

2. **Token Budget System**
   - Show estimated tokens before sending to Claude
   - Warn when approaching limits
   - Suggest model changes based on context size

### MEDIUM Priority  
1. **Conditional Configuration**
   - Show notification_service only if ha_notifications is true
   - Show context options only if context_integration is true
   - Group related fields visually

2. **Preset Templates**
   - "Minimal" - Just essential entities
   - "Automation Helper" - Relevant domains for automation
   - "Full Access" - Everything available
   - "Custom" - Current detailed options

### LOW Priority
1. **Historical Patterns**
   - Learn which entities user asks about
   - Auto-adjust context over time
   - Save preferences per task type

## Anti-Patterns to Avoid

1. **Don't** create custom state storage/caching
   - Use HA's built-in state machine
   
2. **Don't** poll APIs repeatedly
   - Get context once at conversation start
   
3. **Don't** send raw JSON entity dumps
   - Format for human/LLM readability

4. **Don't** hardcode entity lists
   - Always discover dynamically

## Questions to Explore

1. Can we use HA's Areas to group context logically?
2. Can we access entity metadata like "importance" or custom attributes?
3. Is there a way to get "related entities" through the API?
4. Can we use HA's built-in categories/labels system?
5. Should context update during long conversations?

## Reference Patterns from HA Core

Look for how Home Assistant itself handles:
- The "Related" tab in entity details
- Area assignment and grouping  
- Entity categories (diagnostic vs primary)
- The states UI filtering system
- Voice assistant context exposure