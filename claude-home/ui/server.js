const http = require('http');
const httpProxy = require('http-proxy');
const fs = require('fs');
const path = require('path');

const PORT = 8080;

// Create proxy instances
const chatProxy = httpProxy.createProxyServer({target: 'http://localhost:3000'});
const terminalProxy = httpProxy.createProxyServer({target: 'http://localhost:7681', ws: true});
const gatewayProxy = httpProxy.createProxyServer({target: 'http://localhost:8001'});

const server = http.createServer((req, res) => {
    // Route based on path
    if (req.url === '/' || req.url === '/index.html') {
        // Serve the main UI
        fs.readFile(path.join(__dirname, 'index.html'), (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error loading page');
                return;
            }
            res.writeHead(200, {'Content-Type': 'text/html'});
            res.end(data);
        });
    } else if (req.url.startsWith('/chat')) {
        // Proxy to Anse chat UI
        chatProxy.web(req, res, {}, (err) => {
            console.error('Chat proxy error:', err);
            res.writeHead(502);
            res.end('Chat service unavailable');
        });
    } else if (req.url.startsWith('/terminal')) {
        // Proxy to ttyd terminal
        terminalProxy.web(req, res, {}, (err) => {
            console.error('Terminal proxy error:', err);
            res.writeHead(502);
            res.end('Terminal service unavailable');
        });
    } else if (req.url.startsWith('/v1/')) {
        // Proxy to gateway API
        gatewayProxy.web(req, res, {}, (err) => {
            console.error('Gateway proxy error:', err);
            res.writeHead(502);
            res.end('Gateway service unavailable');
        });
    } else {
        res.writeHead(404);
        res.end('Not found');
    }
});

// Handle WebSocket upgrade for terminal
server.on('upgrade', (req, socket, head) => {
    if (req.url.startsWith('/terminal')) {
        terminalProxy.ws(req, socket, head, {}, (err) => {
            console.error('Terminal WebSocket error:', err);
            socket.destroy();
        });
    }
});

// Error handling
chatProxy.on('error', (err) => console.error('Chat proxy error:', err));
terminalProxy.on('error', (err) => console.error('Terminal proxy error:', err));
gatewayProxy.on('error', (err) => console.error('Gateway proxy error:', err));

server.listen(PORT, '0.0.0.0', () => {
    console.log(`Responsive UI server running on port ${PORT}`);
    console.log('Proxying:');
    console.log('  /chat -> localhost:3000 (Anse)');
    console.log('  /terminal -> localhost:7681 (ttyd)');
    console.log('  /v1/* -> localhost:8001 (Gateway)');
});