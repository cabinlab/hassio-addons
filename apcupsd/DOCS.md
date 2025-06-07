# Configuration

This add-on provides native apcupsd integration for monitoring APC UPS devices with an enhanced user interface.

## Options

### Basic Configuration

- **name** (string): Display name for your UPS device
- **cable** (dropdown): Cable type used to connect to UPS
- **type** (dropdown): UPS communication type  
- **device** (string): Device path or IP address (leave empty for auto-detection)

### Power Management Settings

- **battery_level** (1-95): Battery percentage threshold for shutdown (default: 5%)
- **minutes_on_battery** (1-60): Minutes on battery before shutdown (default: 3)
- **max_time_on_battery** (0-7200): Maximum time on battery in seconds (0 = disabled, default: 0)
- **kill_delay** (0-300): Delay before killing processes in seconds (default: 0)

### Network Settings

- **network_port** (1024-65535): Network port for apcupsd daemon (default: 3551)
- **network_timeout** (10-600): Network timeout in seconds (default: 60)

### Advanced Configuration

- **extra** (list): Additional apcupsd configuration options for expert users

### Cable Types

- `usb` - USB connection (most common for modern UPS)
- `smart` - APC smart serial cable
- `simple` - Simple serial cable  
- `ether` - Ethernet/network connection
- `940-0024C`, `940-0095A`, `940-0095B`, `940-0095C` - Specific APC cable models
- `940-1524C`, `940-0128A`, `MAM-04-02-2000` - Legacy cable models

### UPS Types

- `usb` - USB-connected UPS (default)
- `net` - Network UPS (requires device IP)
- `apcsmart` - APC Smart UPS with serial
- `dumb` - Simple contact-closure UPS
- `pcnet` - PowerChute Network
- `snmp` - SNMP-enabled UPS
- `test` - Testing mode
- `modbus` - Modbus communication

## Example Configurations

### USB UPS (Default)
```yaml
name: "Office UPS"
cable: "usb"
type: "usb"
device: ""
extra: []
```

### Network UPS
```yaml
name: "Server Room UPS"
cable: "ether"
type: "net"
device: "192.168.1.100"
extra:
  - key: "NISPORT"
    val: "3551"
```

### Serial Smart UPS
```yaml
name: "Legacy UPS"
cable: "smart"
type: "apcsmart"
device: "/dev/ttyS0"
extra:
  - key: "BATTERYLEVEL"
    val: "20"
  - key: "MINUTES"
    val: "5"
```

## Advanced Options

Use the `extra` configuration to override any apcupsd setting:

### Common Settings

- **BATTERYLEVEL**: Battery percentage for shutdown (default: 5)
- **MINUTES**: Minutes on battery before shutdown (default: 3)
- **KILLDELAY**: Delay before killing processes (default: 0)
- **NISPORT**: Network port for apcupsd daemon (default: 3551)
- **NETTIME**: Network timeout in seconds (default: 60)
- **MAXTIME**: Maximum time on battery (default: 0 = disabled)

### Example Advanced Configuration
```yaml
name: "Critical Server UPS"
cable: "usb"
type: "usb"
device: ""
extra:
  - key: "BATTERYLEVEL"
    val: "30"
  - key: "MINUTES"
    val: "10"
  - key: "KILLDELAY"
    val: "10"
  - key: "MAXTIME"
    val: "1800"
  - key: "NETTIME"
    val: "120"
```

## Home Assistant Integration

### 1. Configure the Integration

Add to `configuration.yaml`:

```yaml
apcupsd:
  host: "apcupsd"  # Add-on hostname
  port: 3551
```

### 2. Add Sensors

