#!/bin/bash

echo "**** Grab Surfshark config files ****"

mkdir -p /etc/openvpn/surfshark

curl -o /tmp/surfshark.zip -L "https://my.surfshark.com/vpn/api/v1/server/configurations" && \
    unzip /tmp/surfshark.zip -d /etc/openvpn/surfshark/

# Cleanup and setup the surfshark config files
for CONFIG_FILE in /etc/openvpn/surfshark/*.ovpn; do
    echo "Cleaning ${CONFIG_FILE}"
    echo "$(basename -- "${CONFIG_FILE}")" >> "/etc/openvpn/surfshark/list.txt"

    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/AES-256-CBC/AES-128-GCM/g" "${CONFIG_FILE}"
    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/surfshark-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
