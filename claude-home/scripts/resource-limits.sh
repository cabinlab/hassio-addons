#!/bin/bash

# Process resource limits for container security
# This script implements ulimit controls and resource restrictions

# Function to apply process resource limits
apply_resource_limits() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Applying process resource limits" >> /config/claude-config/security.log
    
    # File descriptor limits (prevent fd exhaustion)
    ulimit -n 1024  # Max open files: 1024 (default is often 4096+)
    
    # Process limits (prevent fork bombs)
    ulimit -u 256   # Max user processes: 256
    
    # Memory limits (prevent memory exhaustion)
    ulimit -v 1048576  # Virtual memory: 1GB (in KB)
    ulimit -m 524288   # Resident memory: 512MB (in KB)
    
    # CPU limits (prevent CPU exhaustion)
    ulimit -t 3600     # CPU time: 1 hour per process
    
    # File size limits (prevent disk exhaustion)
    ulimit -f 102400   # Max file size: 100MB (in KB)
    
    # Core dump limits (security - disable core dumps)
    ulimit -c 0        # No core dumps
    
    # Stack size limits (prevent stack overflow attacks)
    ulimit -s 8192     # Stack size: 8MB (in KB)
    
    # Nice priority limits (prevent priority escalation)
    ulimit -e 0        # Max nice priority: 0 (normal)
    
    # Log applied limits
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Resource limits applied:" >> /config/claude-config/security.log
    echo "  File descriptors: $(ulimit -n)" >> /config/claude-config/security.log
    echo "  User processes: $(ulimit -u)" >> /config/claude-config/security.log
    echo "  Virtual memory: $(ulimit -v)KB" >> /config/claude-config/security.log
    echo "  CPU time: $(ulimit -t)s" >> /config/claude-config/security.log
    echo "  File size: $(ulimit -f)KB" >> /config/claude-config/security.log
    echo "  Core dumps: $(ulimit -c)" >> /config/claude-config/security.log
    echo "  Stack size: $(ulimit -s)KB" >> /config/claude-config/security.log
}

# Function to apply container-specific cgroup limits
apply_cgroup_limits() {
    # Note: These are additional recommendations for container runtime
    # Actual cgroup limits should be set at the container/docker level
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Container cgroup recommendations:" >> /config/claude-config/security.log
    echo "  Recommended docker run flags:" >> /config/claude-config/security.log
    echo "    --memory=512m (limit memory to 512MB)" >> /config/claude-config/security.log
    echo "    --cpus=1.0 (limit to 1 CPU)" >> /config/claude-config/security.log
    echo "    --pids-limit=256 (limit number of processes)" >> /config/claude-config/security.log
    echo "    --ulimit nofile=1024:1024 (file descriptor limits)" >> /config/claude-config/security.log
    echo "    --ulimit nproc=256:256 (process limits)" >> /config/claude-config/security.log
}

# Function to monitor current resource usage
monitor_resource_usage() {
    local log_file="/config/claude-config/resource-usage.log"
    
    # Create usage log if it doesn't exist
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
        chmod 600 "$log_file"
    fi
    
    # Log current resource usage
    {
        echo "$(date '+%Y-%m-%d %H:%M:%S') Resource Usage:"
        echo "  Memory: $(cat /proc/meminfo | grep MemAvailable | awk '{print $2}') kB available"
        echo "  Load: $(cat /proc/loadavg)"
        echo "  Processes: $(ps aux | wc -l) running"
        echo "  Open files: $(lsof 2>/dev/null | wc -l) open file descriptors"
        echo "  Disk usage: $(df /tmp | tail -1 | awk '{print $5}') /tmp usage"
        echo "---"
    } >> "$log_file"
    
    # Keep only last 100 entries
    tail -n 500 "$log_file" > "$log_file.tmp" 2>/dev/null
    mv "$log_file.tmp" "$log_file" 2>/dev/null
}

# Function to check for resource limit violations
check_resource_violations() {
    local violations=0
    
    # Check if we're approaching limits
    local open_files=$(lsof 2>/dev/null | wc -l)
    local max_files=$(ulimit -n)
    if [ "$open_files" -gt $((max_files * 80 / 100)) ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: High file descriptor usage: $open_files/$max_files" >> /config/claude-config/security.log
        violations=$((violations + 1))
    fi
    
    # Check process count
    local process_count=$(ps aux | wc -l)
    local max_processes=$(ulimit -u)
    if [ "$process_count" -gt $((max_processes * 80 / 100)) ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: High process count: $process_count/$max_processes" >> /config/claude-config/security.log
        violations=$((violations + 1))
    fi
    
    # Check memory usage (approximate)
    local mem_usage=$(free | awk '/^Mem:/ {print int($3*100/$2)}')
    if [ "$mem_usage" -gt 90 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: High memory usage: ${mem_usage}%" >> /config/claude-config/security.log
        violations=$((violations + 1))
    fi
    
    return $violations
}

# Function to enforce security policies
enforce_security_policies() {
    # Disable core dumps system-wide
    echo "* soft core 0" >> /etc/security/limits.conf 2>/dev/null || true
    echo "* hard core 0" >> /etc/security/limits.conf 2>/dev/null || true
    
    # Set process limits in limits.conf
    echo "* soft nproc 256" >> /etc/security/limits.conf 2>/dev/null || true
    echo "* hard nproc 512" >> /etc/security/limits.conf 2>/dev/null || true
    
    # Set file descriptor limits
    echo "* soft nofile 1024" >> /etc/security/limits.conf 2>/dev/null || true
    echo "* hard nofile 2048" >> /etc/security/limits.conf 2>/dev/null || true
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Security policies enforced" >> /config/claude-config/security.log
}

# Main execution based on command
case "$1" in
    apply)
        apply_resource_limits
        apply_cgroup_limits
        ;;
    monitor)
        monitor_resource_usage
        ;;
    check)
        check_resource_violations
        ;;
    enforce)
        enforce_security_policies
        ;;
    all)
        enforce_security_policies
        apply_resource_limits
        apply_cgroup_limits
        monitor_resource_usage
        check_resource_violations
        ;;
    *)
        echo "Usage: $0 {apply|monitor|check|enforce|all}"
        echo "  apply   - Apply ulimit resource limits"
        echo "  monitor - Log current resource usage"
        echo "  check   - Check for resource violations"
        echo "  enforce - Enforce system security policies"
        echo "  all     - Run all security functions"
        exit 1
        ;;
esac