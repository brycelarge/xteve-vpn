#!/bin/bash

echo "**** Setup sqlite3 DB ****"

DB=/etc/openvpn/sqlite3/config.db
sqlite3 "$DB" "CREATE TABLE surfshark_configs (id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT NOT NULL);"
sqlite3 "$DB" "CREATE TABLE openvpn (id INTEGER PRIMARY KEY, name TEXT NOT NULL, value TEXT NOT NULL);"
sqlite3 "$DB" "INSERT INTO openvpn(name, value) VALUES ('enabled', 'false');"
sqlite3 "$DB" "INSERT INTO openvpn(name, value) VALUES ('config', '');"
