#!/bin/bash
# Complete fix for Claude Home chat interface

echo "=== Complete Claude Home Chat Fix ==="
echo

# 1. Fix the main UI HTML
echo "1. Fixing UI HTML (missing iframes)..."
if [ -f /opt/ui/index.html ]; then
    cp /opt/ui/index.html /opt/ui/index.html.bak
    if [ -f ui/index-fixed.html ]; then
        cp ui/index-fixed.html /opt/ui/index.html
        echo "   ✓ Replaced with fixed HTML"
    else
        # Quick inline fix
        sed -i 's/<div id="chat-frame"[^>]*>.*<\/div>/<iframe id="chat-frame" src="\/chat\/" title="Chat Interface"><\/iframe>/g' /opt/ui/index.html
        sed -i 's/<div id="terminal-frame"[^>]*>.*<\/div>/<iframe id="terminal-frame" src="\/terminal\/" title="Terminal Interface"><\/iframe>/g' /opt/ui/index.html
        echo "   ✓ Patched HTML inline"
    fi
else
    echo "   ✗ UI HTML not found at /opt/ui/index.html"
fi

# 2. Ensure chat UI directory exists and has content
echo "2. Setting up chat UI content..."
mkdir -p /opt/anse
if [ ! -f /opt/anse/index.html ]; then
    cat > /opt/anse/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Claude Chat</title>
    <style>
        body { 
            font-family: sans-serif; 
            background: #1a1a1a; 
            color: #e0e0e0;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            text-align: center;
            padding: 20px;
        }
        .status {
            background: #2a2a2a;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
        a {
            color: #0084ff;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Claude Chat Interface</h1>
        <div class="status">
            <p>Chat UI is starting up...</p>
            <p>Gateway endpoint: <a href="/v1/chat/completions">/v1/chat/completions</a></p>
            <p>If you see this page, the HTTP server is working!</p>
        </div>
        <p><a href="/terminal/">Open Terminal</a></p>
    </div>
</body>
</html>
EOF
    echo "   ✓ Created placeholder chat UI"
fi

# 3. Check if http-server is actually installed
echo "3. Checking http-server..."
if ! command -v http-server &> /dev/null; then
    echo "   ✗ http-server not found, installing..."
    npm install -g http-server
else
    echo "   ✓ http-server is installed"
fi

# 4. Fix supervisord config if needed
echo "4. Checking supervisord config..."
if grep -q "autostart=false" /etc/supervisor/conf.d/supervisord.conf; then
    echo "   ! Chat-ui is disabled in supervisord"
    sed -i 's/autostart=false/autostart=true/g' /etc/supervisor/conf.d/supervisord.conf
    echo "   ✓ Enabled chat-ui autostart"
fi

# 5. Restart everything
echo "5. Restarting services..."
supervisorctl reread
supervisorctl update
supervisorctl restart all

echo
echo "=== Waiting for services to start... ==="
sleep 5

# 6. Check status
echo
echo "=== Service Status ==="
supervisorctl status

echo
echo "=== Port Check ==="
for port in 7681 8001 3000 8080; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "✓ Port $port is listening"
        # Extra check for what's on the port
        lsof -i :$port 2>/dev/null | grep LISTEN | head -1
    else
        echo "✗ Port $port is NOT listening"
    fi
done

echo
echo "=== Testing Endpoints ==="
echo -n "Main UI (8080): "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/ || echo "Failed"

echo -n "Chat UI (3000): "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/ || echo "Failed"

echo -n "Terminal (7681): "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:7681/ || echo "Failed"

echo -n "Gateway Health: "
curl -s http://localhost:8001/health | grep -o '"status":"ok"' || echo "Failed"

echo
echo "=== Fix Complete ==="
echo "Main UI should be at: http://homeassistant.local:8080/"
echo
echo "If chat still shows directory listing:"
echo "1. Check chat-ui logs: tail -f /var/log/chat-ui.err"
echo "2. Manually test: cd /opt/anse && python3 -m http.server 3000"