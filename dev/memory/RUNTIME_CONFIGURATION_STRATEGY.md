# Runtime Configuration Strategy for Claude Home

## Overview

This document outlines how Claude Home delivers advanced configuration capabilities at runtime, compensating for Home Assistant's static UI limitations through intelligent terminal-based tools and adaptive behavior.

## Architecture

```
┌─────────────────────┐
│   HA Config UI      │ ← Simple 7-field interface
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   Runtime Engine    │ ← Intelligent adaptation
├─────────────────────┤
│ • Config Validator  │
│ • Smart Defaults    │
│ • Auto-Discovery    │
│ • Context Builder   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  Terminal Commands  │ ← Rich interaction
├─────────────────────┤
│ • claude-config     │
│ • Interactive Setup │
│ • Preview & Debug   │
└─────────────────────┘
```

## Core Components

### 1. Configuration Validator

```python
class ConfigurationValidator:
    """Intelligent runtime configuration validation and enhancement"""
    
    def __init__(self, config, ha_client):
        self.config = config
        self.ha_client = ha_client
        self.warnings = []
        self.suggestions = []
        
    async def validate_and_enhance(self):
        """Main validation pipeline"""
        # Step 1: Basic validation
        self._validate_basic_config()
        
        # Step 2: Enhance with HA data
        await self._enhance_with_ha_context()
        
        # Step 3: Apply smart defaults
        self._apply_smart_defaults()
        
        # Step 4: Check for conflicts
        self._check_configuration_conflicts()
        
        # Step 5: Generate recommendations
        await self._generate_recommendations()
        
        return {
            'config': self.config,
            'warnings': self.warnings,
            'suggestions': self.suggestions
        }
    
    def _validate_basic_config(self):
        """Validate basic configuration rules"""
        # Custom mode needs filter
        if self.config['context_mode'] == 'custom' and not self.config['context_filter']:
            self.warnings.append("Custom mode selected but no filter provided")
            self.config['context_mode'] = 'smart'  # Fallback
            
        # Model-specific validations
        if self.config['model'] == 'opus' and self.config['context_mode'] == 'full':
            self.warnings.append("Opus + full context may cost $10+/day!")
    
    async def _enhance_with_ha_context(self):
        """Enhance configuration with HA-specific data"""
        # Auto-detect notification service
        if self.config['notifications'] and not self.config['notification_service']:
            service = await self._auto_detect_notification_service()
            self.config['notification_service'] = service
            self.suggestions.append(f"Auto-detected notification service: {service}")
        
        # Validate areas/domains in filter
        if self.config['context_filter']:
            valid_filter = await self._validate_filter_terms()
            if valid_filter != self.config['context_filter']:
                self.suggestions.append(f"Adjusted filter to valid terms: {valid_filter}")
                self.config['context_filter'] = valid_filter
```

### 2. Smart Context Builder

```python
class SmartContextBuilder:
    """Builds context based on runtime conditions"""
    
    def __init__(self, mode, model, filter_string=""):
        self.mode = mode
        self.model = model
        self.filter_string = filter_string
        
        # Dynamic weight adjustment
        self.weights = self._calculate_dynamic_weights()
        
    def _calculate_dynamic_weights(self):
        """Adjust weights based on time, date, and usage"""
        base_weights = PRESET_WEIGHTS[self.mode]
        
        # Time-based adjustments
        hour = datetime.now().hour
        if 22 <= hour or hour <= 6:  # Nighttime
            base_weights['security'] *= 1.5
            base_weights['bedroom'] *= 1.5
            base_weights['motion'] *= 1.3
            
        # Day-based adjustments
        if datetime.now().weekday() >= 5:  # Weekend
            base_weights['entertainment'] *= 1.3
            base_weights['kitchen'] *= 1.2
            
        # Seasonal adjustments
        month = datetime.now().month
        if month in [6, 7, 8]:  # Summer
            base_weights['climate'] *= 1.4
            base_weights['temperature'] *= 1.3
        elif month in [12, 1, 2]:  # Winter
            base_weights['climate'] *= 1.5
            base_weights['heating'] *= 1.4
            
        return base_weights
    
    async def build_context(self, entities):
        """Build context with runtime intelligence"""
        # Apply mode-specific logic
        if self.mode == 'smart':
            return await self._build_smart_context(entities)
        elif self.mode == 'minimal':
            return await self._build_minimal_context(entities)
        elif self.mode == 'custom':
            return await self._build_custom_context(entities)
        # ... etc
```

