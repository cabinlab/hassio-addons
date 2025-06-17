# Phase 1 Testing Plan

## Testing Overview
Systematic testing of CH-1 Natural Language Automation Builder and HA Context Integration features.

## Test Categories

### 1. **HA Context Integration Tests**
**Goal**: Verify HA API connectivity and entity access

#### Test Cases:
- [ ] `ha help` - Show available commands
- [ ] `ha summary` - System overview with entity counts
- [ ] `ha entities` - List all allowed entities
- [ ] `ha entities light` - Filter by domain
- [ ] `ha entities sensor` - Test sensor filtering
- [ ] `ha state sensor.test` - Get specific entity state (if exists)

#### Expected Results:
- Commands execute without errors
- Entity lists are properly filtered by domain
- JSON parsing works correctly without jq
- Entity counts match actual HA setup

### 2. **Natural Language Automation Builder Tests**
**Goal**: Verify automation generation and validation

#### Test Cases:
- [ ] `claude-automate help` - Show help information
- [ ] `automate "Turn off all lights at bedtime"` - Basic time trigger
- [ ] `claude-automate "Turn on porch light when motion detected"` - Motion trigger
- [ ] `automate "Send notification if door open too long"` - State-based trigger
- [ ] `claude-automate "Turn off all lights when I say good night"` - Voice trigger

#### Expected Results:
- Valid YAML automation generated
- Proper trigger/action mapping
- Entity resolution works correctly
- Validation passes for generated automations

### 3. **Universal Model Support Tests**
**Goal**: Verify features work with different Claude models

#### Test Cases:
- [ ] Test with Haiku configuration (if available)
- [ ] Test with Sonnet configuration (recommended)
- [ ] Test with Opus configuration (if available)
- [ ] Verify graceful degradation with simpler models

#### Expected Results:
- All features function regardless of model choice
- Quality scales appropriately with model capability
- No features are gated behind specific models

### 4. **Error Handling Tests**
**Goal**: Verify robust error handling and user feedback

#### Test Cases:
- [ ] Test with invalid entity names
- [ ] Test with malformed natural language
- [ ] Test without HA API connectivity
- [ ] Test with insufficient permissions

#### Expected Results:
- Clear error messages for users
- Graceful degradation when APIs unavailable
- No crashes or undefined behavior

### 5. **Integration Tests**
**Goal**: Verify interaction between components

#### Test Cases:
- [ ] Context integration feeding automation builder
- [ ] Settings.json configuration affecting both features
- [ ] Security framework protecting all operations
- [ ] Logging and audit trail functionality

#### Expected Results:
- Seamless integration between features
- Consistent configuration across components
- Proper security and logging

## Test Environment Setup

### Prerequisites:
- Home Assistant running with addon installed
- Valid HASSIO_TOKEN for API access
- Test entities available (lights, sensors, etc.)
- Claude API access for model testing

### Test Data:
- Sample entity IDs for testing
- Known automation patterns
- Test scenarios for edge cases

## Success Criteria

### Functional:
- [ ] All commands execute without fatal errors
- [ ] Generated automations are syntactically valid
- [ ] Entity resolution works for real HA setup
- [ ] Help and documentation are accessible

### Quality:
- [ ] User experience is intuitive and helpful
- [ ] Error messages are clear and actionable
- [ ] Performance is acceptable for interactive use
- [ ] Generated automations are logically correct

### Compatibility:
- [ ] Works with multiple Claude models
- [ ] Handles various HA entity configurations
- [ ] Graceful degradation when features unavailable
- [ ] Backward compatibility maintained

## Test Results Documentation

### Template for Each Test:
```
**Test**: [Test name]
**Status**: ✅ Pass | ❌ Fail | ⚠️ Partial
**Model**: [Haiku/Sonnet/Opus]
**Result**: [Description of result]
**Issues**: [Any problems encountered]
**Notes**: [Additional observations]
```

## Next Steps After Testing
1. Document all test results
2. Prioritize bug fixes and improvements
3. Plan Phase 2 features based on learnings
4. Update documentation based on test findings