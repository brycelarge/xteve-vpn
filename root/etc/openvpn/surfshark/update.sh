#!/bin/bash

echo "[OpenVPN Surfshark] grab config files" | ts '%Y-%m-%d %H:%M:%S'

curl -o /tmp/surfshark.zip -L "https://my.surfshark.com/vpn/api/v1/server/configurations" && \
    unzip /tmp/surfshark.zip -d /config/openvpn/surfshark/

# Cleanup and setup the surfshark config files
echo '' > "/config/openvpn/surfshark/list.txt"
for CONFIG_FILE in /config/openvpn/surfshark/*.ovpn; do
    echo "[OpenVPN Surfshark] cleaning ${CONFIG_FILE}" | ts '%Y-%m-%d %H:%M:%S'
    echo "$(basename -- "${CONFIG_FILE}")" >> "/config/openvpn/surfshark/list.txt"
    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/AES-256-CBC/AES-128-GCM/g" "${CONFIG_FILE}"
    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/surfshark-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
