# Claude Watchdog for Home Assistant

[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=claude_watchdog&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

Intelligent continuous monitoring for Home Assistant using Claude AI. Claude Watchdog runs in the background, analyzing your system state changes and providing proactive insights, security monitoring, and optimization recommendations.

## What is Claude Watchdog?

Claude Watchdog is a revolutionary Home Assistant add-on that provides:

- **Continuous AI Monitoring**: Uses Claude 3.5 Haiku for fast, cost-effective analysis
- **Proactive Insights**: Identifies patterns and anomalies before they become problems
- **Intelligent Alerts**: Smart notifications based on confidence levels and context
- **Energy Optimization**: Detects efficiency opportunities and wasteful patterns
- **Security Intelligence**: Advanced anomaly detection for security events
- **Automation Health**: Monitors automation performance and suggests improvements

## Features

- **Real-time State Analysis**: Monitors entity state changes across your Home Assistant system
- **Multi-Domain Monitoring**: Climate, security, energy, automation performance, and device health
- **Cost-Controlled**: Built-in cost tracking with daily limits to prevent unexpected charges
- **Learning Patterns**: Adapts to your home's normal behavior patterns over time
- **Smart Notifications**: Configurable alerts via Home Assistant notification services
- **Comprehensive Logging**: Detailed insights and analysis history

## Installation

### Quick Install
[![Open your Home Assistant instance and show the dashboard of a Supervisor add-on.](https://my.home-assistant.io/badges/supervisor_addon.svg)](https://my.home-assistant.io/redirect/supervisor_addon/?addon=claude_watchdog&repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

### Manual Installation
1. Add this repository to your Home Assistant add-on store:

   [![Open your Home Assistant instance and show the add add-on repository dialog with this repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fcabinlab%2Fhassio-addons)

2. Install the "Claude Watchdog" add-on
3. Configure your monitoring preferences (see configuration section below)
4. Start the add-on
5. Configure your Anthropic API credentials (see credentials section)

## Configuration

### Basic Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `claude_model` | Claude model to use for analysis | `claude-3-5-haiku-20241022` |
| `check_interval` | Seconds between monitoring checks | `30` |
| `insight_threshold` | Confidence threshold for alerts (0.0-1.0) | `0.8` |
| `max_daily_api_calls` | Maximum API calls per day | `1000` |
| `cost_limit_daily` | Maximum daily cost in USD | `1.00` |
| `notification_service` | HA notification service to use | `persistent_notification` |
| `enable_learning` | Enable pattern learning | `true` |

### Monitoring Scope

Select which areas to monitor:

- **climate**: Temperature, humidity, HVAC systems
- **security**: Doors, locks, motion sensors, alarms
- **energy**: Power consumption, efficiency monitoring
- **automation_performance**: Automation execution and health
- **device_health**: Device connectivity and battery status
- **patterns**: General behavior pattern analysis

### Example Configuration

```yaml
claude_model: "claude-3-5-haiku-20241022"
check_interval: 30
insight_threshold: 0.8
max_daily_api_calls: 1000
monitoring_scope:
  - "climate"
  - "security"
  - "energy"
cost_limit_daily: 1.00
notification_service: "notify"
enable_learning: true
```

## Setting Up Anthropic API Credentials

Claude Watchdog requires an Anthropic API key to function:

1. **Get an Anthropic API Key**: Visit [console.anthropic.com](https://console.anthropic.com/) to create an account and generate an API key

2. **Add to Home Assistant**: Create a file `/config/claude-watchdog/credentials.json` with:
   ```json
   {
     "api_key": "your-anthropic-api-key-here"
   }
   ```

3. **Secure the File**: The add-on will automatically secure this file with proper permissions

## Cost Management

Claude Watchdog is designed to be cost-effective:

### Default Limits
- **Daily Cost Limit**: $1.00 USD per day
- **Daily API Calls**: 1,000 requests maximum
- **Model**: Claude 3.5 Haiku (fastest, most cost-effective)

### Estimated Costs
- **Check Interval**: 30 seconds = 2,880 checks/day
- **Average Cost**: ~$0.36/day for continuous monitoring
- **Monthly Cost**: ~$11/month for 24/7 intelligent monitoring

### Cost Tracking
- Real-time cost tracking with automatic limits
- Detailed usage statistics and history
- Automatic daily reset of usage counters

## Use Cases

### Predictive Maintenance
```
"Water heater temperature gradually increasing over 3 weeks. 
Recommend scheduling maintenance before potential failure."
```

### Energy Optimization  
```
"HVAC runtime increased 23% this week despite similar weather.
Possible causes: dirty filter, leaky ducts, or schedule inefficiency."
```

### Security Intelligence
```
"Motion patterns suggest unusual activity. 
Recommend reviewing exterior camera footage from 2-4pm daily."
```

### Automation Health
```
"Kitchen lights automation failed 3x this week.
Motion sensor may need recalibration or battery replacement."
```

## Understanding Insights

Claude Watchdog provides different types of insights:

### Insight Types
- **Security**: Unusual access patterns, motion anomalies
- **Energy**: Consumption spikes, efficiency opportunities  
- **Climate**: Temperature control optimization, HVAC patterns
- **Automation**: Performance issues, failed executions
- **Device Health**: Connectivity problems, maintenance needs
- **General**: Pattern recognition, behavioral insights

### Confidence Levels
- **High (0.8-1.0)**: Immediate attention recommended
- **Medium (0.6-0.8)**: Worth investigating
- **Low (0.4-0.6)**: Informational observation

## Notifications

Configure how you receive insights:

### Persistent Notifications (Default)
- Appear in Home Assistant frontend
- Persistent until dismissed
- Include full insight details

### Mobile/Email Notifications
- Configure any Home Assistant notification service
- Set `notification_service` to your preferred service
- Examples: `mobile_app_phone`, `smtp`, `telegram_bot`

## Data Storage

Claude Watchdog stores data in `/config/claude-watchdog/`:

- `insights/`: Analysis results and recommendations
- `patterns/`: Learned behavior patterns (future feature)
- `costs/`: API usage and cost tracking
- `logs/`: Service logs and debug information

## Troubleshooting

### Common Issues

1. **High API Costs**: Adjust `check_interval` or `cost_limit_daily`
2. **Too Many Alerts**: Increase `insight_threshold` value
3. **Missing Insights**: Lower `insight_threshold` or check monitoring scope
4. **API Errors**: Verify Anthropic API key and account status

### Logs

View add-on logs for detailed information:
- Service startup and configuration
- API usage and costs
- Analysis results and insights
- Error messages and debugging info

## Privacy and Security

- **Local Processing**: Only state changes are sent to Claude API
- **No Personal Data**: Entity IDs and states only, no personal information
- **Secure Storage**: Credentials and data stored with restricted permissions
- **Configurable Scope**: Monitor only the domains you choose

## Support

- [Documentation](https://github.com/cabinlab/hassio-addons)
- [Issue Tracker](https://github.com/cabinlab/hassio-addons/issues)  
- [Anthropic Claude Documentation](https://docs.anthropic.com/)

## Credits

Built by Cabin Assistant for intelligent home automation monitoring.