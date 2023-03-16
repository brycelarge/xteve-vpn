#!/bin/bash

echo "[OpenVPN VyprVPN] grab config files" | ts '%Y-%m-%d %H:%M:%S'

# If the script is called from elsewhere
cd "${0%/*}"

REQUEST_URL=https://support.vyprvpn.com/hc/article_attachments/360052617332/Vypr_OpenVPN_20200320.zip

curl -skL ${REQUEST_URL} -o openvpn.zip \
    && unzip -jq openvpn.zip && \
    rm openvpn.zip

mv "${PATH}/GF_OpenVPN_20200320/OpenVPN160/*.ovpn"  ./ && \
    rm -rf "GF_OpenVPN_20200320/OpenVPN160" && \
    rm -rf "GF_OpenVPN_20200320/OpenVPN256"

# Cleanup and setup the VyprVPN config files
echo '' > list.txt
for CONFIG_FILE in *.ovpn; do
    echo "[OpenVPN VyprVPN] cleaning ${CONFIG_FILE}" | ts '%Y-%m-%d %H:%M:%S'
    echo "$(basename -- "${CONFIG_FILE}")" >> list.txt
    /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

    sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/vyprvpn-openvpn-credentials.txt/g" "${CONFIG_FILE}"
done
