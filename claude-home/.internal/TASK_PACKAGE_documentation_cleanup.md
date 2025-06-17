# Task Package: Documentation & Error Handling Cleanup

**Created:** June 13, 2025  
**Priority:** Medium  
**Estimated Effort:** 2-4 hours

## Context Requirements (MUST READ FIRST)

**"A+ context leads to A+ decisions. B- context leads to F decisions."**

### Essential Files to Read (in order):

1. **`/home/andrew/hassio-addons/claude-home/run-simple.sh`** - The ONLY active startup script
   - Understand the current authentication flow
   - Note the MCP configuration approach
   - See how settings.json is generated

2. **`/home/andrew/hassio-addons/claude-home/.internal/design-notes/config-structure.md`** - Why configs appear in multiple places
   - Critical for understanding the intentional "duplication"
   - Explains working directory flexibility

3. **`/home/andrew/hassio-addons/claude-home/config.yaml`** - Addon configuration schema
   - Note the `working_directory` option
   - Understand available user options

4. **`/home/andrew/hassio-addons/claude-home/DOCS.md`** - Current user-facing documentation
   - Identify outdated references
   - Note what users are told vs reality

5. **`/home/andrew/hassio-addons/claude-home/.internal/BACKLOG.md`** - Deferred features
   - Understand what was intentionally postponed
   - Avoid re-implementing deferred items

### Additional Context:

- **OAuth Limitation:** Claude Code uses OAuth authentication that cannot be restored after container restart. Session state is lost and re-authentication is required. This is a fundamental limitation, not a bug.
- **No run.sh:** The complex 691-line run.sh has been deleted. Only run-simple.sh exists.
- **MCP Integration:** hass-mcp-lite is implemented and working. Native HA MCP is detected but saved as backup.

## Tasks

### 1. Update DOCS.md
**File:** `/home/andrew/hassio-addons/claude-home/DOCS.md`

**Current Issues:**
- May reference features from the old run.sh
- Might not explain OAuth session loss clearly
- Could have outdated configuration examples

**Requirements:**
- Document that re-authentication is required after container restart
- Explain the working directory option and its implications
- Update any references to removed features
- Keep language simple and user-friendly
- Add troubleshooting section for common auth issues

### 2. Improve Error Handling in run-simple.sh
**File:** `/home/andrew/hassio-addons/claude-home/run-simple.sh`

**Current Issues:**
- Limited error messages when authentication fails
- MCP connection failures could be clearer
- No guidance when OAuth session is lost

**Requirements:**
- Add clear error messages for OAuth session loss
- Improve MCP connection error reporting
- Add helpful suggestions when auth fails
- Consider adding a `claude-troubleshoot` helper command
- DO NOT try to "fix" OAuth persistence - it's impossible

### 3. Document OAuth Limitations
**Create:** `/home/andrew/hassio-addons/claude-home/AUTHENTICATION.md`

**Requirements:**
- Explain why re-authentication is needed after restart
- Document the OAuth flow clearly
- Provide step-by-step re-auth instructions
- Explain what is/isn't preserved across restarts
- Link from DOCS.md

### 4. Review and Update README.md
**File:** `/home/andrew/hassio-addons/claude-home/README.md`

**Requirements:**
- Ensure it accurately describes current functionality
- Remove any references to removed features
- Keep it concise (detailed docs go in DOCS.md)

## Success Criteria

1. User can understand from docs why they need to re-authenticate
2. Error messages guide users to solutions, not just state problems
3. No references to removed features or scripts
4. Documentation matches actual behavior
5. New users can get started without confusion

## Do NOT:

- Try to "fix" OAuth persistence (it's a Claude Code limitation)
- Reference or restore any deleted scripts
- Add complex new features (see BACKLOG.md)
- Change the fundamental architecture
- Create new startup scripts

## Testing Checklist

- [ ] Start fresh container - do docs explain what happens?
- [ ] Simulate auth failure - are errors helpful?
- [ ] Check all doc links - do they work?
- [ ] Read as new user - is flow clear?
- [ ] Verify no references to deleted features

## Notes

- The multi-config file pattern is intentional, not a bug
- Working directory can be /config, /root, etc. - this is why configs exist in multiple places
- run-simple.sh is the ONLY startup script
- Tools in tools/ directory are for diagnostics only