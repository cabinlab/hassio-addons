#!/bin/bash

# Container activity monitoring for security auditing
# This script monitors and logs various container activities

# Function to monitor process activities
monitor_processes() {
    local log_file="/config/claude-config/activity.log"
    local interval=${1:-60}  # Default 60 seconds
    
    while true; do
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') PROCESS_SNAPSHOT:"
            echo "  Active processes: $(ps aux | wc -l)"
            echo "  Node.js processes:"
            ps aux | grep -E '[n]ode' | awk '{print "    PID:"$2" CPU:"$3"% MEM:"$4"% CMD:"$11" "$12" "$13}' || echo "    None"
            echo "  npm processes:"
            ps aux | grep -E '[n]pm' | awk '{print "    PID:"$2" CPU:"$3"% MEM:"$4"% CMD:"$11" "$12" "$13}' || echo "    None"
            echo "  Bash processes:"
            ps aux | grep -E '[b]ash' | awk '{print "    PID:"$2" CPU:"$3"% MEM:"$4"% CMD:"$11" "$12" "$13}' || echo "    None"
            echo "---"
        } >> "$log_file"
        
        sleep "$interval"
    done
}

# Function to monitor network connections
monitor_network() {
    local log_file="/config/claude-config/network.log"
    local interval=${1:-300}  # Default 5 minutes
    
    while true; do
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') NETWORK_SNAPSHOT:"
            echo "  Active connections:"
            netstat -tn 2>/dev/null | grep ESTABLISHED | awk '{print "    "$1" "$4" -> "$5}' || echo "    None"
            echo "  Listening ports:"
            netstat -tln 2>/dev/null | grep LISTEN | awk '{print "    "$1" "$4}' || echo "    None"
            echo "  DNS queries (last 60s):"
            # This is a simplified check - in a real environment you'd use more sophisticated tools
            tail -n 100 /var/log/messages 2>/dev/null | grep -E "$(date '+%H:%M')" | grep -i dns | tail -5 || echo "    None logged"
            echo "---"
        } >> "$log_file"
        
        sleep "$interval"
    done
}

# Function to monitor file system activities  
monitor_filesystem() {
    local log_file="/config/claude-config/filesystem.log"
    local watch_dirs="/config/claude-config /usr/local/bin /tmp"
    
    # Use inotify to watch for file system changes
    if command -v inotifywait >/dev/null 2>&1; then
        inotifywait -m -r --format '%T %w %f %e' --timefmt '%Y-%m-%d %H:%M:%S' $watch_dirs 2>/dev/null | while read line; do
            echo "$line" >> "$log_file"
        done
    else
        # Fallback to periodic checks if inotify not available
        while true; do
            {
                echo "$(date '+%Y-%m-%d %H:%M:%S') FILESYSTEM_CHECK:"
                for dir in $watch_dirs; do
                    if [ -d "$dir" ]; then
                        echo "  $dir: $(ls -la "$dir" 2>/dev/null | wc -l) items"
                        # Check for recently modified files (last 5 minutes)
                        find "$dir" -type f -mmin -5 2>/dev/null | head -10 | while read file; do
                            echo "    Recent: $file ($(stat -c%y "$file" 2>/dev/null))"
                        done
                    fi
                done
                echo "---"
            } >> "$log_file"
            sleep 300  # Check every 5 minutes
        done
    fi
}

