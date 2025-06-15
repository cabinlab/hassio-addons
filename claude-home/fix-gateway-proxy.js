// Fixed server.js with better error handling and logging
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;

// Simple proxy function with better error handling
function proxy(req, res, targetHost, targetPort, targetPath) {
    console.log(`Proxying ${req.url} to ${targetHost}:${targetPort}${targetPath}`);
    
    const options = {
        hostname: targetHost,
        port: targetPort,
        path: targetPath || req.url,
        method: req.method,
        headers: {...req.headers, host: `${targetHost}:${targetPort}`}
    };

    const proxyReq = http.request(options, (proxyRes) => {
        console.log(`Proxy response: ${proxyRes.statusCode}`);
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
        console.error(`Proxy error to ${targetHost}:${targetPort}:`, err.message);
        res.writeHead(502, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({error: 'Gateway error', details: err.message}));
    });

    req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
    console.log(`Request: ${req.method} ${req.url}`);
    
    // Add CORS headers for all responses
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    // Handle OPTIONS for CORS
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // Route based on path
    if (req.url === '/' || req.url === '/index.html') {
        // Serve the main UI
        fs.readFile(path.join(__dirname, 'index.html'), (err, data) => {
            if (err) {
                console.error('Error reading index.html:', err);
                res.writeHead(500);
                res.end('Error loading page');
                return;
            }
            res.writeHead(200, {'Content-Type': 'text/html'});
            res.end(data);
        });
    } else if (req.url.startsWith('/chat')) {
        // Proxy to chat UI
        const targetPath = req.url.substring(5) || '/';
        proxy(req, res, 'localhost', 3000, targetPath);
    } else if (req.url.startsWith('/terminal')) {
        // Proxy to ttyd
        const targetPath = req.url.substring(9) || '/';
        proxy(req, res, 'localhost', 7681, targetPath);
    } else if (req.url.startsWith('/v1/')) {
        // Proxy to gateway API - THIS IS THE IMPORTANT ONE
        proxy(req, res, 'localhost', 8001, req.url);
    } else {
        res.writeHead(404);
        res.end(`Not found: ${req.url}`);
    }
});

// Handle WebSocket upgrades
server.on('upgrade', (req, socket, head) => {
    console.log(`WebSocket upgrade request: ${req.url}`);
    
    if (req.url.startsWith('/terminal')) {
        // Proxy WebSocket to ttyd
        const net = require('net');
        const upstream = net.connect(7681, 'localhost');
        
        upstream.on('connect', () => {
            console.log('Connected to ttyd WebSocket');
            const targetPath = req.url.substring(9) || '/';
            upstream.write(`GET ${targetPath} HTTP/1.1\r\n`);
            for (const [key, value] of Object.entries(req.headers)) {
                if (key.toLowerCase() !== 'host') {
                    upstream.write(`${key}: ${value}\r\n`);
                }
            }
            upstream.write('Host: localhost:7681\r\n');
            upstream.write('\r\n');
            upstream.write(head);
            
            socket.pipe(upstream);
            upstream.pipe(socket);
        });
        
        upstream.on('error', (err) => {
            console.error('WebSocket upstream error:', err);
            socket.destroy();
        });
        
        socket.on('error', (err) => {
            console.error('WebSocket socket error:', err);
            upstream.destroy();
        });
    } else {
        socket.destroy();
    }
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`UI server running on port ${PORT}`);
    console.log('Routes:');
    console.log('  / -> UI (this server)');
    console.log('  /chat/* -> localhost:3000');
    console.log('  /terminal/* -> localhost:7681');
    console.log('  /v1/* -> localhost:8001 (Gateway API)');
    
    // Test gateway connectivity on startup
    setTimeout(() => {
        const testReq = http.get('http://localhost:8001/health', (res) => {
            console.log(`Gateway health check: ${res.statusCode}`);
        });
        testReq.on('error', (err) => {
            console.error('Gateway not responding:', err.message);
        });
    }, 1000);
});