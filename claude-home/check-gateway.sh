#!/bin/bash
echo "=== Quick Gateway Check ==="
echo
echo "1. Is gateway process running?"
ps aux | grep chat_gateway_mcp | grep -v grep || echo "NO - Gateway not running!"
echo
echo "2. Is port 8001 open?"
netstat -tln | grep 8001 || echo "NO - Port 8001 not listening!"
echo
echo "3. Can we reach the gateway?"
curl -s http://localhost:8001/health | jq . || echo "NO - Gateway not responding!"
echo
echo "4. Gateway logs:"
tail -5 /var/log/gateway.err 2>/dev/null || echo "No error log"
echo
echo "5. Try running gateway manually:"
echo "   /opt/gateway-venv/bin/python /opt/chat_gateway_mcp.py --http 8001"