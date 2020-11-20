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

if [[ "${VPN_PROVIDER}" == "surfshark" ]] && [[ ! -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
    # This allows us to use a list similar to PIA list file and try and match it to surfsharks config file. Allows for a somewhat quick transition from PIA to Surfshark
    SURFSHARK_CLUSTERS_URL='https://my.surfshark.com/vpn/api/v1/server/clusters'
    LOCATIONS=$(curl -s "${SURFSHARK_CLUSTERS_URL}" | jq -r '.[] | [.countryCode,.location,":",.location,":",.country,":",.connectionName] | @sh' | tr -d "'")
    readarray -t LOCATIONS_ARRAY <<< "${LOCATIONS//,/$'\n'}"

    ## Try match the config file to SURSHARKS config files
    for i in "${!LOCATIONS_ARRAY[@]}"; do
        IFS=: read -r -a VALUES <<< "${LOCATIONS_ARRAY[${i}]}"
        CODE_AND_LOCATION=$(echo ${VALUES[0]} | sed 's/ *$//g')
        LOCATION=$(echo ${VALUES[1]} | sed 's/ *$//g')
        COUNTRY=$(echo ${VALUES[2]} | sed 's/ *$//g')
        FILE=$(echo ${VALUES[3]} | sed 's/ *$//g')

        if [[ "${CODE_AND_LOCATION}" == "${VPN_CONFIG}" ]] || [[ "${COUNTRY} ${LOCATION}" == "${VPN_CONFIG}" ]] || [[ "${COUNTRY}" == "${VPN_CONFIG}" ]]; then
            VPN_CONFIG="$(echo "${FILE}" | sed -e 's/\<.ovpn\>//g')_${OPENVPN_PROTOCOL,,}"

            if [[ "${DEBUG}" == "true" ]]; then
                echo "[OpenVPN] ${VPN_CONFIG} found using the surfshark API" | ts '%Y-%m-%d %H:%M:%S'
            fi
        fi
    done
fi

if [[ -f "${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn" ]]; then
    echo "[OpenVPN] config file ${VPN_CONFIG}.ovpn found" | ts '%Y-%m-%d %H:%M:%S'
    VPN_CONFIG="${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn"
else
    echo "[OpenVPN] supplied config ${VPN_PROVIDER_CONFIGS}/${VPN_CONFIG}.ovpn could not be found. Exiting..." | ts '%Y-%m-%d %H:%M:%S'
    rm -rf /etc/services.d/openvpn && exit 1
fi

