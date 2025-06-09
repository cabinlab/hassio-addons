ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install Node.js, npm, and ttyd (Debian way)
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
    git \
    curl \
    ttyd \
    && rm -rf /var/lib/apt/lists/*

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