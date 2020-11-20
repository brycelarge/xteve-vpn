FROM lsiobase/ubuntu:bionic

ARG DEBIAN_FRONTEND="noninteractive"

RUN \
    echo "**** install runtime ****" && \
    apt-get update && \
    apt-get install -y \
    vlc \
    ffmpeg \
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
    bc && \
    echo "**** install speedtest cli ****" && \
    export INSTALL_KEY=379CE192D401AB61 && \
    export DEB_DISTRO=$(lsb_release -sc) && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $INSTALL_KEY && \
    echo "deb https://ookla.bintray.com/debian ${DEB_DISTRO} main" | tee /etc/apt/sources.list.d/speedtest.list && \
    apt-get update && \
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
	NAME_SERVERS=8.8.8.8,8.8.4.4 \
    OPENVPN_PROVIDER='**None**' \
    OPENVPN_CONFIG='**None**' \
    OPENVPN_USERNAME='**None**' \
    OPENVPN_PASSWORD='**None**' \
    CREATE_TUN_DEVICE=true \
    OPENVPN_OPTIONS='' \
    OPENVPN_PROTOCOL='udp'

# Timezone (TZ):  Add the tzdata package and configure for EST timezone.
# This will override the default container time in UTC.
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# add local files
COPY root/ /

RUN /etc/openvpn/pia/update.sh && /etc/openvpn/surfshark/update.sh

# setup a health check to monitor OpenVPN
HEALTHCHECK --interval=5m CMD /etc/scripts/healthcheck.sh

# Configure container volume mappings
VOLUME /config /tmp/xteve

# Set default container port
EXPOSE 34400
