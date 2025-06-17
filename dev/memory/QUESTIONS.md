# Questions and Clarifications for Claude Home Configuration Redesign

## Technical Questions

### 1. WebSocket API Access
**Question**: Can we reliably use the WebSocket API through the Supervisor proxy for real-time updates and advanced queries like entity registry?

**Context**: The documentation mentions WebSocket access but it's not clear if it works reliably through `ws://supervisor/core/api/websocket` or if there are authentication challenges.

**Impact**: This affects our ability to:
- Get real-time state updates
- Access entity labels and categories
- Query area and device relationships

### 2. Entity Labels Access
**Question**: Are entity labels accessible through the `/core/api/states` endpoint or do we need the entity registry?

**Context**: Labels would be perfect for users to mark entities as "claude_important" or "claude_ignore" but it's unclear if they're included in standard state queries.

**Impact**: Determines if we can implement user-controlled entity prioritization easily.

### 3. Performance Limits
**Question**: Are there any rate limits or performance concerns when fetching all states repeatedly?

**Context**: A large HA installation might have 500+ entities. Fetching all states could be a heavy operation.

**Impact**: Affects our caching strategy and update frequency recommendations.

## Design Decisions

### 4. Context Update Strategy
**Question**: Should context remain static during a conversation or update dynamically?

**Options**:
1. **Static** (current plan): Fetch once at start, more predictable
2. **Dynamic**: Update every N turns or on demand
3. **Hybrid**: Update only when user asks about current state

**Trade-offs**: Token usage vs accuracy vs complexity

### 5. Default Context Mode
**Question**: What should be the default context mode for new users?

**Options**:
1. **"smart"**: Automatic selection (current plan)
2. **"minimal"**: Start small, let users opt into more
3. **"none"**: No context until explicitly enabled

**Considerations**: First-time user experience vs immediate value

### 6. Token Warning Thresholds
**Question**: At what token usage level should we warn users?

**Current thinking**:
- Haiku: Warn at 3,000 tokens/conversation
- Sonnet: Warn at 8,000 tokens/conversation  
- Opus: Warn at 15,000 tokens/conversation

**Need input**: Are these reasonable based on typical usage patterns?

## Implementation Clarifications

### 7. Backwards Compatibility
**Question**: How important is maintaining exact compatibility with existing configurations?

**Current plan**: Map old fields to new ones transparently
**Alternative**: Force migration with clear upgrade instructions

**Impact**: User experience during upgrade

### 8. Custom Scoring Functions
**Question**: Should we expose the entity scoring algorithm for power users to customize?

**Pros**: Ultimate flexibility
**Cons**: Complexity, support burden, potential for errors

**Proposal**: Start with fixed algorithm, add customization later if requested

### 9. Multi-Language Support
**Question**: How should natural language compression work for non-English users?

**Current**: English-only descriptions
**Options**: 
1. Use HA's translation system
2. Keep technical format for non-English
3. Add translation configuration

## Limitations Discovered

### 10. Missing API Capabilities
**Finding**: We cannot access certain useful data with hassio_api:

- User preferences and frontend settings
- Integration-specific configuration
- Historical state data (only current states)
- Direct database queries
- Custom component data

**Question**: Should we document these as "future enhancements pending API access" or find workarounds?

### 11. Area Assignment Gaps
**Finding**: Not all entities have area assignments, especially:
- Helper entities
- Integration-provided sensors
- Virtual/calculated entities

**Question**: How should we handle entities without area context?

### 12. Device Relationship Complexity
**Finding**: Entity-to-device relationships require entity registry access, which might need WebSocket API.

**Question**: Is device grouping important enough to require WebSocket implementation, or should we skip it in v1?

## User Experience Questions

### 13. Configuration Complexity
**Question**: Is the proposed configuration too complex even with progressive disclosure?

**Concern**: Balance between power and simplicity
**Alternative**: Offer preset-only mode with no customization?

### 14. Cost Transparency
**Question**: Should we show real-time token usage and estimated costs in the UI?

**Options**:
1. Just warnings when high
2. Always visible counter
3. Detailed usage report available

### 15. Migration Communication
**Question**: How do we best communicate the configuration changes to existing users?

**Options**:
1. Automatic migration with changelog
2. Migration wizard on first run
3. Keep old config working with deprecation warnings

## Feature Prioritization

### 16. MVP vs Full Implementation
**Question**: Which features are essential for v1?

**Proposed MVP**:
- Basic context modes (none, minimal, smart, full)
- Simple entity filtering by domain
- Token warnings
- Basic notifications

**Defer to v2**:
- Custom scoring
- Dynamic updates
- Natural language compression
- WebSocket integration

### 17. Testing Requirements
**Question**: What test scenarios are most important?

**Critical paths**:
1. Large HA installations (500+ entities)
2. Various permission levels
3. Different HA versions
4. Upgrade from current version

## Integration Questions

### 18. Other Add-on Interactions
**Question**: Should Claude Home be aware of other add-ons that might provide context?

**Example**: If Node-RED is installed, include automation information?
**Concern**: Scope creep vs useful integration

### 19. CLAUDE.md Integration
**Question**: Should HA context be automatically added to CLAUDE.md memory?

**Options**:
1. No, keep separate
2. Yes, append summary
3. User choice

### 20. Voice Assistant Integration
**Question**: Should we consider future integration with HA's voice assistants?

**Context**: Would affect how we format entity descriptions
**Timeline**: Not urgent but affects architecture decisions

## Final Questions

### 21. Review Process
**Question**: Who should review this design before implementation?

**Stakeholders**:
- Current Claude Home users
- HA core team (for API usage)
- Claude team (for token optimization)

### 22. Success Metrics
**Question**: How do we measure if the redesign is successful?

**Proposed metrics**:
- Token usage reduction (target: 50%)
- User configuration time (target: <2 minutes)
- Support requests (target: reduce by 30%)

Please provide guidance on these questions to ensure the implementation meets all requirements and expectations.