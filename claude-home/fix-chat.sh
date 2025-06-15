#!/bin/bash
# Quick fix script for Claude Home chat interface

echo "=== Applying Claude Home Chat Fixes ==="

# 1. Fix supervisord.conf
echo "1. Backing up and fixing supervisord.conf..."
cp /etc/supervisor/conf.d/supervisord.conf /etc/supervisor/conf.d/supervisord.conf.bak
cp supervisord-fixed.conf /etc/supervisor/conf.d/supervisord.conf 2>/dev/null || echo "Using existing supervisord.conf"

# 2. Ensure chat UI exists
echo "2. Setting up simple chat UI..."
if [ ! -f /opt/anse/index.html ]; then
    echo "   Creating simple chat UI..."
    mkdir -p /opt/anse
    cp simple-chat.html /opt/anse/index.html 2>/dev/null || echo "<h1>Chat UI</h1>" > /opt/anse/index.html
fi

# 3. Fix gateway script permissions
echo "3. Fixing permissions..."
chmod +x /opt/chat_gateway_mcp.py 2>/dev/null

# 4. Create startup script for ttyd if missing
if [ ! -f /tmp/startup.sh ]; then
    echo "4. Creating startup script..."
    cat > /tmp/startup.sh << 'EOF'
#!/bin/bash
echo "Welcome to Claude Home!"
echo "Starting Claude Code CLI..."
export PATH="/usr/local/bin:$PATH"
claude
EOF
    chmod +x /tmp/startup.sh
fi

# 5. Restart supervisor
echo "5. Restarting services..."
supervisorctl reread
supervisorctl update
supervisorctl restart all

echo
echo "=== Status Check ==="
sleep 3
supervisorctl status

echo
echo "=== Testing endpoints ==="
echo -n "UI Server (8080): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ || echo "Failed"
echo
echo -n "Chat UI (3000): "
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/ || echo "Failed"
echo
echo -n "Gateway (8001): "
curl -s http://localhost:8001/health | jq . 2>/dev/null || echo "Failed"
echo

echo
echo "=== Access URLs ==="
echo "Main UI: http://homeassistant.local:8080/"
echo "Terminal: http://homeassistant.local:7681/"
echo
echo "If chat still doesn't work, try:"
echo "1. Check logs: tail -f /var/log/*.err"
echo "2. Run chat UI manually: cd /opt/anse && python3 -m http.server 3000"
echo "3. Run gateway manually: python3 /opt/chat_gateway_mcp.py --http 8001"