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

# Copy scripts and set permissions
COPY run.sh /
COPY hassio_poweroff /etc/apcupsd/doshutdown
COPY hassio_reboot /etc/apcupsd/doreboot
COPY scripts/ /scripts/
RUN chmod +x /run.sh /etc/apcupsd/doshutdown /etc/apcupsd/doreboot /scripts/*.sh

WORKDIR /data

# Use exec form for better signal handling
CMD ["/run.sh"]
