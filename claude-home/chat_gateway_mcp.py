#!/usr/bin/env python3
"""
Minimal MCP Gateway Server for Chat
Provides OpenAI-compatible chat API with Claude Code and OpenAI fallback
"""

import os
import json
import asyncio
import logging
from typing import Optional, Dict, Any, List, AsyncIterator
from datetime import datetime

from mcp.server.fastmcp import FastMCP
import httpx
from pydantic import BaseModel, Field

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize MCP server
mcp = FastMCP(
    "Chat Gateway",
    instructions="""
    A lightweight gateway that provides OpenAI-compatible chat functionality.
    Automatically falls back from Claude Code to OpenAI when needed.
    """
)

# Configuration
CLAUDE_CODE_AVAILABLE = os.environ.get("CLAUDE_CODE_AVAILABLE", "true").lower() == "true"
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY", "")
OPENAI_MODEL = os.environ.get("OPENAI_MODEL", "gpt-3.5-turbo")
CLAUDE_MODEL = os.environ.get("CLAUDE_MODEL", "claude-3-5-sonnet-20241022")


class ChatMessage(BaseModel):
    role: str = Field(description="Message role: system, user, or assistant")
    content: str | List[Dict[str, Any]] = Field(description="Message content - string or multimodal array")


class ChatCompletionRequest(BaseModel):
    model: str = Field(description="Model to use", default=CLAUDE_MODEL)
    messages: List[ChatMessage] = Field(description="Conversation messages")
    temperature: float = Field(description="Sampling temperature", default=0.7)
    max_tokens: Optional[int] = Field(description="Maximum tokens to generate", default=None)
    stream: bool = Field(description="Stream the response", default=False)


class ChatCompletionResponse(BaseModel):
    id: str = Field(description="Unique completion ID")
    model: str = Field(description="Model used")
    created: int = Field(description="Timestamp")
    choices: List[Dict[str, Any]] = Field(description="Response choices")
    usage: Optional[Dict[str, int]] = Field(description="Token usage")


