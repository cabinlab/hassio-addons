#!/usr/bin/env python3
"""
Fixed version with proper port argument handling
"""

# ... (keeping all the imports and classes the same as original)

if __name__ == "__main__":
    import sys
    import argparse
    
    parser = argparse.ArgumentParser(description='Chat Gateway MCP Server')
    parser.add_argument('--http', action='store_true', help='Run as HTTP server')
    parser.add_argument('port', type=int, nargs='?', default=8000, help='Port to listen on')
    
    args = parser.parse_args()
    
    if args.http:
        # Run as HTTP server for SSE support
        from aiohttp import web
        
        async def sse_handler(request):
            """Handle SSE chat requests"""
            try:
                data = await request.json()
                
                response = web.StreamResponse()
                response.headers['Content-Type'] = 'text/event-stream'
                response.headers['Cache-Control'] = 'no-cache'
                response.headers['Access-Control-Allow-Origin'] = '*'
                await response.prepare(request)
                
                async for chunk in handle_sse_chat(data):
                    await response.write(chunk.encode('utf-8'))
                    
                return response
            except Exception as e:
                logger.error(f"SSE handler error: {e}")
                return web.json_response({"error": str(e)}, status=500)
        
        async def health_handler(request):
            """Health check endpoint"""
            return web.json_response({"status": "ok", "port": args.port})
        
        async def chat_handler(request):
            """Non-streaming chat endpoint for testing"""
            try:
                data = await request.json()
                # Simple echo for testing
                return web.json_response({
                    "id": "test-123",
                    "model": "test",
                    "choices": [{
                        "message": {
                            "role": "assistant",
                            "content": f"Echo: {data.get('messages', [{}])[-1].get('content', 'No message')}"
                        },
                        "finish_reason": "stop"
                    }]
                })
            except Exception as e:
                return web.json_response({"error": str(e)}, status=500)
        
        app = web.Application()
        app.router.add_post('/v1/chat/completions', sse_handler)
        app.router.add_get('/health', health_handler)
        app.router.add_post('/v1/chat/completions/test', chat_handler)
        
        logger.info(f"Starting HTTP server on port {args.port}...")
        web.run_app(app, host='0.0.0.0', port=args.port)
    else:
        # Run as MCP server
        mcp.run()