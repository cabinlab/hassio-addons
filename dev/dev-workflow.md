# Home Assistant Addon Development Workflow

This document describes the local development workflow for testing addons in multiple environments without affecting production users.

## The Challenge

Home Assistant's addon system uses version numbers to determine when updates are available. Simply changing files doesn't trigger a reload - you need to:
1. Bump the version in config.yaml
2. Rebuild the Docker image
3. Home Assistant detects the new version and offers an update

However, committing version bumps to GitHub would notify all users of an update, potentially exposing them to development/test code.

## Modern Environment-Aware Approach

We now support both Supervised and Standalone deployments with environment-aware add-ons that detect their runtime context and adapt accordingly.

## Solution Overview

We implement a multi-environment approach:

1. **Local-only version bumping** - Use git hooks to prevent accidental commits of dev versions
2. **Template-based deployment** - Add-ons include `compose.yaml` templates for standalone deployment
3. **Environment detection** - Add-ons detect Supervised vs Standalone mode at runtime
4. **File watching & auto-reload** - Automatic rebuilding on file changes
5. **Multi-instance support** - Deploy to haos, hassdeb, or hadocker environments

## Implementation

### 1. Development Version Management

Create a `.dev-version` file in each addon directory that overrides the version in `config.yaml` during development:

```bash
# In each addon directory
echo "dev-$(date +%Y%m%d-%H%M%S)" > .dev-version
```

### 2. Git Configuration

Add to `.gitignore`:
```
.dev-version
config.yaml.dev
*-dev-build/
```

### 3. Development Scripts

We'll create scripts to:
- Automatically bump dev versions
- Build and deploy to local instances
- Watch for file changes
- Clean up dev artifacts

### 4. Template-Based Deployment (hadocker)

For standalone environments, add-ons include `compose.yaml` templates:
- Templates use variable substitution: `{{VERSION}}`, `{{PORT_8080}}`, etc.
- Dev scripts generate final `compose.yaml` files in `hadocker/addons/addon-name/`
- Configuration provided as YAML file mounted at `/data/options.yaml`
- Add-ons detect `STANDALONE_MODE=true` environment variable

### 5. Environment Detection

Add-ons detect their runtime environment:
- **Supervised**: Use bashio library and Supervisor APIs
- **Standalone**: Parse YAML config from `/data/options.yaml`
- Environment detection allows same container to work in both contexts

## Supported Environments

### haos (Primary Development)
- VirtualBox HAOS instance
- Automated tar.gz export (set `HAOS_SSH_KEY` for full SSH automation)
- Full Supervisor environment for testing

### hassdeb (Production Validation)
- Debian Supervised at 10.0.0.40
- Fully automated deployment via Samba mount
- Final validation before release

### hadocker (Standalone Testing)
- Docker Compose based deployment
- Fully automated template processing with variable substitution
- Environment-aware add-on testing

## Usage Examples

```bash
# Build for different environments
./dev/scripts/dev-build.sh claude-home haos      # Primary development
./dev/scripts/dev-build.sh claude-home hassdeb   # Production validation
./dev/scripts/dev-build.sh claude-home hadocker  # Standalone testing

# Start standalone deployment
cd hadocker/addons/claude-home
docker compose up -d
```