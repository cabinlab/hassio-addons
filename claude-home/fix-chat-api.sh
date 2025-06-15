#!/bin/bash
# Fix chat UI API endpoint issue

echo "=== Fixing Chat UI API Endpoint ==="
echo

# The issue: Chat UI on port 3000 is trying to call /v1/chat/completions
# but it needs to go to port 8001 (gateway), not relative to itself

echo "1. Backing up current chat UI..."
cp /opt/anse/index.html /opt/anse/index.html.bak 2>/dev/null

echo "2. Installing fixed chat UI..."
if [ -f chat-ui-fixed/index.html ]; then
    cp chat-ui-fixed/index.html /opt/anse/index.html
    echo "   ✓ Installed fixed chat UI"
else
    # Quick inline fix - make API calls go to gateway port
    echo "   Applying inline fix..."
    sed -i "s|fetch('/v1/chat/completions'|fetch('http://localhost:8001/v1/chat/completions'|g" /opt/anse/index.html
    sed -i "s|fetch('/v1/chat/completions/test'|fetch('http://localhost:8001/v1/chat/completions/test'|g" /opt/anse/index.html
    echo "   ✓ Applied inline fix"
fi

echo
echo "3. Restarting chat UI service..."
supervisorctl restart chat-ui

echo
echo "4. Testing the fix..."
sleep 3

# Test if chat UI is accessible
echo -n "   Chat UI (3000): "
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000/ || echo "Failed"

# Check if the fix worked by looking at the HTML
echo
echo "5. Verifying API endpoint in HTML..."
grep -o "http://localhost:8001" /opt/anse/index.html | head -1 || echo "   ! Still using relative URLs"

echo
echo "=== Fix Applied ==="
echo "The chat UI should now correctly call the gateway on port 8001"
echo "Try refreshing the chat interface in your browser (Ctrl+F5)"
echo
echo "If CORS errors occur, we may need to update the gateway to add CORS headers."