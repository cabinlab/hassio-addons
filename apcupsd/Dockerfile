ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell and environment
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV LANG=C.UTF-8

# Install packages in a single layer to minimize image size
RUN apk update && apk add --no-cache \
    apcupsd \
    jq \
    curl \
    openssh-client \
    msmtp \
    mailx \
    bash \
    && rm -rf /var/cache/apk/*

# Create symbolic link for sendmail
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail

# Copy scripts with executable permissions
COPY --chmod=755 run.sh /
COPY --chmod=755 hassio_poweroff /sbin/poweroff
COPY --chmod=755 hassio_reboot /sbin/reboot

WORKDIR /data

# Use exec form for better signal handling
CMD ["/run.sh"]