### 3. Interactive Configuration Tool

```bash
#!/usr/bin/env python3
"""claude-config: Interactive configuration management for Claude Home"""

class ClaudeConfig:
    def __init__(self):
        self.commands = {
            'setup': self.interactive_setup,
            'check': self.check_configuration,
            'preview': self.preview_context,
            'suggest': self.suggest_improvements,
            'export': self.export_config,
            'import': self.import_config,
            'tune': self.tune_for_usecase,
            'test': self.test_configuration
        }
    
    def interactive_setup(self):
        """Guided setup wizard"""
        print("🤖 Welcome to Claude Home Setup!")
        print("I'll help you configure Claude for your Home Assistant.\n")
        
        # Step 1: Usage understanding
        use_case = self.ask_multiple_choice(
            "What's your primary use case?",
            [
                ("general", "General assistance and questions"),
                ("automation", "Creating automations and scripts"),
                ("debugging", "Debugging and troubleshooting"),
                ("monitoring", "Home monitoring and status")
            ]
        )
        
        # Step 2: Cost sensitivity
        cost_pref = self.ask_multiple_choice(
            "Cost preference?",
            [
                ("minimal", "Minimize cost (<$0.50/day)"),
                ("balanced", "Balance cost and features (~$1/day)"),
                ("performance", "Maximum capability (cost not primary concern)")
            ]
        )
        
        # Step 3: Home size
        home_size = self.ask_multiple_choice(
            "How many devices/entities do you have?",
            [
                ("small", "Small (< 50 entities)"),
                ("medium", "Medium (50-200 entities)"),
                ("large", "Large (200-500 entities)"),
                ("xlarge", "Very Large (500+ entities)")
            ]
        )
        
        # Generate recommendation
        config = self.generate_config_recommendation(use_case, cost_pref, home_size)
        
        # Show recommendation
        print("\n📋 Recommended Configuration:")
        print(f"  Model: {config['model']}")
        print(f"  Context Mode: {config['context_mode']}")
        if config.get('context_filter'):
            print(f"  Filter: {config['context_filter']}")
        print(f"  Estimated daily cost: ${config['estimated_cost']}")
        
        # Preview
        if self.ask_yes_no("Would you like to preview what Claude will see?"):
            self.preview_context(config)
        
        # Apply
        if self.ask_yes_no("Apply this configuration?"):
            self.apply_configuration(config)
            print("✅ Configuration applied!")
```

### 4. Context Preview System

