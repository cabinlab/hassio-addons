#!/bin/bash
# Quick fix for gateway connectivity issue

echo "=== Quick Gateway Fix ==="
echo

# 1. Check if gateway is running
echo "1. Checking gateway status..."
if supervisorctl status chat-gateway | grep -q RUNNING; then
    echo "   ✓ Gateway is running"
else
    echo "   ✗ Gateway is not running"
    echo "   Starting gateway..."
    supervisorctl start chat-gateway
fi

# 2. Test gateway directly
echo
echo "2. Testing gateway on port 8001..."
if curl -s http://localhost:8001/health | grep -q "ok"; then
    echo "   ✓ Gateway responding on 8001"
else
    echo "   ✗ Gateway not responding"
    
    # Try to start it manually to see errors
    echo
    echo "3. Testing gateway manually..."
    timeout 5 /opt/gateway-venv/bin/python /opt/chat_gateway_mcp.py --http 8001 2>&1 | head -20
fi

# 4. Check if the issue is with the proxy
echo
echo "4. Testing UI proxy..."
# Replace the server.js with fixed version if needed
if [ -f fix-gateway-proxy.js ]; then
    echo "   Updating UI server with better proxy..."
    cp /opt/ui/server.js /opt/ui/server.js.bak
    cp fix-gateway-proxy.js /opt/ui/server.js
    supervisorctl restart responsive-ui
    sleep 2
fi

# 5. Final test
echo
echo "5. Final connectivity test..."
echo -n "   Gateway direct: "
curl -s http://localhost:8001/health | jq -r .status || echo "FAILED"

echo -n "   Gateway via proxy: "
curl -s -X POST http://localhost:8080/v1/chat/completions/test \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}' \
  | jq -r .status 2>/dev/null || echo "FAILED"

echo
echo "=== Status ==="
supervisorctl status | grep -E "chat-gateway|responsive-ui"

echo
echo "If gateway still fails, check:"
echo "1. Python venv: ls -la /opt/gateway-venv/bin/"
echo "2. Gateway script: ls -la /opt/chat_gateway_mcp.py"
echo "3. Import errors: /opt/gateway-venv/bin/python -c 'import mcp, httpx, pydantic, aiohttp'"