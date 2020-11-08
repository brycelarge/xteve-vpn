#!/bin/bash

#Network check
# Ping uses both exit codes 1 and 2. Exit code 2 cannot be used for docker health checks,
# therefore we use this script to catch error code 2
HOST=${HEALTH_CHECK_HOST}

if [[ -z "$HOST" ]]
then
    echo "Host not set! Set env 'HEALTH_CHECK_HOST'. For now, using default google.com" | ts '%Y-%m-%d %H:%M:%S'
    HOST="google.com"
fi

ping -c 1 $HOST
STATUS=$?
if [[ ${STATUS} -ne 0 ]]
then
    echo "Network is down" | ts '%Y-%m-%d %H:%M:%S'
    exit 1
fi

echo "Network is up" | ts '%Y-%m-%d %H:%M:%S'

#Service check
#Expected output is 2 for both checks, 1 for process and 1 for grep
OPENVPN=$(pgrep openvpn | wc -l )

if [[ ${OPENVPN} -ne 1 ]]
then
    echo "OpenVPN process not running" | ts '%Y-%m-%d %H:%M:%S'
    exit 1
fi

echo "OpenVPN process is running" | ts '%Y-%m-%d %H:%M:%S'
exit 0
