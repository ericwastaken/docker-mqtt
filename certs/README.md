# Certificates Directory (`/certs`)

This `/certs` directory stores the SSL/TLS certificates used by the Mosquitto MQTT broker to enable secure communication over the network.

## Contents

- **`ca.crt`**: The Certificate Authority (CA) certificate used to verify the server's certificate. Distribute this file to clients so they can trust the server's identity.
- **`server.crt`**: The server's SSL certificate signed by the CA. This file is used by the Mosquitto broker and should **not** be shared with clients.
- **`server.key`**: The private key corresponding to the server's SSL certificate. This file is critical for the server's security and must be kept confidential.

## Notes

- **Automatic Generation**: If these files do not exist when the Docker container is started, they will be automatically generated (using self-signed certs).
- **Security**: Ensure that `server.crt` and `server.key` are kept secure and are **never** shared outside the server environment.
- **Client Configuration**: Clients connecting to the MQTT broker should use the `ca.crt` file to verify the server's certificate.

---

For more detailed information on certificate generation, usage, and client setup, please refer to the main project [README](../README.md).