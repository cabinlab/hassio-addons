#!/bin/bash

# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
	logger "Stopping Hass.io Access Point" 0
	ifdown $INTERFACE
	ip link set $INTERFACE down
	ip addr flush dev $INTERFACE
	exit 0
}

# Logging function to set verbosity of output to addon log
logger(){
    msg=$1
    level=$2
    if [ $DEBUG -ge $level ]; then
        echo $msg
    fi
}

# Input validation functions
validate_ssid() {
    local ssid="$1"
    # SSID must be 1-32 characters, no control characters
    if [[ -z "$ssid" || ${#ssid} -gt 32 || "$ssid" =~ [[:cntrl:]] ]]; then
        return 1
    fi
    return 0
}

validate_passphrase() {
    local pass="$1"
    # WPA passphrase must be 8-63 characters
    if [[ -z "$pass" || ${#pass} -lt 8 || ${#pass} -gt 63 ]]; then
        return 1
    fi
    return 0
}

validate_ip() {
    local ip="$1"
    # Basic IP validation
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 1
    fi
    # Check each octet is 0-255
    IFS='.' read -ra octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [[ $octet -gt 255 ]]; then
            return 1
        fi
    done
    return 0
}

validate_mac() {
    local mac="$1"
    # MAC address format validation
    if [[ ! "$mac" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
        return 1
    fi
    return 0
}

validate_channel() {
    local channel="$1"
    # WiFi channels 1-14 for 2.4GHz
    if [[ ! "$channel" =~ ^[0-9]+$ ]] || [[ $channel -lt 1 || $channel -gt 14 ]]; then
        return 1
    fi
    return 0
}

# Sanitize string for safe config file injection
sanitize_config_value() {
    local value="$1"
    # Remove potentially dangerous characters
    echo "$value" | sed 's/[;&|`$(){}]/\\_/g' | tr -d '\n\r'
}

CONFIG_PATH=/data/options.json

SSID=$(jq --raw-output ".ssid" $CONFIG_PATH)
WPA_PASSPHRASE=$(jq --raw-output ".wpa_passphrase" $CONFIG_PATH)
CHANNEL=$(jq --raw-output ".channel" $CONFIG_PATH)
ADDRESS=$(jq --raw-output ".address" $CONFIG_PATH)
NETMASK=$(jq --raw-output ".netmask" $CONFIG_PATH)
BROADCAST=$(jq --raw-output ".broadcast" $CONFIG_PATH)
INTERFACE=$(jq --raw-output ".interface" $CONFIG_PATH)
HIDE_SSID=$(jq --raw-output ".hide_ssid" $CONFIG_PATH)
DHCP=$(jq --raw-output ".dhcp" $CONFIG_PATH)
DHCP_START_ADDR=$(jq --raw-output ".dhcp_start_addr" $CONFIG_PATH)
DHCP_END_ADDR=$(jq --raw-output ".dhcp_end_addr" $CONFIG_PATH)
DNSMASQ_CONFIG_OVERRIDE=$(jq --raw-output '.dnsmasq_config_override | join(" ")' $CONFIG_PATH)
ALLOW_MAC_ADDRESSES=$(jq --raw-output '.allow_mac_addresses | join(" ")' $CONFIG_PATH)
DENY_MAC_ADDRESSES=$(jq --raw-output '.deny_mac_addresses | join(" ")' $CONFIG_PATH)
DEBUG=$(jq --raw-output '.debug' $CONFIG_PATH)
HOSTAPD_CONFIG_OVERRIDE=$(jq --raw-output '.hostapd_config_override | join(" ")' $CONFIG_PATH)
CLIENT_INTERNET_ACCESS=$(jq --raw-output ".client_internet_access" $CONFIG_PATH)
CLIENT_DNS_OVERRIDE=$(jq --raw-output '.client_dns_override | join(" ")' $CONFIG_PATH)
DNSMASQ_CONFIG_OVERRIDE=$(jq --raw-output '.dnsmasq_config_override | join(" ")' $CONFIG_PATH)

# Get the Default Route interface with validation
DEFAULT_ROUTE_INTERFACE=$(ip route show default | awk '/^default/ { print $5 }' | head -1)
if [[ -z "$DEFAULT_ROUTE_INTERFACE" ]]; then
    logger "Warning: No default route found" 0
fi

# Set interface as wlan0 if not specified in config, validate interface name
if [ ${#INTERFACE} -eq 0 ]; then
    INTERFACE="wlan0"
fi

# Validate interface name format
if [[ ! "$INTERFACE" =~ ^[a-zA-Z0-9]+$ ]] || [[ ${#INTERFACE} -gt 15 ]]; then
    echo >&2 "Error: Invalid interface name format: $INTERFACE"
    exit 1
fi

# Set debug as 0 if not specified in config, validate range
if [ ${#DEBUG} -eq 0 ]; then
    DEBUG=0
fi

# Validate debug level is numeric and in valid range
if [[ ! "$DEBUG" =~ ^[0-9]+$ ]] || [[ $DEBUG -gt 3 ]]; then
    echo >&2 "Error: Debug level must be 0-3"
    exit 1
fi

echo "Starting Hass.io Access Point Addon"

# Setup interface
logger "# Setup interface:" 1
logger "Add to /etc/network/interfaces: iface $INTERFACE inet static" 1
# Create and add our interface to interfaces file
echo "iface $INTERFACE inet static"$'\n' >> /etc/network/interfaces

logger "Run command: nmcli dev set $INTERFACE managed no" 1
nmcli dev set $INTERFACE managed no

logger "Run command: ip link set $INTERFACE down" 1
ip link set $INTERFACE down

logger "Add to /etc/network/interfaces: address $ADDRESS" 1
echo "address $ADDRESS"$'\n' >> /etc/network/interfaces
logger "Add to /etc/network/interfaces: netmask $NETMASK" 1
echo "netmask $NETMASK"$'\n' >> /etc/network/interfaces
logger "Add to /etc/network/interfaces: broadcast $BROADCAST" 1
echo "broadcast $BROADCAST"$'\n' >> /etc/network/interfaces

logger "Run command: ip link set $INTERFACE up" 1
ip link set $INTERFACE up

# Setup signal handlers
trap 'term_handler' SIGTERM

# Validate all required configuration values
error=0

# Validate SSID
if ! validate_ssid "$SSID"; then
    error=1
    echo >&2 "Error: SSID must be 1-32 characters with no control characters."
fi

# Validate passphrase
if ! validate_passphrase "$WPA_PASSPHRASE"; then
    error=1
    echo >&2 "Error: WPA passphrase must be 8-63 characters."
fi

# Validate channel
if ! validate_channel "$CHANNEL"; then
    error=1
    echo >&2 "Error: Channel must be a number between 1-14."
fi

# Validate IP addresses
for ip_var in ADDRESS DHCP_START_ADDR DHCP_END_ADDR; do
    ip_value="${!ip_var}"
    if [[ -n "$ip_value" ]] && ! validate_ip "$ip_value"; then
        error=1
        echo >&2 "Error: $ip_var contains invalid IP address format."
    fi
done

# Validate netmask and broadcast
if ! validate_ip "$NETMASK"; then
    error=1
    echo >&2 "Error: NETMASK contains invalid IP address format."
fi

if ! validate_ip "$BROADCAST"; then
    error=1
    echo >&2 "Error: BROADCAST contains invalid IP address format."
fi

# Validate MAC addresses in allow/deny lists
if [[ -n "$ALLOW_MAC_ADDRESSES" ]]; then
    ALLOWED=($ALLOW_MAC_ADDRESSES)
    for mac in "${ALLOWED[@]}"; do
        if ! validate_mac "$mac"; then
            error=1
            echo >&2 "Error: Invalid MAC address in allow list: $mac"
        fi
    done
fi

if [[ -n "$DENY_MAC_ADDRESSES" ]]; then
    DENIED=($DENY_MAC_ADDRESSES)
    for mac in "${DENIED[@]}"; do
        if ! validate_mac "$mac"; then
            error=1
            echo >&2 "Error: Invalid MAC address in deny list: $mac"
        fi
    done
fi

# Sanitise and validate config values
if [[ ! "$HIDE_SSID" =~ ^[01]$ ]]; then
    HIDE_SSID=0
fi

if [[ ! "$DHCP" =~ ^[01]$ ]]; then
    DHCP=0
fi

if [[ ! "$CLIENT_INTERNET_ACCESS" =~ ^[01]$ ]]; then
    CLIENT_INTERNET_ACCESS=0
fi

# Exit if any validation errors occurred
if [[ $error -eq 1 ]]; then
    echo >&2 "Configuration validation failed. Please check your settings."
    exit 1
fi

# Setup hostapd.conf with sanitized values
logger "# Setup hostapd:" 1
logger "Add to hostapd.conf: ssid=$SSID" 1
echo "ssid=$(sanitize_config_value "$SSID")"$'\n' >> /hostapd.conf
logger "Add to hostapd.conf: wpa_passphrase=********" 1
echo "wpa_passphrase=$(sanitize_config_value "$WPA_PASSPHRASE")"$'\n' >> /hostapd.conf
logger "Add to hostapd.conf: channel=$CHANNEL" 1
echo "channel=$CHANNEL"$'\n' >> /hostapd.conf
logger "Add to hostapd.conf: ignore_broadcast_ssid=$HIDE_SSID" 1
echo "ignore_broadcast_ssid=$HIDE_SSID"$'\n' >> /hostapd.conf

### MAC address filtering
## Allow is more restrictive, so we prioritise that and set
## macaddr_acl to 1, and add allowed MAC addresses to hostapd.allow
if [ ${#ALLOW_MAC_ADDRESSES} -ge 1 ]; then
    logger "Add to hostapd.conf: macaddr_acl=1" 1
    echo "macaddr_acl=1"$'\n' >> /hostapd.conf
    ALLOWED=($ALLOW_MAC_ADDRESSES)
    logger "# Setup hostapd.allow:" 1
    logger "Allowed MAC addresses:" 0
    for mac in "${ALLOWED[@]}"; do
        echo "$mac"$'\n' >> /hostapd.allow
        logger "$mac" 0
    done
    logger "Add to hostapd.conf: accept_mac_file=/hostapd.allow" 1
    echo "accept_mac_file=/hostapd.allow"$'\n' >> /hostapd.conf
## else set macaddr_acl to 0, and add denied MAC addresses to hostapd.deny
    else
        if [ ${#DENY_MAC_ADDRESSES} -ge 1 ]; then
            logger "Add to hostapd.conf: macaddr_acl=0" 1
            echo "macaddr_acl=0"$'\n' >> /hostapd.conf
            DENIED=($DENY_MAC_ADDRESSES)
            logger "Denied MAC addresses:" 0
            for mac in "${DENIED[@]}"; do
                echo "$mac"$'\n' >> /hostapd.deny
                logger "$mac" 0
            done
            logger "Add to hostapd.conf: accept_mac_file=/hostapd.deny" 1
            echo "deny_mac_file=/hostapd.deny"$'\n' >> /hostapd.conf
## else set macaddr_acl to 0, with blank allow and deny files
            else
                logger "Add to hostapd.conf: macaddr_acl=0" 1
                echo "macaddr_acl=0"$'\n' >> /hostapd.conf
        fi

fi

# Set address for the selected interface. Not sure why this is now not being set via /etc/network/interfaces, but maybe interfaces file is no longer required...
ifconfig $INTERFACE $ADDRESS netmask $NETMASK broadcast $BROADCAST

# Add interface to hostapd.conf
logger "Add to hostapd.conf: interface=$INTERFACE" 1
echo "interface=$INTERFACE"$'\n' >> /hostapd.conf

# Append override options to hostapd.conf with validation
if [ ${#HOSTAPD_CONFIG_OVERRIDE} -ge 1 ]; then
    logger "# Custom hostapd config options:" 0
    HOSTAPD_OVERRIDES=($HOSTAPD_CONFIG_OVERRIDE)
    override_count=0
    for override in "${HOSTAPD_OVERRIDES[@]}"; do
        # Limit number of overrides and sanitize content
        if [[ $override_count -ge 20 ]]; then
            logger "Warning: Maximum 20 hostapd config overrides allowed" 0
            break
        fi
        # Basic validation - must contain = and be reasonable length
        if [[ "$override" =~ ^[a-zA-Z0-9_-]+=[a-zA-Z0-9._/-]+$ ]] && [[ ${#override} -le 100 ]]; then
            sanitized_override=$(sanitize_config_value "$override")
            echo "$sanitized_override"$'\n' >> /hostapd.conf
            logger "Add to hostapd.conf: $sanitized_override" 0
            ((override_count++))
        else
            logger "Warning: Skipping invalid hostapd override: $override" 0
        fi
    done
fi

# Setup dnsmasq.conf if DHCP is enabled in config
if [ $DHCP -eq 1 ]; then
    logger "# DHCP enabled. Setup dnsmasq:" 1
    logger "Add to dnsmasq.conf: dhcp-range=$DHCP_START_ADDR,$DHCP_END_ADDR,12h" 1
        echo "dhcp-range=$DHCP_START_ADDR,$DHCP_END_ADDR,12h"$'\n' >> /dnsmasq.conf
        logger "Add to dnsmasq.conf: interface=$INTERFACE" 1
        echo "interface=$INTERFACE"$'\n' >> /dnsmasq.conf

    ## DNS
    dns_array=()
        if [ ${#CLIENT_DNS_OVERRIDE} -ge 1 ]; then
            dns_string="dhcp-option=6"
            DNS_OVERRIDES=($CLIENT_DNS_OVERRIDE)
            dns_count=0
            for override in "${DNS_OVERRIDES[@]}"; do
                # Limit number of DNS servers and validate IP format
                if [[ $dns_count -ge 8 ]]; then
                    logger "Warning: Maximum 8 DNS servers allowed" 0
                    break
                fi
                if validate_ip "$override"; then
                    dns_string+=",$override"
                    ((dns_count++))
                else
                    logger "Warning: Skipping invalid DNS server IP: $override" 0
                fi
            done
            if [[ $dns_count -gt 0 ]]; then
                echo "$dns_string"$'\n' >> /dnsmasq.conf
                logger "Add custom DNS: $dns_string" 0
            fi
        else
            IFS=$'\n' read -r -d '' -a dns_array < <( nmcli device show | grep IP4.DNS | awk '{print $2}' && printf '\0' )

            if [ ${#dns_array[@]} -eq 0 ]; then
                logger "Couldn't get DNS servers from host. Consider setting with 'client_dns_override' config option." 0
            else
                dns_string="dhcp-option=6"
                for dns_entry in "${dns_array[@]}"; do
                    dns_string+=",$dns_entry"
        
        
                done
                echo "$dns_string"$'\n' >> /dnsmasq.conf
                logger "Add DNS: $dns_string" 0
            fi

        fi

    # Append override options to dnsmasq.conf with validation
    if [ ${#DNSMASQ_CONFIG_OVERRIDE} -ge 1 ]; then
        logger "# Custom dnsmasq config options:" 0
        DNSMASQ_OVERRIDES=($DNSMASQ_CONFIG_OVERRIDE)
        override_count=0
        for override in "${DNSMASQ_OVERRIDES[@]}"; do
            # Limit number of overrides and sanitize content
            if [[ $override_count -ge 20 ]]; then
                logger "Warning: Maximum 20 dnsmasq config overrides allowed" 0
                break
            fi
            # Basic validation for dnsmasq config format
            if [[ "$override" =~ ^[a-zA-Z0-9_-]+([=:][a-zA-Z0-9._:,/-]+)?$ ]] && [[ ${#override} -le 100 ]]; then
                sanitized_override=$(sanitize_config_value "$override")
                echo "$sanitized_override"$'\n' >> /dnsmasq.conf
                logger "Add to dnsmasq.conf: $sanitized_override" 0
                ((override_count++))
            else
                logger "Warning: Skipping invalid dnsmasq override: $override" 0
            fi
        done
    fi
    
    # Setup Client Internet Access
    if [ $CLIENT_INTERNET_ACCESS -eq 1 ]; then

        ## Route traffic
        iptables-nft -t nat -A POSTROUTING -o $DEFAULT_ROUTE_INTERFACE -j MASQUERADE
        iptables-nft -P FORWARD ACCEPT
        iptables-nft -F FORWARD
    fi
else
	logger "# DHCP not enabled. Skipping dnsmasq" 1
    # Setup Client Internet Access
    ## No DHCP == No DNS. Must be set manually on client.
    ## Step 1: Routing
    if [ $CLIENT_INTERNET_ACCESS -eq 1 ]; then
        iptables-nft -t nat -A POSTROUTING -o $DEFAULT_ROUTE_INTERFACE -j MASQUERADE
        iptables-nft -P FORWARD ACCEPT
        iptables-nft -F FORWARD
    fi
fi

# Start dnsmasq if DHCP is enabled in config
if [ $DHCP -eq 1 ]; then
    logger "## Starting dnsmasq daemon" 1
	killall -q dnsmasq; dnsmasq -C /dnsmasq.conf
fi

logger "## Starting hostapd daemon" 1
# If debug level is greater than 1, start hostapd in debug mode
if [ $DEBUG -gt 1 ]; then
    killall -q hostapd; hostapd -d /hostapd.conf & wait ${!}
else
    killall -q hostapd; hostapd /hostapd.conf & wait ${!}
fi
