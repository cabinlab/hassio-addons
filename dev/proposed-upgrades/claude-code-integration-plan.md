# Claude Code Add-on Integration Plan

## 1. MCP Server Integration (voska/hass-mcp)

### Overview
Integrate the Python-based MCP server to enable Claude to directly interact with Home Assistant entities, automations, and services.

### Repository to Fork/Reference
- **Primary**: `voska/hass-mcp` - Pure MCP implementation for Home Assistant

### Implementation Components
- Check for existing Python installation
- Install Python if needed (python3-minimal, pip, venv)
- Create virtual environment for MCP dependencies
- Copy/adapt voska/hass-mcp server code
- Configure to use Supervisor API when running as add-on
- Add configuration options for enabling/disabling MCP

### Size Impact
- If Python exists: ~15-20 MB (venv + dependencies)
- If Python missing: ~50-55 MB (Python + venv + dependencies)

### Benefits
- Natural language HA control
- Entity state queries
- Automation management
- Service calls
- History access
- Guided conversations for common tasks

## 2. SSH & Web Terminal Integration

### Overview
Add OpenSSH server to provide remote terminal access, making the add-on a complete replacement for the official SSH & Web Terminal add-on.

### Repositories to Reference
- **Official HA Add-on**: `home-assistant/addons/ssh` - For configuration patterns
- **Community Add-on**: `hassio-addons/addon-ssh` - Advanced SSH & Web Terminal by Frenck

### Implementation Components
- Install OpenSSH server package
- Configure SSH daemon with secure defaults
- User management (create non-root user with sudo)
- Install Home Assistant CLI if not present
- Add port configuration for SSH access
- Optional: authorized_keys support

### Size Impact
- OpenSSH server: ~5 MB
- HA CLI: ~5 MB
- Additional utilities: ~5 MB
- Total: ~15 MB

### Benefits
- Complete SSH & Terminal replacement
- Remote access capability
- Integrated with Claude Code environment
- Single add-on instead of two
- Eliminates redundant terminal installations

## 3. Chat Interface for Mobile/Emergency Access

### Overview
Add a web-based chat interface for mobile access and emergency fixes when rate-limited or away from desktop. Three implementation options based on complexity needs.

### Option A: Lightweight Claude-Only (~5-10 MB)

**Approach**: Minimal custom chat interface
- Simple HTML/JS chat UI served via existing web server
- Direct connection to Claude via your existing backend
- Mobile-optimized design with large touch targets
- Basic conversation history in browser localStorage
- No external dependencies beyond what's already in container

**Repositories to Reference**:
- **chatbot-ui** by mckaywrigley - Lightweight Next.js chat interface
- Build custom using existing ttyd web server infrastructure

**Best for**: Users who only use Claude and want minimal overhead

### Option B: Multi-Model with Fallbacks (~20-30 MB)

**Approach**: Lightweight multi-model router
- Fork/adapt a simple open-source chat interface (e.g., chatbot-ui)
- Add model routing logic for fallback support
- Support for 2-3 configured models (Claude primary + backups)
- Simple SQLite for conversation history
- Basic model selection UI

**Repositories to Fork/Reference**:
- **chatbot-ui** by mckaywrigley - Clean, extensible chat interface
- **LibreChat** - Multi-model chat with good routing logic to study
- **BetterChatGPT** - Simple multi-model chat interface

**Fallback Examples**:
- OpenAI GPT-3.5 ($5 backup credit)
- Google Gemini Flash (free tier)
- Groq Cloud (cheap inference)
- Anthropic Claude Instant (legacy cheaper model)

**Best for**: Users wanting reliability without local LLM complexity

### Option C: Full Chat UI Integration (~100-120 MB)

**Approach**: Integrate Hugging Face Chat UI
- Full SvelteKit application
- MongoDB or SQLite for persistence
- Native support for dozens of model providers
- Advanced features: web search, multimodal, tools
- Professional UI with theme support
- Conversation management across all models

**Repository to Fork**:
- **huggingface/chat-ui** - The complete solution

**Model Support**:
- All Claude models
- OpenAI compatible endpoints
- Google Vertex AI
- Local models (if user provides)
- Custom endpoints
- Automatic fallback routing

**Best for**: Power users wanting a complete AI hub for Home Assistant

### Recommendation
Start with Option B as it provides the best balance:
- Reasonable size overhead
- Critical fallback functionality
- Simpler than full Chat UI
- Can upgrade to Option C later if needed

### Mobile Use Cases
All options should prioritize:
- Quick automation fixes
- Emergency troubleshooting
- Simple command execution
- Config validation
- Log viewing

The chat interface primarily serves as an emergency repair tool, not an always-on assistant.