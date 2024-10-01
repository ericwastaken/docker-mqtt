#!/bin/bash

set -e

# Generate SSL certificates if they don't exist
if [ ! -f "/mosquitto/certs/server.crt" ] || [ ! -f "/mosquitto/certs/server.key" ]; then
    echo "Generating SSL certificates..."
    /usr/local/bin/generate-self-signed-certs.sh
fi

# Generate password file if it doesn't exist
if [ ! -f "/mosquitto/password/passwd" ]; then
    echo "Creating password file..."
    mkdir -p /mosquitto/password
else
    echo "Overwriting password file..."
fi
mosquitto_passwd -b -c /mosquitto/password/passwd "$USERNAME" "$PASSWORD"

# Ensure proper permissions
chown -R mosquitto:mosquitto /mosquitto

# Set default values if not set
LOG_TYPE=${LOG_TYPE:-notice}
MQTT_PORT=${MQTT_PORT:-8883}
WEBSOCKET_PORT=${WEBSOCKET_PORT:-9443}

# Use envsubst to replace environment variables in mosquitto.conf
envsubst '${LOG_TYPE} ${MQTT_PORT} ${WEBSOCKET_PORT}' < /mosquitto/config/mosquitto.conf > /tmp/mosquitto.conf

# Start Mosquitto with the processed configuration file and verbose logging
exec /usr/sbin/mosquitto -v -c /tmp/mosquitto.conf
