const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;

// Simple proxy function
function proxy(req, res, targetHost, targetPort, targetPath) {
    const options = {
        hostname: targetHost,
        port: targetPort,
        path: targetPath || req.url,
        method: req.method,
        headers: req.headers
    };

    const proxyReq = http.request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res);
    });

    proxyReq.on('error', (err) => {
        console.error(`Proxy error to ${targetHost}:${targetPort}:`, err.message);
        res.writeHead(502);
        res.end('Service unavailable');
    });

    req.pipe(proxyReq);
}

const server = http.createServer((req, res) => {
    console.log(`Request: ${req.method} ${req.url}`);
    
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
    } else if (req.url === '/test') {
        // Serve test page
        fs.readFile(path.join(__dirname, 'test.html'), (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error loading test page');
                return;
            }
            res.writeHead(200, {'Content-Type': 'text/html'});
            res.end(data);
        });
    } else {
        res.writeHead(404);
        res.end(`Not found: ${req.url}`);
    }
});

// Simple WebSocket proxy for terminal
server.on('upgrade', (req, socket, head) => {
    console.log(`WebSocket upgrade request: ${req.url}`);
    
    if (req.url.startsWith('/terminal')) {
        // Connect to ttyd WebSocket
        const net = require('net');
        const upstream = net.connect(7681, 'localhost');
        
        upstream.on('connect', () => {
            console.log('Connected to ttyd WebSocket');
            // Send the HTTP upgrade request
            upstream.write(`GET ${req.url.substring(9) || '/'} HTTP/1.1\r\n`);
            for (const [key, value] of Object.entries(req.headers)) {
                upstream.write(`${key}: ${value}\r\n`);
            }
            upstream.write('\r\n');
            upstream.write(head);
            
            // Pipe the connections
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
    console.log(`Responsive UI server running on port ${PORT}`);
    console.log('Routes:');
    console.log('  / -> UI (this server)');
    console.log('  /chat -> localhost:3000 (Anse)');
    console.log('  /terminal -> localhost:7681 (ttyd)');
    console.log('  /v1/* -> localhost:8001 (Gateway)');
});