```python
class ContextPreview:
    """Shows users exactly what Claude will see"""
    
    def generate_preview(self, context, mode='full'):
        """Generate human-readable context preview"""
        
        if mode == 'summary':
            return self._summary_preview(context)
        elif mode == 'full':
            return self._full_preview(context)
        elif mode == 'token_analysis':
            return self._token_analysis_preview(context)
    
    def _summary_preview(self, context):
        """Compact summary preview"""
        output = ["=== Context Summary ==="]
        output.append(f"Total entities: {len(context['entities'])}")
        output.append(f"Estimated tokens: {context['token_estimate']}")
        
        # Group by area
        by_area = defaultdict(list)
        for entity_id, data in context['entities'].items():
            area = data.get('area', 'No Area')
            by_area[area].append(entity_id)
        
        output.append("\nBy Area:")
        for area, entities in sorted(by_area.items()):
            output.append(f"  {area}: {len(entities)} entities")
        
        # Group by domain
        by_domain = defaultdict(int)
        for entity_id in context['entities']:
            domain = entity_id.split('.')[0]
            by_domain[domain] += 1
        
        output.append("\nBy Domain:")
        for domain, count in sorted(by_domain.items(), key=lambda x: x[1], reverse=True):
            output.append(f"  {domain}: {count}")
        
        return '\n'.join(output)
    
    def _token_analysis_preview(self, context):
        """Detailed token usage analysis"""
        output = ["=== Token Usage Analysis ==="]
        
        total_tokens = 0
        token_breakdown = defaultdict(int)
        
        for entity_id, data in context['entities'].items():
            # Entity ID tokens
            id_tokens = len(entity_id) // 4
            token_breakdown['entity_ids'] += id_tokens
            
            # State tokens
            state_tokens = len(str(data.get('state', ''))) // 4
            token_breakdown['states'] += state_tokens
            
            # Attribute tokens
            attr_tokens = len(json.dumps(data.get('attributes', {}))) // 4
            token_breakdown['attributes'] += attr_tokens
            
            total_tokens += id_tokens + state_tokens + attr_tokens
        
        output.append(f"Total estimated tokens: {total_tokens}")
        output.append("\nBreakdown:")
        for category, tokens in sorted(token_breakdown.items(), key=lambda x: x[1], reverse=True):
            percentage = (tokens / total_tokens) * 100
            output.append(f"  {category}: {tokens} ({percentage:.1f}%)")
        
        # Cost estimate
        model_costs = {
            'haiku': 0.00025,   # per 1K tokens
            'sonnet': 0.001,
            'opus': 0.005
        }
        
        output.append("\nEstimated cost per query:")
        for model, cost_per_k in model_costs.items():
            query_cost = (total_tokens / 1000) * cost_per_k
            output.append(f"  {model}: ${query_cost:.4f}")
        
        return '\n'.join(output)
```

### 5. Configuration Tuning

```python
class ConfigurationTuner:
    """Helps users optimize configuration for specific use cases"""
    
    def tune_for_automation_development(self, current_config):
        """Optimize for creating automations"""
        tuned = current_config.copy()
        
        # Recommend settings
        suggestions = []
        
        if tuned['model'] == 'haiku':
            suggestions.append("Consider 'sonnet' model for complex automation logic")
        
        if tuned['context_mode'] != 'custom':
            tuned['context_mode'] = 'custom'
            tuned['context_filter'] = 'light,switch,sensor,binary_sensor,automation,script'
            suggestions.append("Switched to custom mode with automation-relevant domains")
        
        # Add automation-specific context
        tuned['include_automation_traces'] = True
        suggestions.append("Will include recent automation traces for debugging")
        
        return tuned, suggestions
    
    def tune_for_monitoring(self, current_config):
        """Optimize for home monitoring"""
        tuned = current_config.copy()
        suggestions = []
        
        # Focus on sensors and states
        tuned['context_mode'] = 'custom'
        tuned['context_filter'] = 'sensor,binary_sensor,climate,lock,alarm_control_panel'
        suggestions.append("Focused on monitoring-relevant domains")
        
        # Increase update frequency
        tuned['context_update'] = 'frequent'
        suggestions.append("Enabled frequent context updates for current data")
        
        return tuned, suggestions
```

### 6. Advanced Configuration File Support

```python
class AdvancedConfigManager:
    """Manages advanced configuration through files"""
    
    def load_claude_md_preferences(self):
        """Load preferences from CLAUDE.md"""
        claude_md_path = '/config/claude-config/CLAUDE.md'
        
        if not os.path.exists(claude_md_path):
            return {}
        
        with open(claude_md_path, 'r') as f:
            content = f.read()
        
        # Parse markdown for configuration
        config = {}
        
        # Extract YAML blocks
        yaml_blocks = re.findall(r'```yaml\n(.*?)```', content, re.DOTALL)
        for block in yaml_blocks:
            try:
                data = yaml.safe_load(block)
                config.update(data)
            except:
                pass
        
        # Extract preference lists
        if 'Prefer areas:' in content:
            areas = re.findall(r'Prefer areas: (.+)', content)
            if areas:
                config['prefer_areas'] = [a.strip() for a in areas[0].split(',')]
        
        return config
    
    def apply_advanced_config(self, base_config, advanced_config):
        """Merge advanced configuration with base"""
        # Advanced config overrides specific fields
        if 'scoring' in advanced_config:
            base_config['_scoring_override'] = advanced_config['scoring']
        
        if 'prefer_areas' in advanced_config:
            base_config['_area_boost'] = advanced_config['prefer_areas']
        
        if 'ignore_domains' in advanced_config:
            base_config['_domain_exclude'] = advanced_config['ignore_domains']
        
        return base_config
```