class ChatGateway:
    """Handles chat completions with fallback logic"""
    
    def __init__(self):
        self.claude_available = CLAUDE_CODE_AVAILABLE
        self.openai_available = bool(OPENAI_API_KEY)
        
    async def _try_claude_code(self, request: ChatCompletionRequest) -> Optional[ChatCompletionResponse]:
        """Try to use Claude Code via the Anthropic SDK"""
        if not self.claude_available:
            return None
            
        try:
            # Import here to avoid issues if not in Claude Code environment
            from anthropic import AsyncAnthropic
            
            client = AsyncAnthropic()
            
            # Convert messages to Anthropic format
            anthropic_messages = []
            system_message = None
            
            for msg in request.messages:
                if msg.role == "system":
                    system_message = msg.content if isinstance(msg.content, str) else msg.content[0]["text"]
                else:
                    # Handle multimodal content
                    if isinstance(msg.content, str):
                        anthropic_messages.append({
                            "role": msg.role,
                            "content": msg.content
                        })
                    else:
                        # Convert OpenAI multimodal format to Anthropic format
                        anthropic_content = []
                        for part in msg.content:
                            if part["type"] == "text":
                                anthropic_content.append({
                                    "type": "text",
                                    "text": part["text"]
                                })
                            elif part["type"] == "image_url":
                                # Anthropic expects base64 or URLs differently
                                image_url = part["image_url"]["url"]
                                if image_url.startswith("data:"):
                                    # Extract base64 data
                                    media_type = image_url.split(";")[0].split(":")[1]
                                    base64_data = image_url.split(",")[1]
                                    anthropic_content.append({
                                        "type": "image",
                                        "source": {
                                            "type": "base64",
                                            "media_type": media_type,
                                            "data": base64_data
                                        }
                                    })
                                else:
                                    # URL-based image
                                    anthropic_content.append({
                                        "type": "image",
                                        "source": {
                                            "type": "url",
                                            "url": image_url
                                        }
                                    })
                        
                        anthropic_messages.append({
                            "role": msg.role,
                            "content": anthropic_content
                        })
            
            # Make the request
            response = await client.messages.create(
                model=request.model or CLAUDE_MODEL,
                messages=anthropic_messages,
                system=system_message,
                temperature=request.temperature,
                max_tokens=request.max_tokens or 4096,
            )
            
            # Convert to OpenAI format
            return ChatCompletionResponse(
                id=f"claude-{response.id}",
                model=response.model,
                created=int(datetime.now().timestamp()),
                choices=[{
                    "index": 0,
                    "message": {
                        "role": "assistant",
                        "content": response.content[0].text
                    },
                    "finish_reason": "stop"
                }],
                usage={
                    "prompt_tokens": response.usage.input_tokens,
                    "completion_tokens": response.usage.output_tokens,
                    "total_tokens": response.usage.input_tokens + response.usage.output_tokens
                }
            )
            
        except Exception as e:
            logger.warning(f"Claude Code failed: {e}")
            return None
    
    async def _try_openai(self, request: ChatCompletionRequest) -> Optional[ChatCompletionResponse]:
        """Try to use OpenAI API as fallback"""
        if not self.openai_available:
            return None
            
        try:
            async with httpx.AsyncClient() as client:
                # Convert messages to OpenAI format (already in correct format)
                messages = []
                for msg in request.messages:
                    if isinstance(msg.content, str):
                        messages.append({
                            "role": msg.role,
                            "content": msg.content
                        })
                    else:
                        # Already in OpenAI multimodal format
                        messages.append({
                            "role": msg.role,
                            "content": msg.content
                        })
                
                openai_request = {
                    "model": OPENAI_MODEL,
                    "messages": messages,
                    "temperature": request.temperature,
                }
                
                if request.max_tokens:
                    openai_request["max_tokens"] = request.max_tokens
                
                response = await client.post(
                    "https://api.openai.com/v1/chat/completions",
                    json=openai_request,
                    headers={
                        "Authorization": f"Bearer {OPENAI_API_KEY}",
                        "Content-Type": "application/json"
                    },
                    timeout=30.0
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return ChatCompletionResponse(**data)
                else:
                    logger.warning(f"OpenAI API error: {response.status_code}")
                    return None
                    
        except Exception as e:
            logger.error(f"OpenAI API failed: {e}")
            return None
    
    async def complete(self, request: ChatCompletionRequest) -> ChatCompletionResponse:
        """Complete a chat with fallback logic"""
        # Try Claude Code first
        result = await self._try_claude_code(request)
        if result:
            return result
            
        # Fall back to OpenAI
        result = await self._try_openai(request)
        if result:
            return result
            
        # If all fail, return error
        raise Exception("All providers failed. Check configuration and API keys.")
    
    async def stream_complete(self, request: ChatCompletionRequest) -> AsyncIterator[str]:
        """Stream a chat completion"""
        # For simplicity, we'll implement basic streaming
        # In production, you'd want proper SSE streaming from both providers
        
        try:
            # Get non-streaming response
            response = await self.complete(request)
            
            # Simulate streaming by yielding chunks
            content = response.choices[0]["message"]["content"]
            words = content.split()
            
            for i, word in enumerate(words):
                chunk = {
                    "id": response.id,
                    "model": response.model,
                    "created": response.created,
                    "choices": [{
                        "index": 0,
                        "delta": {
                            "content": word + " " if i < len(words) - 1 else word
                        },
                        "finish_reason": None if i < len(words) - 1 else "stop"
                    }]
                }
                yield f"data: {json.dumps(chunk)}\n\n"
                await asyncio.sleep(0.02)  # Small delay to simulate streaming
                
            yield "data: [DONE]\n\n"
            
        except Exception as e:
            error_chunk = {
                "error": {
                    "message": str(e),
                    "type": "gateway_error"
                }
            }
            yield f"data: {json.dumps(error_chunk)}\n\n"


# Initialize gateway
gateway = ChatGateway()


@mcp.tool()
async def chat_completion(
    messages: List[Dict[str, Any]],
    model: Optional[str] = None,
    temperature: float = 0.7,
    max_tokens: Optional[int] = None,
    stream: bool = False
) -> Dict[str, Any]:
    """
    Create a chat completion using Claude Code with OpenAI fallback.
    
    Args:
        messages: List of message objects with 'role' and 'content'
                 Content can be a string or multimodal array with text/images
        model: Model to use (defaults to configured model)
        temperature: Sampling temperature (0-2)
        max_tokens: Maximum tokens to generate
        stream: Whether to stream the response
        
    Example messages with image:
        [{
            "role": "user",
            "content": [
                {"type": "text", "text": "What's in this image?"},
                {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,..."}}
            ]
        }]
        
    Returns:
        OpenAI-compatible chat completion response
    """
    try:
        # Convert messages to ChatMessage objects
        chat_messages = [ChatMessage(**msg) for msg in messages]
        
        # Create request
        request = ChatCompletionRequest(
            model=model or CLAUDE_MODEL,
            messages=chat_messages,
            temperature=temperature,
            max_tokens=max_tokens,
            stream=stream
        )
        
        if stream:
            # For MCP, we can't actually stream, so return a message about streaming
            return {
                "type": "streaming_not_supported",
                "message": "Streaming is supported via the SSE endpoint, not MCP tools"
            }
        else:
            # Get completion
            response = await gateway.complete(request)
            return response.dict()
            
    except Exception as e:
        logger.error(f"Chat completion error: {e}")
        return {
            "error": {
                "message": str(e),
                "type": "gateway_error"
            }
        }


@mcp.tool()
async def list_models() -> Dict[str, Any]:
    """
    List available models and their status.
    
    Returns:
        Dictionary of available models and their providers
    """
    models = {
        "available_models": [],
        "primary_provider": None,
        "fallback_provider": None
    }
    
    if gateway.claude_available:
        models["available_models"].append({
            "id": CLAUDE_MODEL,
            "provider": "claude_code",
            "status": "available"
        })
        models["primary_provider"] = "claude_code"
    
    if gateway.openai_available:
        models["available_models"].append({
            "id": OPENAI_MODEL,
            "provider": "openai",
            "status": "available"
        })
        if not models["primary_provider"]:
            models["primary_provider"] = "openai"
        else:
            models["fallback_provider"] = "openai"
    
    return models


@mcp.tool()
async def test_providers() -> Dict[str, Any]:
    """
    Test connectivity to all configured providers.
    
    Returns:
        Status of each provider
    """
    results = {}
    
    # Test Claude Code
    if gateway.claude_available:
        try:
            test_request = ChatCompletionRequest(
                messages=[ChatMessage(role="user", content="Say 'test'")],
                max_tokens=10
            )
            result = await gateway._try_claude_code(test_request)
            results["claude_code"] = {
                "status": "ok" if result else "failed",
                "model": CLAUDE_MODEL
            }
        except Exception as e:
            results["claude_code"] = {
                "status": "error",
                "error": str(e)
            }
    
    # Test OpenAI
    if gateway.openai_available:
        try:
            test_request = ChatCompletionRequest(
                messages=[ChatMessage(role="user", content="Say 'test'")],
                max_tokens=10
            )
            result = await gateway._try_openai(test_request)
            results["openai"] = {
                "status": "ok" if result else "failed",
                "model": OPENAI_MODEL
            }
        except Exception as e:
            results["openai"] = {
                "status": "error",
                "error": str(e)
            }
    
    return results


# SSE endpoint for streaming (when running as HTTP server)
async def handle_sse_chat(request_data: Dict[str, Any]) -> AsyncIterator[str]:
    """Handle SSE streaming requests"""
    try:
        # Parse request
        messages = [ChatMessage(**msg) for msg in request_data.get("messages", [])]
        request = ChatCompletionRequest(
            model=request_data.get("model", CLAUDE_MODEL),
            messages=messages,
            temperature=request_data.get("temperature", 0.7),
            max_tokens=request_data.get("max_tokens"),
            stream=True
        )
        
        # Stream response
        async for chunk in gateway.stream_complete(request):
            yield chunk
            
    except Exception as e:
        error_chunk = {
            "error": {
                "message": str(e),
                "type": "gateway_error"
            }
        }
        yield f"data: {json.dumps(error_chunk)}\n\n"


if __name__ == "__main__":
    import sys
    
    # Check if we should run as MCP server or HTTP server
    if len(sys.argv) > 1 and sys.argv[1] == "--http":
        # Run as HTTP server for SSE support
        from aiohttp import web
        
        async def sse_handler(request):
            """Handle SSE chat requests"""
            data = await request.json()
            
            response = web.StreamResponse()
            response.headers['Content-Type'] = 'text/event-stream'
            response.headers['Cache-Control'] = 'no-cache'
            response.headers['Access-Control-Allow-Origin'] = '*'
            await response.prepare(request)
            
            async for chunk in handle_sse_chat(data):
                await response.write(chunk.encode('utf-8'))
                
            return response
        
        async def health_handler(request):
            """Health check endpoint"""
            return web.json_response({"status": "ok"})
        
        app = web.Application()
        app.router.add_post('/v1/chat/completions', sse_handler)
        app.router.add_get('/health', health_handler)
        
        logger.info("Starting HTTP server on port 8000...")
        web.run_app(app, port=8000)
    else:
        # Run as MCP server
        mcp.run()