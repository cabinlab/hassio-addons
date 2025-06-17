# CH-1: Natural Language Automation Builder - Implementation Design

## Overview
Transform natural language commands like "Turn off all lights when I say good night" into valid Home Assistant automation YAML.

## Architecture Design

### Core Components

#### 1. **Natural Language Parser**
```bash
# Command: claude-automate "Turn off all lights when I say good night"
# Input: Natural language automation description
# Output: Structured automation intent
```

#### 2. **Intent Analyzer** 
- Parse triggers, conditions, actions from natural language
- Map to HA entity types using existing context integration
- Handle time-based, state-based, and event-based triggers

#### 3. **YAML Generator**
- Convert structured intent to valid HA automation YAML
- Use HA context integration to resolve entity IDs
- Include proper service calls and data structures

#### 4. **Validation Engine**
- Syntax validation of generated YAML
- Entity existence checking via HA API
- Logic validation (e.g., circular dependencies)

#### 5. **Test Framework**
- Dry-run capability to test automation logic
- Safe preview mode before deployment
- Integration testing with HA

## Implementation Strategy

### Phase 1A: Basic Natural Language Processing (Week 1)
**Goal**: Handle simple automation patterns

**Examples to Support**:
- "Turn off all lights at bedtime"
- "Turn on porch light when motion detected"
- "Close garage door if left open for 10 minutes"
- "Send notification when temperature drops below 65"

**Architecture**:
```bash
# New script: /claude-home/scripts/claude-automate.sh
claude-automate() {
    local description="$1"
    local automation_name="$2"
    
    # Step 1: Parse natural language with Claude
    # Step 2: Analyze HA context for entities
    # Step 3: Generate YAML
    # Step 4: Validate and preview
    # Step 5: Optional deployment
}
```

### Phase 1B: Entity Resolution (Week 2)
**Goal**: Integrate with HA context to resolve "all lights", "motion sensors", etc.

**Integration Points**:
- Use existing `ha entities` command for entity discovery
- Smart matching: "lights" → `light.*` entities
- Domain mapping: "thermostats" → `climate.*` entities
- Room/area resolution: "living room lights" → area-based filtering

### Phase 1C: YAML Generation & Validation (Week 3)
**Goal**: Generate syntactically correct and logically sound HA automations

**Validation Layers**:
1. **Syntax**: Valid YAML structure
2. **HA Schema**: Proper automation format
3. **Entity Existence**: All referenced entities exist
4. **Logic**: No circular dependencies or conflicts

### Phase 1D: Testing & Integration (Week 4)
**Goal**: Safe deployment and testing capabilities

**Safety Features**:
- Preview mode (show YAML without deployment)
- Dry-run testing (simulate without executing)
- Backup existing automations before changes
- Rollback capability

## Universal Model Support

### Haiku Implementation
- **Focus**: Simple, common automation patterns
- **Scope**: Basic trigger-action pairs
- **Examples**: "Turn off lights at 11pm", "Lock doors when away"
- **Validation**: Basic syntax and entity checking

### Sonnet Implementation (Recommended)
- **Focus**: Complex multi-step automations
- **Scope**: Conditions, variables, templates
- **Examples**: "Turn on vacation mode when away for 2+ days"
- **Validation**: Advanced logic checking and optimization

### Opus Implementation
- **Focus**: Sophisticated automation logic
- **Scope**: Complex conditions, advanced templates
- **Examples**: "Gradually adjust lighting based on sunset and occupancy patterns"
- **Validation**: Deep logic analysis and edge case handling

## Command Interface

### Basic Usage
```bash
# Simple automation creation
claude-automate "Turn off all lights at bedtime"

# Named automation
claude-automate "Lock all doors when leaving" --name "departure_security"

# Preview only (no deployment)
claude-automate "Close blinds when sunny" --preview

# Test automation logic
claude-automate "Send alert if door open too long" --test
```

### Advanced Usage
```bash
# Complex automation with conditions
claude-automate "Turn on security lights if motion detected after sunset and nobody home"

# Time-based automation
claude-automate "Start coffee maker at 7am on weekdays"

# Template-based automation
claude-automate "Adjust thermostat based on outside temperature and time of day"
```

## Integration with Existing Claude Home

### Context Integration
- Leverage existing `ha entities`, `ha state`, `ha summary` commands
- Use entity discovery for smart matching
- Integrate with domain filtering configuration

### Configuration Integration
- Add automation builder settings to Claude Home config
- Support for default automation names, validation levels
- Integration with HA notification system

### Security Integration
- Use existing security framework for validation
- Audit logging of all automation creations
- Backup and rollback capabilities

## Example Implementation Flow

### Input: "Turn off all lights when I say good night"
1. **Parse**: Trigger="voice command 'good night'", Action="turn off all lights"
2. **Resolve**: lights=`ha entities light`, trigger=conversation integration
3. **Generate**: 
   ```yaml
   automation:
     alias: "Good Night Lights Off"
     trigger:
       platform: conversation
       command: "good night"
     action:
       service: light.turn_off
       target:
         entity_id: all
   ```
4. **Validate**: Check conversation integration exists, validate light entities
5. **Preview**: Show generated YAML to user
6. **Deploy**: Optional deployment to HA automations

## Success Metrics
- **Functionality**: Works with Haiku for basic automations
- **Quality**: Sonnet generates complex, valid automations
- **Reliability**: 95%+ generated automations deploy successfully
- **Safety**: Zero automations cause system conflicts
- **Usability**: Non-technical users can create working automations

## Next Steps
1. Create `claude-automate` script foundation
2. Implement basic natural language parsing
3. Integrate with existing HA context system
4. Build YAML generation engine
5. Add comprehensive validation framework