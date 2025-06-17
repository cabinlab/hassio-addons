# Home Assistant Addon Development Guide

This guide explains how to develop and test Home Assistant addons locally without affecting production users.

## Quick Start

### 🚀 **One Command - All Environments**
```bash
./dev/scripts/dev-build-all.sh claude-home
```
Builds and deploys to haos, hassdeb, and hadocker simultaneously.

### ⚙️ **Individual Environment Deployment**
```bash
./dev/scripts/dev-build.sh claude-home haos     # Primary development
./dev/scripts/dev-build.sh claude-home hassdeb  # Production validation  
./dev/scripts/dev-build.sh claude-home hadocker # Standalone testing
```

### 👁️ **File Watching (Auto-rebuild)**
```bash
./dev/scripts/dev-watch.sh claude-home &        # Defaults to haos
./dev/scripts/dev-watch.sh claude-home hassdeb & # Or specify environment
```

### 🧹 **Cleanup**
```bash
./dev/scripts/dev-clean.sh                      # Remove dev artifacts
```

## How It Works

### Version Management
- Production versions stay in `config.yaml` (e.g., "2.3.21")
- Development builds use temporary versions (e.g., "dev-20250615-143022")
- Dev versions are stored in `.dev-version` files (gitignored)
- Git hooks prevent accidental commits of dev versions

### Template-Based Deployment (hadocker)
- Each add-on repo contains a `compose.yaml` template with variables
- Dev scripts process templates and generate final deployment files
- Variables include: `{{VERSION}}`, `{{PORT_8080}}`, `{{HA_CONFIG_DIR}}`, etc.
- Configuration provided as YAML file mounted at `/data/options.yaml`
- Add-ons detect `STANDALONE_MODE=true` environment variable

### For haos (VirtualBox HAOS - Primary Development)
1. Build creates a `.tar.gz` file for deployment
2. Auto-deploy via SSH or configured sync method
3. Trigger addon reload via HA API
4. Primary environment for development and testing

### For hassdeb (Debian Supervised - Production Validation)
1. Build creates addon package and copies to Samba mount
2. Mounted at `../hassdeb/` from Debian system at 10.0.0.40:8123
3. Auto-deployment via Samba share to `/addons` directory
4. Final validation environment for production readiness

### For hadocker (Standalone Container - Migration Testing)
1. Scripts copy addon files directly to hadocker `addons/` directory
2. Standalone Home Assistant container environment
3. Add-ons run as separate containers alongside HA
4. Experimental scaffolding for testing supervised → standalone migration

## Development Workflow

### Basic Workflow
```bash
# 1. Start watching for changes
./dev/scripts/dev-watch.sh claude-home &

# 2. Edit files
vim claude-home/ui/index.html

# 3. Changes auto-rebuild and deploy to haos
# 4. Test in Home Assistant UI

# 5. When done, clean up
./dev/scripts/dev-clean.sh
```

### Testing Multiple Addons
```bash
# Run multiple watchers
./dev/scripts/dev-watch.sh claude-home &
./dev/scripts/dev-watch.sh apcupsd &

# Check running watchers
jobs

# Stop a specific watcher
kill %1  # Stops first background job
```

### Testing Workflow
1. **haos**: Access at http://homeassistant.local:8123
   - Primary development environment
   - Auto-deployment via exported tar.gz (set `HAOS_SSH_KEY` for full automation)
   - Addons appear in Supervisor → Add-on Store → Local Add-ons

2. **hassdeb**: Access at http://10.0.0.40:8123
   - Production validation environment
   - Fully automated deployment via Samba mount at `../hassdeb/`
   - Addons appear in Supervisor → Add-on Store → Local Add-ons

3. **hadocker**: Standalone container environment
   - Experimental migration testing
   - Fully automated template processing and deployment
   - Start with: `cd hadocker/addons/addon-name && docker compose up -d`

## File Structure

```
hassio-addons/
├── dev/                  # Development workspace (gitignored)
│   ├── scripts/
│   │   ├── dev-setup.sh      # One-time setup
│   │   ├── dev-build.sh      # Build with dev version
│   │   ├── dev-watch.sh      # Auto-rebuild on changes
│   │   ├── dev-deploy.sh     # Deploy to HA instance
│   │   └── dev-clean.sh      # Clean up dev artifacts
│   └── ...
├── <addon-name>/
│   ├── config.yaml       # Production config (don't edit version!)
│   ├── .dev-version      # Dev version (gitignored)
│   └── ...
├── ../hadocker/
│   ├── compose.yaml               # Main HA container + orchestrator
│   ├── config/                    # HA configuration
│   └── addons/                    # Generated add-on deployments
│       ├── addon-name/
│       │   ├── compose.yaml       # Generated from template
│       │   ├── config.yaml        # Standalone configuration
│       │   └── data/              # Persistent volumes
│       └── ...
└── ../hassdeb/                     # Samba mount to Debian HA (10.0.0.40)
```

## Important Notes

1. **Never commit dev versions** - Git hooks prevent this, but be careful
2. **UI changes** - Some files (like UI) can be live-mounted for instant updates
3. **Core changes** - Changes to Dockerfile, run.sh, etc. require rebuild
4. **Clean regularly** - Run `dev-clean.sh` to remove old dev images

## Troubleshooting

### "Version already exists"
- Home Assistant caches addon info
- Try: Supervisor → System → Reload
- Or use a new timestamp: `rm .dev-version && ./dev/scripts/dev-build.sh <addon>`

### Changes not appearing
- Check if file is mounted in `docker-compose.override.yml`
- Core files always require rebuild
- Try manual reload: `docker-compose restart <addon>`

### Build fails
- Check Docker daemon is running
- Ensure base image is accessible
- Review Dockerfile for errors

## Advanced Usage

### Custom Base Images
Edit `build.yaml` to use local base images during development:
```yaml
build_from:
  amd64: local/my-base:latest
```

### Environment Variables
```bash
# Use different HA instance
HASSD_DIR=/path/to/hassd ./dev/scripts/dev-deploy.sh claude-home

# Deploy to HAOS with SSH
HAOS_IP=192.168.1.100 HAOS_SSH_KEY=~/.ssh/haos ./dev/scripts/dev-deploy.sh claude-home haos

# Deploy to hassdeb
HASSDEB_IP=10.0.0.40 ./dev/scripts/dev-deploy.sh claude-home hassdeb
```

### Debugging
```bash
# View addon logs
docker logs hassd-claude-home

# Enter addon container
docker exec -it hassd-claude-home bash

# Check build output
docker build -t test . --progress=plain
```

## Best Practices

1. **Test in all environments** - haos for primary development, hassdeb for production validation, hadocker for migration testing
2. **Use version branches** - Create feature branches for major changes
3. **Document changes** - Update CHANGELOG.md before merging
4. **Test upgrades** - Ensure users can upgrade smoothly
5. **Clean up** - Run `dev-clean.sh` regularly to free disk space

## Contributing

When your changes are ready:
1. Clean up dev artifacts: `./dev/scripts/dev-clean.sh`
2. Update CHANGELOG.md
3. Create PR with production version bump
4. Test upgrade path from previous version