# Function to monitor authentication attempts
monitor_auth() {
    local log_file="/config/claude-config/auth.log"
    
    # Monitor credential access patterns
    tail -f /config/claude-config/access.log 2>/dev/null | while read line; do
        case "$line" in
            *"FAILED"*)
                echo "$(date '+%Y-%m-%d %H:%M:%S') AUTH_FAILURE: $line" >> "$log_file"
                ;;
            *"SUCCESS"*)
                echo "$(date '+%Y-%m-%d %H:%M:%S') AUTH_SUCCESS: $line" >> "$log_file"
                ;;
            *"WARNING"*)
                echo "$(date '+%Y-%m-%d %H:%M:%S') AUTH_WARNING: $line" >> "$log_file"
                ;;
        esac
    done &
    
    # Monitor login attempts via ttyd/web interface
    if [ -f "/var/log/nginx/access.log" ]; then
        tail -f /var/log/nginx/access.log 2>/dev/null | grep -E "(POST|login|auth)" | while read line; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') WEB_ACCESS: $line" >> "$log_file"
        done &
    fi
}

# Function to monitor resource usage patterns
monitor_resources() {
    local log_file="/config/claude-config/resources.log"
    local interval=${1:-60}  # Default 60 seconds
    
    while true; do
        {
            echo "$(date '+%Y-%m-%d %H:%M:%S') RESOURCE_USAGE:"
            echo "  Memory:"
            free -m | awk '/^Mem:/ {printf "    Total:%sMB Used:%sMB Free:%sMB Usage:%.1f%%\n", $2, $3, $4, ($3/$2)*100}'
            echo "  CPU Load:"
            cat /proc/loadavg | awk '{printf "    1min:%.2f 5min:%.2f 15min:%.2f\n", $1, $2, $3}'
            echo "  Disk Usage:"
            df -h /tmp 2>/dev/null | tail -1 | awk '{printf "    /tmp: %s used of %s (%s)\n", $3, $2, $5}'
            df -h /config 2>/dev/null | tail -1 | awk '{printf "    /config: %s used of %s (%s)\n", $3, $2, $5}'
            echo "  Open Files:"
            lsof 2>/dev/null | wc -l | awk '{printf "    Total open files: %s\n", $1}'
            echo "---"
        } >> "$log_file"
        
        sleep "$interval"
    done
}

# Function to detect suspicious activities
detect_anomalies() {
    local log_file="/config/claude-config/anomalies.log"
    local interval=${1:-120}  # Default 2 minutes
    
    while true; do
        local alerts=0
        local timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
        
        # Check for unusual process activity
        local node_procs=$(pgrep -c node)
        if [ "$node_procs" -gt 5 ]; then
            echo "$timestamp ANOMALY: Excessive Node.js processes ($node_procs)" >> "$log_file"
            alerts=$((alerts + 1))
        fi
        
        # Check for high memory usage
        local mem_usage=$(free | awk '/^Mem:/ {print int($3*100/$2)}')
        if [ "$mem_usage" -gt 90 ]; then
            echo "$timestamp ANOMALY: High memory usage (${mem_usage}%)" >> "$log_file"
            alerts=$((alerts + 1))
        fi
        
        # Check for unusual file activity
        local recent_files=$(find /tmp -type f -mmin -2 2>/dev/null | wc -l)
        if [ "$recent_files" -gt 20 ]; then
            echo "$timestamp ANOMALY: High file activity in /tmp ($recent_files files)" >> "$log_file"
            alerts=$((alerts + 1))
        fi
        
        # Check for failed authentication attempts
        local failed_auths=$(grep -c "FAILED" /config/claude-config/access.log 2>/dev/null | head -1)
        if [ "$failed_auths" -gt 10 ]; then
            echo "$timestamp ANOMALY: Multiple authentication failures ($failed_auths)" >> "$log_file"
            alerts=$((alerts + 1))
        fi
        
        # Check for unusual network activity
        local connections=$(netstat -tn 2>/dev/null | grep -c ESTABLISHED)
        if [ "$connections" -gt 10 ]; then
            echo "$timestamp ANOMALY: High network connection count ($connections)" >> "$log_file"
            alerts=$((alerts + 1))
        fi
        
        # Log summary if no alerts
        if [ "$alerts" -eq 0 ]; then
            echo "$timestamp STATUS: No anomalies detected" >> "$log_file"
        fi
        
        sleep "$interval"
    done
}

