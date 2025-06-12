# Rollback Instructions

## Quick Rollback to v2.0.12 (Session Persistence)

If the new authentication changes cause issues, you can quickly rollback to v2.0.12 which has:
- ✅ Authentication persistence within the same container session
- ✅ No forced re-auth when re-entering terminal in same session
- ❌ Requires re-auth after container restart

### Option 1: Git Rollback (Recommended)
```bash
# Rollback to the working version
git checkout v2.0.12-working -- claude-home/run-simple.sh claude-home/config.yaml

# Update version in config.yaml back to 2.0.12
# Commit the rollback
git add -A
git commit -m "Rollback to v2.0.12 - session persistence only"
git push
```

### Option 2: Manual Rollback
```bash
# Reset to the tagged version
git reset --hard v2.0.12-working
git push --force
```

### Option 3: Cherry-pick Specific Fixes
If some fixes work but others don't:
```bash
# View commits since v2.0.12
git log v2.0.12-working..HEAD --oneline

# Cherry-pick only the commits that work
git checkout v2.0.12-working
git cherry-pick <commit-hash>
```

## What Works in v2.0.12

1. **First Container Start**: Shows "Not authenticated" 
2. **After `claude auth`**: Authentication completes
3. **Exit and Re-enter Terminal**: Shows "Authenticated" and claude works
4. **Container Restart**: Back to "Not authenticated" (expected limitation)

## Known Limitations in v2.0.12

- Requires re-authentication after every container restart
- This is a Claude Code limitation with containers
- But at least auth persists within the session