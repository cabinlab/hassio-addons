#!/usr/bin/with-contenv bashio

# Test script to debug HA MCP Server endpoint

bashio::log.info "Testing Home Assistant MCP Server endpoint..."

# Test different possible endpoints
ENDPOINTS=(
    "http://supervisor/core/mcp_server/sse"
    "http://supervisor/core/api/mcp_server/sse"
    "http://supervisor/core/api/mcp"
    "http://supervisor/mcp_server/sse"
)

for endpoint in "${ENDPOINTS[@]}"; do
    bashio::log.info "Testing endpoint: $endpoint"
    
    # Test with curl to see response
    response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Accept: text/event-stream" \
        "$endpoint" 2>&1 || true)
    
    http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_CODE:")
    
    bashio::log.info "  HTTP Code: $http_code"
    if [ -n "$body" ]; then
        bashio::log.info "  Response: $(echo "$body" | head -50)"
    fi
    echo ""
done

# Also test the regular API to ensure token works
bashio::log.info "Testing regular API with token..."
api_test=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    "http://supervisor/core/api/" 2>&1 || true)

api_code=$(echo "$api_test" | grep "HTTP_CODE:" | cut -d: -f2)
bashio::log.info "API test HTTP Code: $api_code"

# Check if MCP Server integration is installed
bashio::log.info "Checking for MCP Server integration..."
integrations=$(curl -s \
    -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    "http://supervisor/core/api/config/entries/entry" 2>&1 || true)

if echo "$integrations" | grep -q "mcp_server"; then
    bashio::log.info "MCP Server integration found!"
else
    bashio::log.warning "MCP Server integration not found in Home Assistant"
fi