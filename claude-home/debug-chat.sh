#!/bin/bash
# Debug script for Claude Home chat interface

echo "=== Claude Home Chat Debug ==="
echo

# Check if services are running
echo "1. Checking services with supervisorctl..."
supervisorctl status || echo "Supervisord not running?"
echo

# Check ports
echo "2. Checking ports..."
for port in 7681 8001 3000 8080; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✓ Port $port is listening"
    else
        echo "✗ Port $port is NOT listening"
    fi
done
echo

# Check gateway health
echo "3. Testing gateway health..."
curl -s http://localhost:8001/health || echo "Gateway not responding"
echo
echo

# Check UI server
echo "4. Testing UI server..."
curl -s http://localhost:8080/ | head -n 5 || echo "UI server not responding"
echo

# Check chat UI
echo "5. Testing chat UI..."
curl -s http://localhost:3000/ | head -n 5 || echo "Chat UI not responding"
echo

# Check logs
echo "6. Recent errors from logs..."
echo "=== Gateway errors ==="
tail -n 5 /var/log/gateway.err 2>/dev/null || echo "No gateway errors"
echo
echo "=== Chat UI errors ==="
tail -n 5 /var/log/chat-ui.err 2>/dev/null || echo "No chat UI errors"
echo
echo "=== UI server errors ==="
tail -n 5 /var/log/ui.err 2>/dev/null || echo "No UI server errors"

echo
echo "=== Quick fixes to try ==="
echo "1. Replace supervisord.conf with supervisord-fixed.conf"
echo "2. Restart supervisor: supervisorctl reload"
echo "3. Check individual services: supervisorctl start chat-ui"
echo "4. For testing, run chat UI manually:"
echo "   cd /opt/anse && python3 -m http.server 3000"