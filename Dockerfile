FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

ARG DEBIAN_FRONTEND="noninteractive"

# Add needed nvidia environment variables for https://github.com/NVIDIA/nvidia-docker
ENV NVIDIA_DRIVER_CAPABILITIES="compute,video,utility"

RUN \
    echo "**** install runtime ****" && \
    curl -s https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | apt-key add - && \
    echo 'deb [arch=amd64] https://repo.jellyfin.org/ubuntu jammy main' > /etc/apt/sources.list.d/jellyfin.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    vlc \
    jellyfin-ffmpeg5 \
    tzdata \
    unzip \
    jq \
    ufw \
    iputils-ping \
    openvpn \
    dos2unix \
    moreutils \
    lsb-release \
    gnupg2 \
    net-tools \
    sqlite3 \
    privoxy \
    bc && \
    echo "**** install speedtest cli ****" && \
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt-get install -y speedtest && \
    echo "**** install xTeVe ****" && \
    curl -L "https://github.com/xteve-project/xTeVe-Downloads/blob/master/xteve_linux_amd64.tar.gz?raw=true" -o /tmp/xteve_linux_amd64.tar.gz && \
    tar xf /tmp/xteve_linux_amd64.tar.gz -C \
    /usr/local/bin/ --strip-components=1 && \
    echo "**** cleanup ****" && \
    rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/tmp/*

# env
ENV \
    XTEVE_BRANCH=master \
    XTEVE_PORT=34400 \
    XTEVE_DEBUG=0 \
    DEBUG=false \
    TZ=Africa/Johannesburg \
	NAME_SERVERS=209.222.18.222,84.200.69.80,37.235.1.174,1.1.1.1,209.222.18.218,37.235.1.177,84.200.70.40,1.0.0.1 \
    OPENVPN_PROVIDER='**None**' \
    OPENVPN_CONFIG='**None**' \
    OPENVPN_USERNAME='**None**' \
    OPENVPN_PASSWORD='**None**' \
    CREATE_TUN_DEVICE=true \
    OPENVPN_OPTIONS='' \
    PRIVOXY_ENABLED=true \
    OPENVPN_PROTOCOL='udp'

# Timezone (TZ):  Add the tzdata package and configure for EST timezone.
# This will override the default container time in UTC.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# move ffmpeg to a standard location for users on an old unraid template
RUN ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg usr/bin/ffmpeg

# add local files
COPY root/ /

RUN chmod -R +x /etc/openvpn && /etc/openvpn/sqlite3/setup.sh && /etc/openvpn/surfshark/map.sh

# setup a health check to monitor OpenVPN
HEALTHCHECK --interval=5m CMD /etc/scripts/health-check.sh

# Configure container volume mappings
VOLUME /config /tmp/xteve

# Set default container port
EXPOSE 34400
# Privoxy
EXPOSE 8118
