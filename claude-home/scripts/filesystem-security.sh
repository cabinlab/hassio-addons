#!/bin/bash

# Filesystem access controls and security policies
# This script implements file permission controls and access restrictions

# Function to setup secure directory permissions
setup_secure_permissions() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Setting up secure filesystem permissions" >> /config/claude-config/security.log
    
    # Secure the main configuration directory
    if [ -d "/config/claude-config" ]; then
        chmod 700 /config/claude-config
        chown root:root /config/claude-config 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Secured /config/claude-config (700)" >> /config/claude-config/security.log
    fi
    
    # Secure subdirectories
    if [ -d "/config/claude-config/backups" ]; then
        chmod 700 /config/claude-config/backups
        chown root:root /config/claude-config/backups 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Secured /config/claude-config/backups (700)" >> /config/claude-config/security.log
    fi
    
    # Secure credential files
    for cred_file in "/config/claude-config/.claude" "/config/claude-config/.claude.json" "/config/claude-config/credentials.json" "/config/claude-config/auth.json"; do
        if [ -f "$cred_file" ]; then
            chmod 600 "$cred_file"
            chown root:root "$cred_file" 2>/dev/null || true
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Secured credential file: $cred_file (600)" >> /config/claude-config/security.log
        fi
    done
    
    # Secure log files
    for log_file in /config/claude-config/*.log; do
        if [ -f "$log_file" ]; then
            chmod 600 "$log_file"
            chown root:root "$log_file" 2>/dev/null || true
        fi
    done
    
    # Secure hash files
    for hash_file in /config/claude-config/*.hash; do
        if [ -f "$hash_file" ]; then
            chmod 600 "$hash_file"
            chown root:root "$hash_file" 2>/dev/null || true
        fi
    done
    
    # Secure script directories
    if [ -d "/usr/local/bin" ]; then
        chmod 755 /usr/local/bin
        for script in /usr/local/bin/credentials-* /usr/local/bin/resource-* /usr/local/bin/app-* /usr/local/bin/activity-* /usr/local/bin/claude-*; do
            if [ -f "$script" ]; then
                chmod 755 "$script"
                chown root:root "$script" 2>/dev/null || true
            fi
        done
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Filesystem permissions setup completed" >> /config/claude-config/security.log
}

# Function to implement access restrictions
implement_access_restrictions() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Implementing filesystem access restrictions" >> /config/claude-config/security.log
    
    # Create restricted directories with proper permissions
    local restricted_dirs="/tmp/claude-restricted /var/claude-temp"
    
    for dir in $restricted_dirs; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            chmod 750 "$dir"
            chown root:root "$dir" 2>/dev/null || true
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Created restricted directory: $dir" >> /config/claude-config/security.log
        fi
    done
    
    # Secure temporary directories
    if [ -d "/tmp" ]; then
        # Ensure /tmp has sticky bit and proper permissions
        chmod 1777 /tmp 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Secured /tmp directory with sticky bit" >> /config/claude-config/security.log
    fi
    
    # Create secure workspace directory
    local workspace="/config/claude-config/workspace"
    if [ ! -d "$workspace" ]; then
        mkdir -p "$workspace"
        chmod 700 "$workspace"
        chown root:root "$workspace" 2>/dev/null || true
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Created secure workspace: $workspace" >> /config/claude-config/security.log
    fi
    
    # Implement file creation umask
    umask 077
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Set secure umask (077)" >> /config/claude-config/security.log
}

# Function to monitor filesystem integrity
monitor_filesystem_integrity() {
    local log_file="/config/claude-config/integrity.log"
    
    # Create integrity log if it doesn't exist
    if [ ! -f "$log_file" ]; then
        touch "$log_file"
        chmod 600 "$log_file"
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting filesystem integrity check" >> "$log_file"
    
    # Check critical directories and files
    local critical_paths="/config/claude-config /usr/local/bin"
    
    for path in $critical_paths; do
        if [ -e "$path" ]; then
            if [ -d "$path" ]; then
                local file_count=$(find "$path" -type f 2>/dev/null | wc -l)
                local dir_perms=$(stat -c%a "$path" 2>/dev/null)
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Directory $path: $file_count files, permissions $dir_perms" >> "$log_file"
            elif [ -f "$path" ]; then
                local file_perms=$(stat -c%a "$path" 2>/dev/null)
                local file_size=$(stat -c%s "$path" 2>/dev/null)
                echo "$(date '+%Y-%m-%d %H:%M:%S') - File $path: $file_size bytes, permissions $file_perms" >> "$log_file"
            fi
        else
            echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Critical path missing: $path" >> "$log_file"
        fi
    done
    
    # Check for unauthorized files in sensitive locations
    local sensitive_dirs="/config/claude-config"
    for dir in $sensitive_dirs; do
        if [ -d "$dir" ]; then
            find "$dir" -type f -not -name "*.log" -not -name "*.hash" -not -name ".claude*" -not -name "credentials.json" -not -name "auth.json" 2>/dev/null | while read file; do
                echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Unexpected file in sensitive location: $file" >> "$log_file"
            done
        fi
    done
    
    # Check for world-writable files (security risk)
    local world_writable=$(find /config /usr/local/bin -type f -perm -002 2>/dev/null | head -10)
    if [ -n "$world_writable" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: World-writable files detected:" >> "$log_file"
        echo "$world_writable" | while read file; do
            echo "$(date '+%Y-%m-%d %H:%M:%S') -   $file" >> "$log_file"
        done
    fi
    
    # Keep log file manageable
    tail -n 500 "$log_file" > "$log_file.tmp" 2>/dev/null
    mv "$log_file.tmp" "$log_file" 2>/dev/null
}

# Function to implement chroot-like restrictions
implement_directory_restrictions() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Implementing directory access restrictions" >> /config/claude-config/security.log
    
    # Create a restricted environment configuration
    local restricted_config="/config/claude-config/filesystem-policy.conf"
    
    cat > "$restricted_config" << 'EOF'
# Filesystem Security Policy Configuration
# This file defines restricted access policies

# Allowed directories for read access
ALLOWED_READ_DIRS="/config /usr/local /tmp /var/log"

# Allowed directories for write access  
ALLOWED_WRITE_DIRS="/config/claude-config /tmp"

# Restricted directories (no access)
RESTRICTED_DIRS="/root/.ssh /etc/shadow /etc/passwd"

# Maximum file sizes (in bytes)
MAX_FILE_SIZE=104857600  # 100MB

# Allowed file extensions
ALLOWED_EXTENSIONS=".json .log .txt .js .md .yaml .yml"

# Blocked file extensions
BLOCKED_EXTENSIONS=".exe .bat .sh .php .py .rb .pl"
EOF
    
    chmod 600 "$restricted_config"
    chown root:root "$restricted_config" 2>/dev/null || true
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Created filesystem policy configuration" >> /config/claude-config/security.log
    
    # Create directory access validation function
    cat > "/usr/local/bin/validate-access" << 'EOF'
#!/bin/bash
# Filesystem access validation helper

validate_file_access() {
    local file_path="$1"
    local operation="$2"  # read, write, execute
    
    # Load policy configuration
    source /config/claude-config/filesystem-policy.conf 2>/dev/null || return 1
    
    # Basic path validation
    case "$file_path" in
        /config/claude-config/*)
            return 0  # Always allow access to our own directory
            ;;
        /tmp/*)
            return 0  # Allow temporary file access
            ;;
        /usr/local/*)
            if [ "$operation" = "read" ] || [ "$operation" = "execute" ]; then
                return 0
            fi
            ;;
        /root/.ssh/*|/etc/shadow|/etc/passwd)
            echo "$(date '+%Y-%m-%d %H:%M:%S') - BLOCKED: Access to restricted path: $file_path" >> /config/claude-config/security.log
            return 1
            ;;
    esac
    
    # Check file extension restrictions
    local extension="${file_path##*.}"
    for blocked_ext in $BLOCKED_EXTENSIONS; do
        if [ ".$extension" = "$blocked_ext" ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - BLOCKED: Restricted file extension: $file_path" >> /config/claude-config/security.log
            return 1
        fi
    done
    
    return 0
}

# Execute validation
validate_file_access "$@"
EOF
    
    chmod 755 "/usr/local/bin/validate-access"
    chown root:root "/usr/local/bin/validate-access" 2>/dev/null || true
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Created filesystem access validator" >> /config/claude-config/security.log
}

# Function to audit file permissions
audit_file_permissions() {
    local audit_log="/config/claude-config/permission-audit.log"
    
    # Create audit log if it doesn't exist
    if [ ! -f "$audit_log" ]; then
        touch "$audit_log"
        chmod 600 "$audit_log"
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting file permission audit" >> "$audit_log"
    
    # Audit critical files and directories
    local audit_paths="/config/claude-config /usr/local/bin"
    
    for path in $audit_paths; do
        if [ -e "$path" ]; then
            find "$path" -type f -o -type d 2>/dev/null | while read item; do
                local perms=$(stat -c%a "$item" 2>/dev/null)
                local owner=$(stat -c%U:%G "$item" 2>/dev/null)
                local type="FILE"
                [ -d "$item" ] && type="DIR"
                
                echo "$(date '+%Y-%m-%d %H:%M:%S') - $type $item $perms $owner" >> "$audit_log"
                
                # Flag potentially unsafe permissions
                if [ -f "$item" ]; then
                    # Check for world-writable files
                    if [ "$((perms & 002))" -ne 0 ]; then
                        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: World-writable file: $item ($perms)" >> "$audit_log"
                    fi
                    # Check for files without owner read permission
                    if [ "$((perms & 400))" -eq 0 ]; then
                        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: Owner cannot read file: $item ($perms)" >> "$audit_log"
                    fi
                elif [ -d "$item" ]; then
                    # Check for world-writable directories without sticky bit
                    if [ "$((perms & 002))" -ne 0 ] && [ "$((perms & 1000))" -eq 0 ]; then
                        echo "$(date '+%Y-%m-%d %H:%M:%S') - WARNING: World-writable directory without sticky bit: $item ($perms)" >> "$audit_log"
                    fi
                fi
            done
        fi
    done
    
    # Keep audit log manageable
    tail -n 1000 "$audit_log" > "$audit_log.tmp" 2>/dev/null
    mv "$audit_log.tmp" "$audit_log" 2>/dev/null
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - File permission audit completed" >> "$audit_log"
}

# Function to fix common permission issues
fix_permission_issues() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Fixing common permission issues" >> /config/claude-config/security.log
    
    local fixed=0
    
    # Fix world-writable files (except /tmp)
    find /config /usr/local/bin -type f -perm -002 -not -path "/tmp/*" 2>/dev/null | while read file; do
        chmod o-w "$file" 2>/dev/null && {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Fixed world-writable file: $file" >> /config/claude-config/security.log
            fixed=$((fixed + 1))
        }
    done
    
    # Fix directories with overly permissive permissions
    find /config/claude-config -type d -perm -077 2>/dev/null | while read dir; do
        chmod 700 "$dir" 2>/dev/null && {
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Fixed directory permissions: $dir" >> /config/claude-config/security.log
            fixed=$((fixed + 1))
        }
    done
    
    # Ensure critical files have secure permissions
    for file in /config/claude-config/*.log /config/claude-config/*.hash; do
        if [ -f "$file" ]; then
            chmod 600 "$file" 2>/dev/null && {
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Secured critical file: $file" >> /config/claude-config/security.log
            }
        fi
    done
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Permission fixes completed ($fixed issues fixed)" >> /config/claude-config/security.log
}

# Main execution based on command
case "$1" in
    setup)
        setup_secure_permissions
        implement_access_restrictions
        implement_directory_restrictions
        ;;
    monitor)
        monitor_filesystem_integrity
        ;;
    audit)
        audit_file_permissions
        ;;
    fix)
        fix_permission_issues
        ;;
    validate)
        /usr/local/bin/validate-access "$2" "$3"
        ;;
    all)
        setup_secure_permissions
        implement_access_restrictions
        implement_directory_restrictions
        monitor_filesystem_integrity
        audit_file_permissions
        ;;
    *)
        echo "Usage: $0 {setup|monitor|audit|fix|validate|all}"
        echo "  setup    - Setup secure filesystem permissions and restrictions"
        echo "  monitor  - Monitor filesystem integrity"
        echo "  audit    - Audit file permissions"
        echo "  fix      - Fix common permission issues"
        echo "  validate - Validate file access (requires path and operation)"
        echo "  all      - Run all filesystem security functions"
        exit 1
        ;;
esac