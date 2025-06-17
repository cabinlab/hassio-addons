# Model Assignments for Parallel Terminals

## Terminal 2 - Container Infrastructure
**Recommended Model: Haiku (claude-3-5-haiku-20241022)**

**Reasoning:**
- Mostly creating well-understood patterns (Dockerfiles, build scripts)
- Research tasks are straightforward (GitHub registry docs)
- No complex debugging needed
- Cost-effective for routine DevOps work

**Tasks:**
- Create Dockerfile (standard patterns)
- Research container registry (documentation lookup)
- Write build scripts (common patterns)

## Terminal 3 - Bug Fixes & Features  
**Recommended Model: Sonnet**

**Reasoning:**
- Complex debugging (auth detection, model selection)
- Needs to understand subtle bash scripting issues
- Terminal UI formatting requires careful attention
- Migration scripts need thoughtful design

**Tasks:**
- Debug why model defaults to Opus (tricky)
- Fix authentication detection (complex logic)
- Fix terminal colors/formatting (detailed work)
- Create migration helper scripts (design work)

## Main Terminal (This one)
**Current Model: Opus**

**Reasoning:**
- Orchestration and architecture decisions
- Complex integration work
- Monitoring and coordinating parallel work
- Final testing and deployment

## Cost Optimization

Using this split:
- **Haiku for Terminal 2**: ~80% cost savings on routine tasks
- **Sonnet for Terminal 3**: Good balance of capability/cost for debugging
- **Opus for Main**: Maximum capability for coordination

Total cost reduction: ~50-60% compared to all Opus

## Alternative (If Budget Conscious)

All terminals on **Haiku** except when blocked:
- Start all terminals with Haiku
- If Terminal 3 gets stuck debugging, upgrade to Sonnet
- Keep Terminal 2 on Haiku throughout
- Downgrade Main to Sonnet after initial planning

This could reduce costs by ~70-80%