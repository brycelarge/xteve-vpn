#!/bin/bash

if [[ -z "${1}" ]]; then
    echo "No parameter supplied for file to convert" | ts '%Y-%m-%d %H:%M:%S'
    exit 1
fi

if [[ ! -f "${1}" ]]; then
    echo "File '${1}' does not exist" | ts '%Y-%m-%d %H:%M:%S'
    exit 1
fi

# create temp files used during the conversion
TEMP_FILE=$(mktemp /tmp/dos2unixtemp.XXXXXXXXX)
STDOUT_FILE=$(mktemp /tmp/dos2unixstdout.XXXXXXXXX)

# file to convert
SOURCE_FILE="${1}"

# run conversion, creating new temp file
/usr/bin/dos2unix -v -n "${SOURCE_FILE}" "${TEMP_FILE}" > "${STDOUT_FILE}" 2>&1

# if the file required conversion then overwrite (move with force) source file with converted temp file
if ! cat "${STDOUT_FILE}" | grep -q 'Converted 0'; then
    echo "Line ending conversion required, moving '${TEMP_FILE}' to '${SOURCE_FILE}'"
    mv -f "${TEMP_FILE}" "${SOURCE_FILE}"
fi

# remove temporary files
rm -f "${TEMP_FILE}"
rm -f "${STDOUT_FILE}"
