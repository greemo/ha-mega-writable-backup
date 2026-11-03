ARG BUILD_FROM
FROM ${BUILD_FROM}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        fuse \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://mega.nz/linux/repo/Debian_12/Release.key \
        | gpg --dearmor -o /etc/apt/keyrings/mega.nz.gpg \
    && echo "deb [arch=amd64,arm64 signed-by=/etc/apt/keyrings/mega.nz.gpg] https://mega.nz/linux/repo/Debian_12/ ./" \
        > /etc/apt/sources.list.d/mega.nz.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends megacmd \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod a+x /run.sh

CMD ["/run.sh"]
