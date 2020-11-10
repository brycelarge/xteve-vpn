#!/bin/bash

# convert dos to unix
/etc/scripts/dos2unix.sh "${1}";

# Remove up/down resolv-conf script calls (Mullvad)
sed -i "/update-resolv-conf/d" "${1}"

# if 'proto' is old format 'tcp' then replace with newer 'tcp-client' format
sed -i "s/^proto\stcp$/proto tcp-client/g" "${1}"

# remove persist-tun from ovpn file if present, this allows reconnection to tunnel on disconnect
#sed -i '/^persist-tun/d' "${1}"

# remove reneg-sec from ovpn file if present, this is removed to prevent re-checks and dropouts
sed -i '/^reneg-sec.*/d' "${1}"

# remove windows specific openvpn options
sed -i '/^route-method exe/d' "${1}"
sed -i '/^service\s.*/d' "${1}"
sed -i '/^block-outside-dns/d' "${1}"

VPN_DEVICE_TYPE=$(cat "${1}" | grep -P -o -m 1 '(?<=^dev\s)[^\r\n\d]+' | sed -e 's~^[ \t]*~~;s~[ \t]*$~~')
if [[ ! -z "${VPN_DEVICE_TYPE}" ]]; then
    # forcibly set virtual network device to 'tun0/tap0'
    sed -i "s/^dev\s${VPN_DEVICE_TYPE}.*/dev ${VPN_DEVICE_TYPE}/g" "${1}"
else
    echo "VPN_DEVICE_TYPE not found in ${1}, deleting file"
    rm "${1}" && exit 1
fi


