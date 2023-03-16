#!/bin/bash

echo "[OpenVPN PIA] grab config files" | ts '%Y-%m-%d %H:%M:%S'

set -e

# If the script is called from elsewhere
cd "${0%/*}"

declare -a CONFIG_URLS=("" "-tcp")
declare -a CONFIG_FOLDERS=("" "tcp")
BASE_URL="https://www.privateinternetaccess.com/openvpn/openvpn"

NUMBER_OF_CONFIG_TYPES=${#CONFIG_URLS[@]}

for (( i=1; i<${NUMBER_OF_CONFIG_TYPES}+1; i++ )); do
    REQUEST_URL="${BASE_URL}${CONFIG_URLS[$i-1]}.zip"
    if [[ ! -z "${CONFIG_FOLDERS[$i-1]}" ]] ; then
        mkdir -p ${CONFIG_FOLDERS[$i-1]} && cd ${CONFIG_FOLDERS[$i-1]}
    fi

    curl -kL ${REQUEST_URL} -o openvpn.zip \
        && unzip -j openvpn.zip && \
        rm openvpn.zip

    # Update configs with correct paths
    FOLDER_WITH_ESCAPED_SLASH=""
    if [[ ! -z "${CONFIG_FOLDERS[$i-1]}" ]] ; then
        FOLDER_WITH_ESCAPED_SLASH="${CONFIG_FOLDERS[$i-1]}\/"
    fi

    # Cleanup and setup the surfshark config files
    echo '' > "/config/openvpn/pia/list.txt"
    for CONFIG_FILE in *.ovpn; do
        echo "[OpenVPN PIA] cleaning ${CONFIG_FILE}" | ts '%Y-%m-%d %H:%M:%S'
        echo "$(basename -- "${CONFIG_FILE}")" >> "/config/openvpn/pia/list.txt"

        /etc/scripts/openvpn-config-clean.sh "${CONFIG_FILE}"

        sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/pia-openvpn-credentials.txt/g" "${CONFIG_FILE}"
        sed -i "s/ca ca\.rsa\.\([0-9]*\)\.crt/ca \/config\/openvpn\/pia\/${FOLDER_WITH_ESCAPED_SLASH}ca\.rsa\.\1\.crt/" "${CONFIG_FILE}"
        sed -i "s/crl-verify crl\.rsa\.\([0-9]*\)\.pem/crl-verify \/config\/openvpn\/pia\/${FOLDER_WITH_ESCAPED_SLASH}crl\.rsa\.\1\.pem/" "${CONFIG_FILE}"
    done

    if [[ ! -z "${CONFIG_FOLDERS[$i-1]}" ]] ; then
        cd ..
    fi
done