# Function to start all monitoring services
start_monitoring() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting container activity monitoring" >> /config/claude-config/security.log
    
    # Create log files with proper permissions
    mkdir -p /config/claude-config
    for logfile in activity.log network.log filesystem.log auth.log resources.log anomalies.log; do
        touch "/config/claude-config/$logfile"
        chmod 600 "/config/claude-config/$logfile"
    done
    
    # Start monitoring processes in background
    monitor_processes 60 &
    echo $! > /tmp/monitor_processes.pid
    
    monitor_network 300 &
    echo $! > /tmp/monitor_network.pid
    
    monitor_filesystem &
    echo $! > /tmp/monitor_filesystem.pid
    
    monitor_auth &
    echo $! > /tmp/monitor_auth.pid
    
    monitor_resources 60 &
    echo $! > /tmp/monitor_resources.pid
    
    detect_anomalies 120 &
    echo $! > /tmp/detect_anomalies.pid
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - All monitoring services started" >> /config/claude-config/security.log
}

# Function to stop monitoring services
stop_monitoring() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Stopping container activity monitoring" >> /config/claude-config/security.log
    
    # Kill monitoring processes
    for pidfile in /tmp/monitor_*.pid; do
        if [ -f "$pidfile" ]; then
            local pid=$(cat "$pidfile")
            kill "$pid" 2>/dev/null && echo "Stopped monitoring process $pid"
            rm -f "$pidfile"
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - All monitoring services stopped" >> /config/claude-config/security.log
}

# Function to show monitoring status
status_monitoring() {
    echo "Container Activity Monitoring Status:"
    echo "===================================="
    
    local active=0
    for pidfile in /tmp/monitor_*.pid; do
        if [ -f "$pidfile" ]; then
            local pid=$(cat "$pidfile")
            if kill -0 "$pid" 2>/dev/null; then
                echo "✓ $(basename "$pidfile" .pid): Running (PID $pid)"
                active=$((active + 1))
            else
                echo "✗ $(basename "$pidfile" .pid): Not running"
                rm -f "$pidfile"
            fi
        fi
    done
    
    echo "Active monitors: $active"
    echo ""
    echo "Recent activity summary:"
    echo "- Processes: $(tail -1 /config/claude-config/activity.log 2>/dev/null | grep -o '[0-9]* processes' || echo 'No data')"
    echo "- Network: $(tail -1 /config/claude-config/network.log 2>/dev/null | grep -o 'ESTABLISHED.*' || echo 'No data')"
    echo "- Auth events: $(grep -c "$(date '+%Y-%m-%d')" /config/claude-config/auth.log 2>/dev/null || echo '0') today"
    echo "- Anomalies: $(grep -c "ANOMALY" /config/claude-config/anomalies.log 2>/dev/null || echo '0') detected"
}

# Function to cleanup old logs
cleanup_logs() {
    local days=${1:-7}  # Keep logs for 7 days by default
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleaning up logs older than $days days" >> /config/claude-config/security.log
    
    for logfile in /config/claude-config/*.log; do
        if [ -f "$logfile" ]; then
            # Keep only recent entries (approximate cleanup)
            tail -n 10000 "$logfile" > "$logfile.tmp" 2>/dev/null
            mv "$logfile.tmp" "$logfile" 2>/dev/null
        fi
    done
}

# Main execution based on command
case "$1" in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    status)
        status_monitoring
        ;;
    cleanup)
        cleanup_logs "$2"
        ;;
    restart)
        stop_monitoring
        sleep 2
        start_monitoring
        ;;
    *)
        echo "Usage: $0 {start|stop|status|cleanup|restart}"
        echo "  start   - Start all monitoring services"
        echo "  stop    - Stop all monitoring services"  
        echo "  status  - Show monitoring status"
        echo "  cleanup - Clean up old log files"
        echo "  restart - Restart all monitoring services"
        exit 1
        ;;
esac