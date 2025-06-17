# Architecture Decisions - Claude Home

## Decision 1: Clean Container Approach
**Decision**: Skip wrapper hack, build clean container with proper base image
**Rationale**: Avoids technical debt, solves root cause of BusyBox issue
**Impact**: All terminals should build for this architecture

## Decision 2: Dual-Mode Architecture
**Decision**: Same codebase works for both HA add-on and standalone
**Architecture**:
```
claude-home/
├── core/                 # Shared scripts (work everywhere)
├── ha-adapter/          # HA-specific (bashio, etc.)
├── standalone/          # Pure Docker files
└── run.sh              # Detects environment and routes
```

## Decision 3: Container Registry
**Decision**: Use GitHub Container Registry (ghcr.io)
**Image**: `ghcr.io/cabinlab/claude-home:latest`
**Multi-arch**: Support amd64 and arm64

## Decision 4: Core Scripts Must Be Portable
**Decision**: Core scripts work WITHOUT bashio
**Implementation**: 
- Use environment detection
- Fallback for non-HA environments
- Example:
```bash
if command -v bashio >/dev/null 2>&1; then
    # HA environment
    MODEL=$(bashio::config 'claude_model')
else
    # Standalone environment
    MODEL=${CLAUDE_MODEL:-claude-3-5-haiku-20241022}
fi
```

## Decision 5: Fix Priority
1. Model selection (5x cost issue) - CRITICAL
2. Clean container build - CRITICAL
3. Auth detection - HIGH
4. Terminal UI - MEDIUM

## For All Terminals
- Build for the clean container architecture
- No temporary hacks or wrappers
- Test in both HA and standalone contexts
- Update memory files frequently