```yaml
sensor:
  - platform: apcupsd
    resources:
      - status        # UPS status
      - linev         # Line voltage
      - loadpct       # Load percentage
      - bcharge       # Battery charge
      - timeleft      # Time remaining
      - mbattchg      # Min battery charge
      - mintimel      # Min time left
      - maxtime       # Max time on battery
      - sense         # Sensitivity
      - dwake         # Wake delay
      - dshutd        # Shutdown delay
      - lotrans       # Low transfer point
      - hitrans       # High transfer point
      - retpct        # Return charge percent
      - itemp         # Internal temperature
      - alarmdel      # Alarm delay
      - battv         # Battery voltage
      - linefreq      # Line frequency
      - lastxfer      # Last transfer reason
      - numxfers      # Number of transfers
      - tonbatt       # Time on battery
      - cumonbatt     # Cumulative time on battery
      - xoffbatt      # Last time off battery
      - selftest      # Self-test result
      - stesti        # Self-test interval
      - statflag      # Status flag
      - mandate       # Manufacture date
      - serialno      # Serial number
      - battdate      # Battery date
      - nominv        # Nominal input voltage
      - nombattv      # Nominal battery voltage
      - nompower      # Nominal power
      - firmware      # Firmware version
```

## Custom Event Scripts

### Available Events

The add-on supports all 22 apcupsd events:

- **Power Events**: `onbattery`, `offbattery`, `powerout`, `mainsback`
- **Communication**: `commfailure`, `commok`
- **Battery**: `changeme`, `battdetach`, `battattach`
- **System**: `doshutdown`, `doreboot`, `emergency`
- **Monitoring**: `failing`, `loadlimit`, `runlimit`, `timeout`
- **Testing**: `startselftest`, `endselftest`
- **Control**: `remotedown`, `annoyme`

### Script Directory

Create scripts in `/share/apcupsd/scripts/` with the event name (no extension).

### Example Scripts

**Battery Low Alert** (`/share/apcupsd/scripts/onbattery`):
```bash
#!/bin/bash
# Send notification when UPS switches to battery
curl -X POST "http://supervisor/core/api/services/notify/persistent_notification" \
  -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "UPS is now running on battery power!", "title": "Power Failure"}'
```

**Power Restored** (`/share/apcupsd/scripts/offbattery`):
```bash
#!/bin/bash
# Clear notification when power is restored
curl -X POST "http://supervisor/core/api/services/notify/persistent_notification" \
  -H "Authorization: Bearer $SUPERVISOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "UPS power has been restored.", "title": "Power Restored"}'
```

**Emergency Shutdown Prevention** (`/share/apcupsd/scripts/doshutdown`):
```bash
#!/bin/bash
# Prevent automatic shutdown during business hours
current_hour=$(date +%H)
if [ $current_hour -ge 8 ] && [ $current_hour -le 17 ]; then
    echo "Preventing shutdown during business hours"
    exit 99  # Prevent default shutdown action
fi
```

## Email Notifications

### Configuration Files

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
admin: your-email@gmail.com
```

### Email Script Example

**Email on Communication Failure** (`/share/apcupsd/scripts/commfailure`):
```bash
#!/bin/bash
echo "UPS communication failure detected at $(date)" | \
  mail -s "UPS Communication Failure" root
```

## Troubleshooting

### Debug Mode

Enable debug logging by setting log level to debug in add-on configuration.

### Common Issues

1. **USB Device Not Found**
   - Check USB cable connection
   - Verify UPS is powered on
   - Try different USB port

2. **Permission Denied**
   - Restart Home Assistant
   - Check add-on has manager role

3. **Network UPS Not Responding**
   - Verify IP address is correct
   - Check firewall settings
   - Ensure UPS network card is configured

4. **Scripts Not Executing**
   - Verify file permissions (executable)
   - Check script syntax
   - Review add-on logs

### Log Analysis

Monitor these log messages:
- `UPS name set to: [name]` - Configuration loaded
- `Starting APC UPS daemon...` - Daemon startup
- `Copied custom [event] script` - Script loaded
- `ERROR: Failed to [action]` - Operation failed

## Security Considerations

- Scripts are validated for size and permissions
- Configuration values are sanitized
- File access is restricted to `/share/apcupsd/`
- API tokens are handled securely
- Maximum limits prevent resource exhaustion