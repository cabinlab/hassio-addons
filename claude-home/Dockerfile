ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install required packages and Node.js
# First install dependencies including Python for hass-mcp
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    nano \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install ttyd from GitHub releases (not in Debian repos)
# Handle multiple architectures
RUN ARCH="$(dpkg --print-architecture)" && \
    if [ "$ARCH" = "amd64" ]; then \
        TTYD_ARCH="x86_64"; \
    elif [ "$ARCH" = "arm64" ]; then \
        TTYD_ARCH="aarch64"; \
    else \
        TTYD_ARCH="$ARCH"; \
    fi && \
    wget "https://github.com/tsl0922/ttyd/releases/download/1.7.4/ttyd.${TTYD_ARCH}" -O /usr/local/bin/ttyd && \
    chmod +x /usr/local/bin/ttyd

# Install Claude Code globally - it just works on Debian!
RUN npm install -g @anthropic-ai/claude-code

# Copy and install hass-mcp-lite
COPY hass-mcp-lite /opt/hass-mcp
WORKDIR /opt/hass-mcp
# Install in a more compatible way
RUN python3 -m pip install --no-cache-dir --break-system-packages httpx mcp && \
    python3 -m pip install --no-cache-dir --break-system-packages -e .
WORKDIR /

# Copy run scripts and make them executable
COPY run.sh /
COPY run-simple.sh /
COPY claude-wrapper.sh /usr/local/bin/claude-wrapper
COPY test-mcp.sh /usr/local/bin/test-mcp
COPY mcp-diagnostics.sh /usr/local/bin/mcp-diagnostics
RUN chmod a+x /run.sh /run-simple.sh /usr/local/bin/claude-wrapper /usr/local/bin/test-mcp /usr/local/bin/mcp-diagnostics

# S6 expects the service in a specific location for legacy mode
# Use the simple script for now
RUN mkdir -p /etc/services.d/claude-home && \
    echo '#!/usr/bin/with-contenv bashio' > /etc/services.d/claude-home/run && \
    echo 'exec /run-simple.sh' >> /etc/services.d/claude-home/run && \
    chmod +x /etc/services.d/claude-home/run

# Labels
LABEL \
    io.hass.name="Claude Home" \
    io.hass.description="AI-powered terminal interface with Claude Code CLI" \
    io.hass.arch="aarch64|amd64" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Cabin Lab"

# S6 and bashio are already in the base image!
# No BusyBox issues!
# No wrapper needed!