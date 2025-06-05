# APC UPS Daemon

Monitor and manage APC UPS devices with native apcupsd integration for Home Assistant.

## Features

- **Native APC Support**: Direct apcupsd integration optimized for APC UPS devices
- **22 UPS Events**: Complete event handling (onbattery, offbattery, commfailure, etc.)
- **Host Control**: Safe shutdown/reboot through Home Assistant Supervisor API
- **Custom Scripts**: Run custom scripts on any UPS event
- **Email Notifications**: Built-in msmtp support for alerts
- **USB & Network**: Supports both USB-connected and network UPS devices
- **Secure**: Comprehensive input validation and sanitization

## Installation

1. Add this repository to Home Assistant: `https://github.com/cabinlab/hassio-addons`
2. Install the "APC UPS Daemon" add-on
3. Configure your UPS settings
4. Start the add-on

## Configuration

### Basic Options

| Option | Description | Default |
|--------|-------------|---------|
| `name` | UPS display name | `APC UPS` |
| `cable` | Cable type (usb, smart, ether, etc.) | `usb` |
| `type` | UPS type (usb, net, apcsmart, etc.) | `usb` |
| `device` | Device path or IP (auto-detected if empty) | `""` |

### Example Configuration

```yaml
name: "Office UPS"
cable: "usb"
type: "usb"
device: ""  # Auto-detect USB device
extra:
  - key: "BATTERYLEVEL"
    val: "20"
  - key: "MINUTES"
    val: "5"
```

### Advanced Configuration

Use the `extra` option to override any `apcupsd.conf` setting:

```yaml
extra:
  - key: "KILLDELAY"
    val: "10"
  - key: "NISPORT" 
    val: "5555"
  - key: "BATTERYLEVEL"
    val: "15"
```

## Home Assistant Integration

### Sensor Configuration

Add to your `configuration.yaml`:

```yaml
apcupsd:
  host: !secret apcupsd_host  # Use add-on hostname
  port: 3551
```

Then configure the [apcupsd integration](https://www.home-assistant.io/integrations/apcupsd/) sensors:

```yaml
sensor:
  - platform: apcupsd
    resources:
      - status
      - linev
      - loadpct
      - bcharge
      - timeleft
      - mbattchg
      - mintimel
      - maxtime
```

### Finding the Add-on Hostname

The hostname follows the pattern: `{addon_slug}` where characters are replaced with hyphens.
You can find it in the add-on logs when it starts.

## Custom Event Scripts

### Supported Events

- `onbattery` - UPS on battery power
- `offbattery` - UPS back on mains power  
- `commfailure` - Communication with UPS lost
- `commok` - Communication restored
- `changeme` - Battery needs replacement
- `doshutdown` - UPS initiating shutdown
- `doreboot` - UPS initiating reboot
- `emergency` - Emergency shutdown
- `failing` - UPS battery failing
- `loadlimit` - Load limit exceeded
- `powerout` - Power failure detected
- `mainsback` - Mains power restored
- `remotedown` - Remote shutdown requested
- `runlimit` - Runtime limit exceeded
- `timeout` - Timeout occurred
- `startselftest` - Self-test started
- `endselftest` - Self-test completed
- `battdetach` - Battery disconnected
- `battattach` - Battery reconnected

### Script Setup

1. Create directory: `/share/apcupsd/scripts/`
2. Add executable scripts with event names (no `.sh` extension)
3. Use `exit 99` to prevent default actions

**Example `/share/apcupsd/scripts/onbattery`:**

```bash
#!/bin/bash
echo "UPS on battery - sending notification"
curl -X POST "https://api.pushover.net/1/messages.json" \
  -d "token=YOUR_TOKEN" \
  -d "user=YOUR_USER" \
  -d "message=UPS is now running on battery power"
```

## Email Notifications

### Configuration

Create `/share/apcupsd/msmtprc`:

```
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
syslog         on

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-password

account default : gmail
```

Create `/share/apcupsd/aliases`:

```
root: your-email@gmail.com
```

### Security Note

Use app-specific passwords, not your main account password.

## Troubleshooting

### Common Issues

1. **UPS not detected**: Check USB connections and device permissions
2. **Communication errors**: Verify cable type matches your UPS
3. **Host control fails**: Ensure add-on has `manager` role
4. **Scripts not running**: Check file permissions and paths

### Logging

View add-on logs for detailed information:
- Configuration validation
- UPS status changes  
- Script execution
- API calls

## Migration from Original Add-on

This add-on is compatible with the original configuration format. Simply:

1. Install this modernized version
2. Copy your existing configuration
3. Update repository URL if needed

## Support

- [Documentation](https://github.com/cabinlab/hassio-addons)
- [Issue Tracker](https://github.com/cabinlab/hassio-addons/issues)
- [Home Assistant apcupsd Integration](https://www.home-assistant.io/integrations/apcupsd/)