## Terminal User Experience

### 1. First Run Experience

```bash
$ # User opens terminal for first time
🤖 Welcome to Claude Home!

📊 Analyzing your Home Assistant setup...
  ✓ Found 247 entities across 12 areas
  ✓ Detected notification service: notify.mobile_app
  ✓ Most active areas: Living Room, Kitchen, Master Bedroom

💡 Quick Setup Available!
   Run 'claude-config setup' for personalized configuration
   Or just type 'claude' to start with smart defaults

Current configuration:
  Model: haiku (cost-optimized)
  Context: smart mode (auto-selects relevant entities)
  
Type 'claude' to start or 'claude-config' for options.
```

### 2. Regular Startup

```bash
$ # Normal startup with smart mode
🤖 Claude Home v1.5.0
📊 Smart Context: 52 relevant entities selected from 247 total
🏠 Active areas: Living Room (motion detected), Kitchen (lights on)
💰 Token estimate: 1,560 (well within haiku limits)

$claude> How can I help with your home today?
```

### 3. Debug Mode Output

```bash
$ # With debug_mode enabled
🤖 Claude Home v1.5.0 [DEBUG MODE]

=== Configuration ===
Model: haiku
Context Mode: smart
Filter: (none)
Token Limit: 3000

=== Context Building ===
Stage 1: Fetched 247 entities (312ms)
Stage 2: Scoring entities...
  - Recency weight: 0.4
  - Domain weight: 0.2
  - Activity weight: 0.3
  - Location weight: 0.1
  
Top scored entities:
  1. light.living_room (0.92) - on, changed 2m ago
  2. motion.hallway (0.88) - detected, changed 5m ago
  3. climate.main (0.85) - heating, active
  ...

Stage 3: Selected 52 entities under token limit
Stage 4: Formatted context (1,560 tokens)

=== Ready ===
Type your question or 'claude-config preview' to see full context

$claude>
```

## Configuration Commands Reference

### Basic Commands

```bash
claude-config setup          # Interactive setup wizard
claude-config check         # Validate current configuration
claude-config preview       # Preview context Claude will see
claude-config suggest       # Get optimization suggestions
```

### Advanced Commands

```bash
claude-config export [file]      # Export configuration
claude-config import <file>      # Import configuration
claude-config tune <use-case>    # Optimize for specific use case
claude-config test               # Test configuration with sample queries
claude-config reset              # Reset to defaults
```

### Debug Commands

```bash
claude-config debug entities     # Show all entities with scores
claude-config debug tokens       # Detailed token analysis  
claude-config debug performance  # Timing and performance stats
claude-config debug api          # Test API connectivity
```

## Benefits

### 1. Overcomes UI Limitations
- Rich interaction despite flat config UI
- Progressive disclosure through commands
- Visual feedback and previews

### 2. Adaptive Intelligence
- Configuration adjusts to time/day/season
- Learns from usage patterns
- Smart defaults that actually work

### 3. Power User Features
- Full control when needed
- Export/import/share configs
- Advanced debugging tools

### 4. User Education
- Shows impact of choices
- Teaches through suggestions
- Builds understanding over time

## Future Enhancements

### 1. Web Configuration UI
- Separate ingress endpoint
- Rich configuration interface
- Visual entity selector

### 2. Configuration Profiles
- Save multiple configurations
- Switch based on context
- Time-based profile switching

### 3. Community Sharing
- Share configurations online
- Rate and review configs
- Auto-apply popular settings

## Conclusion

The runtime configuration strategy transforms Claude Home's simple 7-field configuration into a sophisticated, adaptive system that provides:

- **Immediate value** through smart defaults
- **Progressive learning** through interactive tools  
- **Full power** for advanced users
- **Continuous improvement** through runtime adaptation

This approach delivers the best of both worlds: simplicity for beginners and depth for power users.