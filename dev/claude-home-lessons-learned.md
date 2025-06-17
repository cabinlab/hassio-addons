# Claude Home Development: Lessons Learned

## Critical Discoveries

### 1. Model Selection Bug (60x Cost Issue)
- **Problem**: Settings.json was created at `/config/claude-config/settings.json`
- **Solution**: Claude expects it at `~/.claude/settings.json`
- **Lesson**: Always check official documentation for file locations

### 2. Package Name Confusion
- **Wrong**: `@anthropic/claude-cli` (doesn't exist)
- **Correct**: `@anthropic-ai/claude-code`
- **Lesson**: Verify package names before extensive debugging

### 3. BusyBox env -S Issue
- **Problem**: Alpine's BusyBox doesn't support `env -S` flag
- **Workarounds tried**: Complex wrappers, npx solutions
- **Ultimate solution**: Switch to Debian base where it just works
- **Lesson**: Sometimes changing the foundation is better than patching

### 4. Base Image Decision
- **Started with**: `ghcr.io/home-assistant/amd64-base:3.19` (Alpine)
- **Switched to**: `ghcr.io/hassio-addons/debian-base:7.8.3`
- **Benefits**: No BusyBox, standard GNU tools, npm install works directly
- **Lesson**: Community solutions exist - use them

## Architecture Insights

### Container Strategy
- **Single container** for both HA supervised and standalone
- **Debian base** provides familiar environment for developers
- **100MB size tradeoff** worth avoiding maintenance burden
- **Community base** includes S6 and bashio pre-installed

### Key Advantages Over Upstream
- Full CLI access: `claude --help`, `claude --resume`, `claude --model`
- Not forced directly into interactive mode
- Users can leverage all Claude CLI features

## Future Considerations
- MCP Server integration potential (noted in NOTES.md)
- GitHub Actions for automated builds ready when needed
- Clean path to v2.0.0 after experimental validation

## Testing Path
1. v1.4.x - Experimental versions for testing
2. Validate all features work in HA environment
3. Only then bump to v2.0.0 for release

## Documentation-First Approach
- Terminal 3 found model bug solution in official docs
- Saved hours of trial-and-error debugging
- Always check upstream documentation before assuming behavior