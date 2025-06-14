# Claude Home + Chat Integration Plan

## Version Control Strategy

1. **Backup Branch**: `backup/claude-home-v2.2.7` (created)
   - Contains current working version before chat integration
   - Can rollback if needed: `git checkout backup/claude-home-v2.2.7`

2. **Main Branch**: Where integration work happens
   - Required for Home Assistant testing
   - Will increment version to 3.0.0 for major feature addition

## Integration Steps

### Phase 1: Core Files Migration
- [ ] Copy `chat_gateway_mcp.py` to claude-home/
- [ ] Copy responsive UI files to claude-home/ui/
- [ ] Add Python dependencies to Dockerfile

### Phase 2: Configuration Merge
- [ ] Update config.yaml with chat options
- [ ] Preserve existing options
- [ ] Add new chat-specific options

### Phase 3: Service Management
- [ ] Add supervisord for multi-service management
- [ ] Update run-simple.sh to launch all services
- [ ] Configure ports and routing

### Phase 4: Anse Integration
- [ ] Add Anse build process to Dockerfile
- [ ] Configure Anse to use local gateway
- [ ] Set up proper ingress routing

### Phase 5: Testing
- [ ] Test terminal functionality preserved
- [ ] Test chat interface working
- [ ] Test mobile responsiveness
- [ ] Test fallback providers

## Rollback Procedure

If issues arise:
```bash
# Quick rollback to v2.2.7
git checkout backup/claude-home-v2.2.7 -- claude-home/
git commit -m "Rollback to v2.2.7"

# Or full branch switch
git checkout backup/claude-home-v2.2.7
```

## Testing in Home Assistant

After each major change:
1. Commit to main branch
2. Push to GitHub
3. Reload addon in HA
4. Test functionality
5. Check logs for errors