# Proposed Addon System Upgrades

## Overview

Build a lightweight orchestrator add-on that improves the standalone Home Assistant experience by leveraging existing HA add-on repository patterns while providing better UX and container management.

## Current Problems

### Configuration UI Limitations
- Single-column layout wastes space
- Auto-selected UI controls (dropdown vs radio) based on count, not semantics
- No grouping, sections, or custom styling
- Forces developers to choose between:
  - **Preselect defaults** → May not fit user needs
  - **Leave blank** → Users must understand complex command syntax

### Standalone Experience Gap
- No equivalent to Supervisor's add-on discovery/installation
- Manual Docker Compose management
- No update notifications
- Missing the familiar "add-on store" UX

## Proposed Solution

### Lightweight Orchestrator Add-on
```
┌─────────────────────────────────────────┐
│              Our Add-on                 │
│  ┌─────────────────┐ ┌─────────────────┐│
│  │  Enhanced       │ │  Container      ││
│  │  Config UI      │ │  Management     ││
│  │                 │ │                 ││
│  │ • Multi-column  │ │ • Docker API    ││
│  │ • Grouping      │ │ • Start/Stop    ││
│  │ • Context help  │ │ • Status/Logs   ││
│  │ • Smart defaults│ │ • Updates       ││
│  └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────┘
            │                    │
            ▼                    ▼
   ┌─────────────────┐  ┌─────────────────┐
   │ Existing Add-on │  │ Docker Compose  │
   │ Repositories    │  │ Management      │
   │                 │  │                 │
   │ • config.yaml   │  │ • Standard      │
   │ • README.md     │  │   templates     │
   │ • CHANGELOG.md  │  │ • Direct API    │
   └─────────────────┘  └─────────────────┘
```

## Implementation Strategy

### 1. Leverage Existing Patterns
- **Repository format**: Use existing `config.yaml` schemas
- **Update system**: Monitor GitHub repos for version bumps
- **Metadata**: Parse existing documentation and changelogs

### 2. Standardized Deployment Recipe
Each add-on repo includes a minimal `compose.yml`:
```yaml
services:
  addon-name:
    image: "author/addon-name:latest"
    environment:
      - CONFIG_JSON=${CONFIG_JSON}
    volumes:
      - ${DATA_DIR}:/data
      - ${CONFIG_DIR}:/config
    networks:
      - homeassistant
    restart: unless-stopped
```

### 3. Installation Flow
```
User Selects Add-on
        │
        ▼
Fetch compose.yml + config.yaml
        │
        ▼
Generate Enhanced Config UI
        │
        ▼
User Configures Options
        │
        ▼
Generate Final Compose File
        │
        ▼
Deploy Container via Docker API
```

### 4. Configuration Injection
Move from external bash setup scripts to internal container configuration:

**Old Pattern:**
```bash
# Host setup script
setup_volumes.sh
configure_networking.sh
docker run ...
```

**New Pattern:**
```bash
# Container entrypoint
parse_config_json "$CONFIG_JSON"
configure_service
exec actual-service
```

## Environment Compatibility

### Supervised Mode
- Provides read-only visibility into user's installed add-ons
- Shows status, versions, and available updates
- Does NOT interfere with Supervisor's container management
- Gracefully detects supervised environment and disables orchestration features

### Standalone Mode  
- Becomes the primary orchestrator
- Replaces Supervisor's CRUD functions
- Direct Docker Compose management

## MVP Features

### Core Functionality
- [ ] **Add-on Management Dashboard** - Central panel showing all installed add-ons with status, actions, and resource usage
- [ ] Enhanced configuration UI generation from existing schemas
- [ ] Docker Compose file generation and deployment
- [ ] Container lifecycle management (start/stop/restart)
- [ ] Status monitoring and log viewing
- [ ] Update notifications via GitHub monitoring

### Nice-to-Have
- [ ] **Add-on Store/Browser** - Discovery and installation interface for available add-ons from repositories
- [ ] Health check integration
- [ ] Dependency management between add-ons
- [ ] Backup/restore functionality
- [ ] Custom themes for configuration UI

## Design Choices to Make

### 1. Configuration UI Framework
**Options:**
- JSON Schema + React JSON Schema Form
- Custom React components with form validation
- Vue.js with dynamic form generation
- Web Components for maximum compatibility

**Considerations:** Performance, maintainability, browser compatibility

### 2. Compose Template Format
**Options:**
- Single `compose.yml` with variables
- Template engine (Jinja2, Mustache)
- JSON configuration with compose generation
- Multiple template files for different scenarios

**Considerations:** Developer simplicity, flexibility, debugging

### 3. Configuration Injection Method
**Options:**
- Single `CONFIG_JSON` environment variable
- Multiple environment variables mapped from config
- Configuration files mounted as volumes
- API endpoint for configuration retrieval

**Considerations:** Container security, ease of debugging, compatibility

### 4. Update Mechanism
**Options:**
- GitHub API polling for version checks
- Webhook-based notifications
- RSS/Atom feed monitoring
- Docker Hub tag monitoring

**Considerations:** Rate limiting, reliability, real-time vs batch updates

### 5. Container Communication
**Options:**
- Docker Compose networks with service discovery
- Shared volumes for data exchange
- HTTP API endpoints between containers
- Message queue (Redis, RabbitMQ)

**Considerations:** Complexity, performance, debugging

## Success Metrics

- **Better UX**: Reduced configuration errors, faster setup times
- **Lighter footprint**: Less resource usage than full Supervisor
- **Developer adoption**: Other add-on developers follow standardized patterns
- **User adoption**: Standalone users migrate from manual Docker management

## Next Steps

1. **Prototype enhanced configuration UI** using existing add-on schemas
2. **Build Docker API integration** for container management
3. **Create standardized compose template** and test with existing add-ons
4. **Implement GitHub monitoring** for update notifications
5. **Test environment detection** and adaptive behavior