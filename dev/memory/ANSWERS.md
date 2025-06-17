# Answers to Configuration Redesign Questions

## Technical Answers

### 1. WebSocket API Access
**Answer**: Skip WebSocket for v1. The Supervisor proxy adds complexity and potential reliability issues. Use REST API only for now. We can add WebSocket in v2 if needed.

### 2. Entity Labels Access
**Answer**: Labels are NOT in `/core/api/states`. For v1, let's use a simpler approach:
- Use entity_id patterns (e.g., entities ending in `_important`)
- Use friendly names containing keywords
- Document WebSocket requirement for future enhancement

### 3. Performance Limits
**Answer**: No hard rate limits, but be respectful:
- Cache states for entire conversation
- Only refresh on explicit user request
- Add 1-second delay if making multiple API calls

## Design Decisions

### 4. Context Update Strategy
**Answer**: Static context (fetch once at start) for v1. This is predictable and avoids token creep. Add a user command like "refresh context" if they need updates.

### 5. Default Context Mode
**Answer**: Default to "smart" mode. New users get immediate value without configuration, and it demonstrates the capability.

### 6. Token Warning Thresholds
**Answer**: Your thresholds are good, but make them configurable:
```yaml
token_warnings:
  haiku: 3000
  sonnet: 8000
  opus: 15000
```

## Implementation Clarifications

### 7. Backwards Compatibility
**Answer**: Maintain compatibility. Silent migration is better UX. Map old fields transparently and only show deprecation warnings in logs.

### 8. Custom Scoring Functions
**Answer**: Not in v1. The proposed algorithm is sophisticated enough. We can add customization if users request it with specific use cases.

### 9. Multi-Language Support
**Answer**: English-only for v1. Use technical format for non-English users. This is a nice-to-have that can wait.

## Limitations Discovered

### 10. Missing API Capabilities
**Answer**: Document as "future enhancements." Don't try to work around these - it adds complexity and potential breaking points.

### 11. Area Assignment Gaps
**Answer**: Treat entities without areas as "global" - they get medium priority in scoring unless they match other high-priority criteria.

### 12. Device Relationship Complexity
**Answer**: Skip device grouping in v1. It's not worth the WebSocket complexity. Entity-level grouping is sufficient.

## User Experience

### 13. Configuration Complexity
**Answer**: The progressive disclosure approach is perfect. Start simple, reveal complexity only when needed.

### 14. Cost Transparency
**Answer**: Show warnings when high (your proposed thresholds). Don't add always-visible counters - it creates anxiety.

### 15. Migration Communication
**Answer**: Automatic migration with changelog. No wizards or interruptions. Just make it work.

## Feature Prioritization

### 16. MVP vs Full Implementation
**Answer**: Your MVP list is perfect. Ship that first, gather feedback, then enhance.

### 17. Testing Requirements
**Answer**: Focus on:
1. 10 entity setup (minimal)
2. 100 entity setup (typical)
3. 500+ entity setup (stress test)
4. Upgrade from 1.4.x

## Integration Questions

### 18. Other Add-on Interactions
**Answer**: No. Keep scope focused on core HA entities. Don't create cross-addon dependencies.

### 19. CLAUDE.md Integration
**Answer**: No automatic integration. Keep HA context separate from file context. Users can manually add important info to CLAUDE.md if desired.

### 20. Voice Assistant Integration
**Answer**: Not now. This would require different formatting and isn't our primary use case.

## Final Answers

### 21. Review Process
**Answer**: We'll test internally first, then do a beta release for feedback.

### 22. Success Metrics
**Answer**: Your metrics are good. Also track:
- Time to first useful response
- Number of "refresh context" requests
- Error rates

## Implementation Priorities

Based on your excellent analysis, here's the implementation order:

1. **Phase 1 (v1.5.0)**
   - New config schema with context_mode
   - Basic scoring algorithm
   - Static context fetching
   - Token warnings

2. **Phase 2 (v1.6.0)**
   - Progressive disclosure UI
   - Context presets (minimal, smart, full)
   - Migration from old schema

3. **Phase 3 (v2.0.0)**
   - Custom context configuration
   - Natural language compression
   - WebSocket support (if needed)

## Key Decisions

1. **Keep it simple** - Your smart defaults handle 90% of use cases
2. **Static context** - Predictable and efficient
3. **No WebSocket** - Reduces complexity significantly
4. **Progressive disclosure** - Perfect balance of power and simplicity

Your scoring algorithm is excellent. The context architecture is well thought out. Let's implement the MVP and iterate based on user feedback.

Great work on this analysis!