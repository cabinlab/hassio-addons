# Configuration

Monitor your APC UPS device with automatic shutdown protection when power fails.

## Basic Settings

**name**: Display name for your UPS device  
**cable**: Connection type (USB, Smart serial, Simple serial, Ethernet)  
**type**: Communication protocol (USB, Network, APC Smart, etc.)  
**device**: Device path or IP address (leave empty for auto-detection)  

## Power Management

**battery_level**: Battery percentage that triggers shutdown (1-95%, default: 5%)  
**timeout_minutes**: Minutes to wait on battery before shutdown (1-60, default: 3)

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

### Auto-Discovery (Recommended)

The add-on automatically configures Home Assistant's native APC UPS Daemon integration when `auto_discovery` is enabled (default).

**What it does:**
- Detects existing apcupsd integration configuration
- Automatically sets up integration via Supervisor API (host: "apcupsd", port: 3551)
- Falls back to configuration.yaml method if needed
- Sends notification when complete

**No manual setup required!** The integration appears in Settings > Devices & Services automatically.

### Manual Configuration (if auto-discovery disabled)

**For configuration.yaml method:**
```yaml
apcupsd:
  host: "apcupsd"  # Add-on hostname on internal network
  port: 3551
```

**For UI integration setup:**
- Go to Settings > Devices & Services > Add Integration
- Search for "APC UPS Daemon" 
- Enter Host: `apcupsd` and Port: `3551`
- The add-on slug name "apcupsd" is the correct hostname for internal network access

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

## UPS Power Control Services

The add-on provides Home Assistant services for remote UPS power control:

### Available Services

**`apcupsd.ups_shutdown_return`**
- Gracefully shuts down UPS with automatic restart when power returns
- Parameters: `delay` (seconds, default: 20)
- Use for: Planned maintenance, testing power restoration

**`apcupsd.ups_load_off`**  
- Cuts power to UPS outlets after delay
- Parameters: `delay` (seconds, default: 10)
- ⚠️ **WARNING**: Immediately shuts down connected equipment

**`apcupsd.ups_load_on`**
- Restores power to UPS outlets after delay  
- Parameters: `delay` (seconds, default: 5)
- Use for: Restoring power after controlled shutdown

**`apcupsd.ups_reboot`**
- Reboots UPS (shutdown then restart)
- Parameters: `off_delay`, `on_delay` (seconds)
- Use for: Power cycling connected equipment

**`apcupsd.ups_emergency_kill`**
- Immediately cuts all UPS power (no delay)
- ⚠️ **DANGER**: Emergency use only - causes immediate power loss

### Service Call Examples

```yaml
# Automation example - graceful shutdown during extended outage
automation:
  - alias: "UPS Extended Outage Shutdown"
    trigger:
      - platform: numeric_state
        entity_id: sensor.apc_ups_time_left
        below: 300  # 5 minutes remaining
    action:
      - service: apcupsd.ups_shutdown_return
        data:
          delay: 60  # 1 minute warning

# Manual power cycling via script
script:
  reboot_server_ups:
    sequence:
      - service: apcupsd.ups_reboot
        data:
          off_delay: 10   # Power off in 10 seconds
          on_delay: 30    # Power on after 30 seconds
```

### Safety Notes

- **Kill vs Shutdown**: `emergency_kill` cuts power immediately; other commands provide graceful coordination
- **Service Dependencies**: Power control stops/restarts apcupsd daemon temporarily
- **Recovery**: UPS automatically restarts monitoring after power control operations
- **Validation**: All delays are validated (0-7200 seconds)

## Security Considerations

- Scripts are validated for size and permissions
- Configuration values are sanitized
- File access is restricted to `/share/apcupsd/`
- API tokens are handled securely
- Maximum limits prevent resource exhaustion
- Power control commands require manager role permissions