# Claude Home Terminal Resume Package

## Current Status
Terminal UX redesign with ASCII header and improved auth flow, but experiencing BusyBox `/usr/bin/env -S` incompatibility with npm-installed Claude CLI.

## Core Problem
Claude Code CLI installed via npm uses `#!/usr/bin/env -S node` shebang which BusyBox (Alpine Linux) doesn't support, causing:
```
/usr/bin/env: unrecognized option: S
```

## Key Context to Gather Before Starting

### 1. Current Implementation Status
- Review git log from v1.4.8 onwards for experimental terminal changes
- Check current run.sh authentication logic and terminal header implementation  
- Understand model selection configuration (settings.json vs environment variables)
- Review current credential persistence and validation approach

### 2. Working vs Broken Flows
- Auto-start claude flow (may work via different path)
- Manual `claude auth` command (definitely broken with BusyBox)
- Authentication status detection reliability
- Model selection not defaulting to Haiku (cost issue)

### 3. Upstream Reference
- Check `git show upstream/main:claude-terminal/run.sh` for their BusyBox solution
- Upstream uses: `node $(which claude)` in ttyd command directly
- Understand why we diverged from this approach (UX requirements)

### 4. Container Architecture
- Current base: `ghcr.io/home-assistant/amd64-base:3.19` (Alpine + BusyBox)
- HA add-on constraints and requirements
- User's future migration to non-supervised HA (standalone containers)

### 5. Failed Authentication State
- Authentication shows false positives/negatives
- State changes without completing auth process
- Possible credential caching/persistence issues causing confusion

## Solution Options (In Order of Complexity)

### Option 1: Restore Simple Wrapper (Immediate Fix)
**Status:** Previously working, removed for testing
**Implementation:**
- Create `/usr/local/bin/claude` wrapper that calls `node /usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js "$@"`
- Backup original npm claude to claude-original
- Keep all UX functionality: `claude auth`, `claude --help`, etc.
- Fix remaining issues: model selection, auth status detection, text centering

**Pros:** Minimal change, preserves UX, proven to work
**Cons:** Band-aid solution, doesn't address container architecture

### Option 2: Add GNU Coreutils to Alpine
**Implementation:**
- Add `coreutils` package to Dockerfile (~2-4MB overhead)
- Replace BusyBox env with GNU env that supports `-S` flag
- Keep direct Claude CLI calls without wrapper

**Pros:** Fixes root cause, clean implementation
**Cons:** Container bloat, still tied to HA base image limitations

### Option 3: Dual-Mode Architecture 
**Implementation:**
- Runtime detection: HA supervisor mode vs standalone mode
- Shared core logic with configuration abstraction layer
- Same codebase for both deployment types
- Could use wrapper in HA mode, direct calls in standalone

**Pros:** Future-proof for user's migration, broader adoption
**Cons:** More complex, requires careful abstraction design

### Option 4: Custom Container Strategy
**Implementation:**
- Publish ideal container to `ghcr.io/cabinlab/claude-home`
- Use `node:alpine` + coreutils base (no BusyBox issues)
- HA add-on becomes thin adapter layer that:
  - Inherits from custom container
  - Translates HA config.yaml → container config.json  
  - Adds bashio logging integration
  - Handles HA networking/security/permissions

**Pros:** Full control, clean architecture, solves all issues
**Cons:** Most complex, requires container registry management

### Option 5: Claude Code Dev Container Reference (NEW)
**Implementation:**
- Research Claude Code's official development container configuration
- Check `.devcontainer/` or similar in Claude Code repository
- See what base image and setup they recommend
- Potentially inherit their proven working environment

**Pros:** Official solution, likely addresses known issues
**Cons:** May not fit HA add-on constraints, unknown compatibility

## Critical Issues to Address

1. **Model Selection Bug:** Not defaulting to Haiku (5x cost difference!)
2. **Auth Status Detection:** False positives/negatives causing confusion
3. **Terminal Layout:** Color codes printing literally, misaligned text
4. **Theme Configuration:** Still showing as radio buttons vs dropdown
5. **Credential Persistence:** Unreliable state across container restarts

## Files Modified Recently
- `claude-home/run.sh` - Main startup logic
- `claude-home/config.yaml` - Version and options
- `claude-home/translations/en.yaml` - UX descriptions and warnings
- `claude-home/Dockerfile` - Container dependencies

## User Requirements
- Manual control over Claude startup (`claude auth`, `claude --help`, etc.)
- Auto-start toggle option
- Model selection with cost warnings
- Clean terminal UX with ASCII header
- Reliable authentication persistence
- Future compatibility with non-supervised HA deployment

## Testing Strategy
After implementing solution:
1. Fresh container startup - verify no BusyBox errors
2. Authentication flow - `claude auth` should work properly
3. Model selection - verify Haiku default, check logs for actual model used
4. Terminal layout - colors render properly, text aligned under ASCII
5. Authentication persistence - status survives container restart
6. Configuration changes - dropdown vs radio button behavior

## Next Steps Priority
1. **Immediate:** Fix BusyBox issue (likely restore wrapper)
2. **Critical:** Fix model selection defaulting to expensive option
3. **Important:** Resolve auth status detection reliability
4. **Strategic:** Plan container architecture for dual-mode deployment

## Git Context
Current branch: `main`
Recent commits focus on experimental terminal redesign starting v1.4.8
Test commit at v1.4.13 removed wrapper to confirm BusyBox issue is real
Ready to implement chosen solution and commit stable version