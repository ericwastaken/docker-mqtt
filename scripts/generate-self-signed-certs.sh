#!/bin/bash

set -e

# Check for dependencies
if ! command -v openssl &> /dev/null
then
    echo "OpenSSL could not be found. Please install it before proceeding."
    exit 1
fi

# Check if HOSTNAME is provided
if [ -z "$HOSTNAME" ]; then
    echo "HOSTNAME environment variable is not set."
    exit 1
fi

CERT_DIR=/mosquitto/certs

mkdir -p $CERT_DIR

# Generate CA key and certificate
if [ ! -f "$CERT_DIR/ca.key" ] || [ ! -f "$CERT_DIR/ca.crt" ]; then
    echo "Generating CA key and certificate..."
    openssl genrsa -out $CERT_DIR/ca.key 2048
    openssl req -x509 -new -nodes -key $CERT_DIR/ca.key -sha256 -days 3650 -out $CERT_DIR/ca.crt -subj "/CN=My MQTT CA"
fi

# Generate server key and CSR
echo "Generating server key and CSR..."
openssl genrsa -out $CERT_DIR/server.key 2048
openssl req -new -key $CERT_DIR/server.key -out $CERT_DIR/server.csr -subj "/CN=${HOSTNAME}"

# Create a configuration file for the extensions
cat > $CERT_DIR/openssl.cnf <<EOL
[ v3_ca ]
basicConstraints = CA:FALSE
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = ${HOSTNAME}
EOL

# Generate server certificate signed by the CA
echo "Signing server certificate with CA..."
openssl x509 -req -in $CERT_DIR/server.csr -CA $CERT_DIR/ca.crt -CAkey $CERT_DIR/ca.key -CAcreateserial -out $CERT_DIR/server.crt -days 365 -sha256 -extfile $CERT_DIR/openssl.cnf -extensions v3_ca

# Clean up
rm $CERT_DIR/server.csr
rm $CERT_DIR/openssl.cnf
rm $CERT_DIR/ca.srl
