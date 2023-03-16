#!/bin/bash

echo "[OpenVPN VyprVPN] grab config files" | ts '%Y-%m-%d %H:%M:%S'

curl -o /tmp/vyprvpn.zip -L "https://support.vyprvpn.com/hc/article_attachments/360052617332/Vypr_OpenVPN_20200320.zip" && \
    unzip /tmp/vyprvpn.zip -d /config/openvpn/vyprvpn/ && \
    mv /config/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN160/*.ovpn  /config/openvpn/vyprvpn/ && \
    rm -rf /config/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN160 && \
    rm -rf /config/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN256

# Cleanup and setup the VyprVPN config files
echo '' > "/config/openvpn/vyprvpn/list.txt"
for CONFIG_FILE in /config/openvpn/vyprvpn/*.ovpn; do
    echo "[OpenVPN VyprVPN] cleaning ${CONFIG_FILE}" | ts '%Y-%m-%d %H:%M:%S'
    echo "$(basename -- "${CONFIG_FILE}")" >> "/config/openvpn/vyprvpn/list.txt"
    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/vyprvpn-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
