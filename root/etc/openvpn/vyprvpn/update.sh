#!/bin/bash

echo "**** Grab VyprVPN config files ****"

curl -o /tmp/vyprvpn.zip -L "https://support.vyprvpn.com/hc/article_attachments/360052617332/Vypr_OpenVPN_20200320.zip" && \
    unzip /tmp/vyprvpn.zip -d /etc/openvpn/vyprvpn/ && \
    mv /etc/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN160/*.ovpn  /etc/openvpn/vyprvpn/ && \
    rm -rf /etc/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN160 && \
    rm -rf /etc/openvpn/vyprvpn/GF_OpenVPN_20200320/OpenVPN256

# Cleanup and setup the VyprVPN config files
for CONFIG_FILE in /etc/openvpn/vyprvpn/*.ovpn; do
    echo "Cleaning ${CONFIG_FILE}"
    echo "$(basename -- "${CONFIG_FILE}")" >> "/etc/openvpn/vyprvpn/list.txt"

    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/vyprvpn-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
