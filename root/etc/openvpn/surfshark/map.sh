#!/bin/bash

echo "Compiling name from surfshark config to make it easier to cross reference with PAI"
clustersData="$(curl -s "https://my.surfshark.com/vpn/api/v1/server/clusters" | jq -r .[])"
for country in $(echo "$clustersData" | jq -r '.countryCode'); do
    locations=$(echo "$clustersData" | jq -r "select(.countryCode==\"$country\") | .location")
    for location in $(echo $locations); do
        NAME=$(echo "${country}_${location}" | tr '[:upper:]' '[:lower:]')
        FILE=$(echo "$clustersData" | jq -r "select(.location==\"$location\") | .connectionName")
        if [ ! -z "$FILE" ]; then
            sqlite3 /etc/openvpn/sqlite3/config.db "INSERT INTO surfshark_configs(name, value) VALUES ('${NAME}', '${FILE}');"
        fi
    done
done
