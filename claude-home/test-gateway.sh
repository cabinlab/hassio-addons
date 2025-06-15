#!/bin/bash
# Test gateway connectivity

echo "=== Testing Gateway Connectivity ==="
echo

# 1. Direct gateway test
echo "1. Testing gateway directly on port 8001..."
echo -n "   Health check: "
curl -s http://localhost:8001/health 2>/dev/null | jq . || echo "FAILED"

echo
echo "2. Testing gateway through UI proxy on port 8080..."
echo -n "   Health check via proxy: "
curl -s http://localhost:8080/v1/chat/completions/test \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"test"}]}' 2>/dev/null | jq . || echo "FAILED"

echo
echo "3. Checking if gateway is actually running..."
ps aux | grep -E "chat_gateway_mcp|gateway-venv" | grep -v grep || echo "   Gateway process not found!"

echo
echo "4. Checking gateway logs..."
echo "   === Last 10 lines of gateway.log ==="
tail -n 10 /var/log/gateway.log 2>/dev/null || echo "   No log file"
echo
echo "   === Last 10 lines of gateway.err ==="
tail -n 10 /var/log/gateway.err 2>/dev/null || echo "   No error log"

echo
echo "5. Testing gateway port directly..."
nc -zv localhost 8001 2>&1 || echo "   Port 8001 not open"

echo
echo "6. Checking supervisord status..."
supervisorctl status chat-gateway

echo
echo "=== Quick Fixes ==="
echo "1. Restart gateway: supervisorctl restart chat-gateway"
echo "2. Check python path: which python3"
echo "3. Test gateway manually:"
echo "   /opt/gateway-venv/bin/python /opt/chat_gateway_mcp.py --http 8001"
echo "4. Check if venv exists: ls -la /opt/gateway-venv/"