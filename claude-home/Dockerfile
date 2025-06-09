ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install required packages and Node.js
# First install dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
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

# Copy run script
COPY run.sh /

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