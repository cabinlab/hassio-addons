ARG BUILD_FROM
FROM ${BUILD_FROM}

# Install packages for monitoring service
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-aiohttp \
    py3-asyncio \
    bash \
    curl \
    jq \
    && pip3 install --no-cache-dir \
        anthropic \
        pyyaml \
        schedule \
        python-dateutil \
    && pip3 cache purge

# Create directory for monitoring data
RUN mkdir -p /config/claude-watchdog
WORKDIR /config

# Copy application files
COPY run.sh /run.sh
COPY watchdog/ /app/
RUN chmod +x /run.sh \
    && chmod +x /app/*.py

# Use exec form for better signal handling
CMD ["/run.sh"]