#!/bin/bash

echo "[OpenVPN Surfshark] grab config files" | ts '%Y-%m-%d %H:%M:%S'

REQUEST_URL=https://my.surfshark.com/vpn/api/v1/server/configurations

# If the script is called from elsewhere
cd "${0%/*}"

curl -skL ${REQUEST_URL} -o openvpn.zip \
    && unzip -jq openvpn.zip && \
    rm openvpn.zip

# Cleanup and setup the surfshark config files
echo '' > list.txt
for CONFIG_FILE in *.ovpn; do
    echo "[OpenVPN Surfshark] cleaning ${CONFIG_FILE}" | ts '%Y-%m-%d %H:%M:%S'
    echo "$(basename -- "${CONFIG_FILE}")" >> list.txt
    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/AES-256-CBC/AES-128-GCM/g" "${CONFIG_FILE}"
    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/surfshark-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
