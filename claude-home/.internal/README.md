# .internal/ Directory

This directory serves as a communication channel between Claude Code agents and the repository maintainer.

## Purpose

- **Design Documentation**: Document architectural decisions and explain confusing-but-necessary patterns
- **Agent Communication**: Store information that needs to persist between Claude Code sessions
- **Test Artifacts**: Confine test-related files to prevent repository pollution
- **Implementation Notes**: Explain why certain approaches were taken

## Structure

```
.internal/
├── README.md           # This file
├── BACKLOG.md         # Deferred features and code snippets
├── design-notes/      # Architectural decisions and explanations
└── test-artifacts/    # Test files and experimental code
```

## Guidelines

1. This directory is gitignored - nothing here will be committed
2. Use markdown files for documentation
3. Create subdirectories as needed for organization
4. Document "why" not just "what" - especially for confusing patterns

## Current Documentation

- `BACKLOG.md` - Code snippets and features deferred from the run.sh consolidation
- `design-notes/config-structure.md` - Explains the multiple config file locations

## Note

The `tools/` directory remains at the addon root level as those are operational diagnostic scripts rather than internal documentation.