#!/bin/bash

# if network interface docker0 is present then we are running in host mode and thus must exit
if [[ ! -z "$(ifconfig | grep docker0 || true)" ]]; then
    echo "[OpenVPN] docker network type detected as 'Host', this will cause major issues, please stop the container and switch back to 'Bridge'. Exiting..."
    rm -rf /etc/services.d/openvpn && exit 1
fi

VPN_PROVIDER="${OPENVPN_PROVIDER,,}"
# Remove the extension so we allow the user to specify or not specify the .ovpn extension
VPN_CONFIG="$(echo ${OPENVPN_CONFIG} | sed 's/\b.ovpn\b//g')"

# Get the directory where the providers config files sit
if [[ "${VPN_PROVIDER}" == "custom" ]]; then
    VPN_PROVIDER_CONFIGS="/config/openvpn"

    # If no file has been specified or the file specified does not exist in the custom directory then find the first file in that directory
    if [[ ! -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
        # Remove mac os files before we try find the first
        rm -rf /config/openvpn/._*.ovpn

        VPN_CONFIG=$(basename -- $(find ${VPN_PROVIDER_CONFIGS} -maxdepth 1 -name "*.ovpn" -print -quit) | sed 's/\b.ovpn\b//g')
    fi

    # If the file exists then lets clean it and link our credentials files
    if [[ -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
        /etc/scripts/openvpn-config-clean.sh "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn"
        sed -i "s/auth-user-pass.*/auth-user-pass \/config\/openvpn\/custom-openvpn-credentials.txt/g" "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn"
    fi
else
    # Set the pia config file to tcp directory if the protocol is tcp
    if [[ "${VPN_PROVIDER}" == "pia" && "${OPENVPN_PROTOCOL,,}" == "tcp" ]]; then
        VPN_PROVIDER_CONFIGS="/etc/openvpn/${VPN_PROVIDER}/tcp"
    else
        VPN_PROVIDER_CONFIGS="/etc/openvpn/${VPN_PROVIDER}"
        # allow for a config file without the _udp (protocol) to be used
        if [[ ! -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]] && [[ -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}_${OPENVPN_PROTOCOL,,}.ovpn" ]]; then
            VPN_CONFIG="${VPN_CONFIG}_${OPENVPN_PROTOCOL,,}"
        fi
    fi
fi

# Exit out if the provider config directory does not exist
if [[ ! -d "${VPN_PROVIDER_CONFIGS}" ]]; then
    echo "[OpenVPN] Could not find provider: ${OPENVPN_PROVIDER}. Exiting..." | ts '%Y-%m-%d %H:%M:%S'
    rm -rf /etc/services.d/openvpn && exit 1
fi

# This allows us to use a list similar to PIA list file and try and match it to surfsharks config file. Allows for a somewhat quick transition from PIA to Surfshark
if [[ "${VPN_PROVIDER}" == "surfshark" ]] && [[ ! -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
    clustersData="$(curl -s "https://my.surfshark.com/vpn/api/v1/server/clusters" | jq -r .[])"
    for country in $(echo "$clustersData" | jq -r '.countryCode'); do
        locations=$(echo "$clustersData" | jq -r "select(.countryCode==\"$country\") | .location")
        for location in $(echo $locations); do
            NAME="${country}_${location}"
            FILE=$(echo "$clustersData" | jq -r "select(.location==\"$location\") | .connectionName")
            if [ ! -z "$FILE" ]; then
                if [[ "$(echo $NAME | tr '[:upper:]' '[:lower:]')" == "${VPN_CONFIG}" ]] ]]; then
                    VPN_CONFIG="$(echo "${FILE}" | sed -e 's/\<.ovpn\>//g')_${OPENVPN_PROTOCOL,,}"

                    if [[ "${DEBUG}" == "true" ]]; then
                        echo "[OpenVPN] ${VPN_CONFIG} found using the surfshark API" | ts '%Y-%m-%d %H:%M:%S'
                    fi
                fi
            fi
        done
    done
fi

if [[ -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
    echo "[OpenVPN] config file ${VPN_CONFIG}.ovpn found" | ts '%Y-%m-%d %H:%M:%S'
    VPN_CONFIG="${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn"
else
    echo "[OpenVPN] supplied config ${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn could not be found. Exiting..." | ts '%Y-%m-%d %H:%M:%S'
    rm -rf /etc/services.d/openvpn && exit 1
fi

