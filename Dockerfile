FROM eclipse-mosquitto:2.0.18-openssl

# Install necessary packages
RUN apk update && apk add --no-cache openssl bash gettext

# Create necessary directories
RUN mkdir -p /mosquitto/password /mosquitto/data /mosquitto/log /mosquitto/certs

# Copy scripts
COPY scripts/generate-self-signed-certs.sh /usr/local/bin/
COPY scripts/docker-entrypoint.sh /usr/local/bin/

# Make scripts executable
RUN chmod +x /usr/local/bin/generate-self-signed-certs.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Copy mosquitto configuration
COPY mosquitto.conf /mosquitto/config/mosquitto.conf

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
