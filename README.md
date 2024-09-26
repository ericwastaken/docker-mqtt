# Secure Mosquitto MQTT Broker with Docker

An open-source project to deploy a secure [Eclipse Mosquitto](https://mosquitto.org/) MQTT broker using Docker and Docker Compose. This setup includes SSL/TLS encryption, user authentication, dynamic configuration via environment variables, and supports MQTT over WebSockets.

## Features

- **Secure Communication**: SSL/TLS encryption using self-signed certificates.
- **User Authentication**: Username and password authentication for clients.
- **Dynamic Configuration**: Environment variables allow for easy customization.
- **Logging to Console**: Logs are output to the Docker console for easy monitoring.
- **IPv4 Only**: Configured to listen only on IPv4 addresses.
- **Data Persistence**: Data is stored in a volume for persistence across container restarts. (The default setup uses an automatically created Docker volume, but you can easily modify the `docker-compose.yml` file to use a named volume, external volume, or bind mount instead.)
- **WebSockets Support**: MQTT over WebSockets is enabled on port **9443**, allowing clients to connect using WebSockets over SSL/TLS.

## Prerequisites

- **Docker or Docker Desktop**
- **Docker Compose**
- **Git**: For cloning the repository

## Getting Started

### Clone the Repository

```bash
git clone https://github.com/ericwastaken/docker-mqtt.git
cd docker-mqtt
```

### Set Up Environment Variables

Create a `.env` file in the root directory to define your environment variables:

```env
USERNAME=mqttuser
PASSWORD=yourpassword
HOSTNAME=yourhostname
LOG_TYPE=debug
MQTT_PORT=8883
WEBSOCKET_PORT=9443
```

(A file `env.template` is provided as a template which you can copy and edit.)

**Required Environment Variables**:

- **`USERNAME`**: The username for MQTT authentication.
- **`PASSWORD`**: The password for MQTT authentication.
- **`HOSTNAME`**: The hostname or domain name of your MQTT broker.
- **`LOG_TYPE`**: Logging level (see below).
- **`MQTT_PORT`**: The port number on which the MQTT broker will listen for MQTT over SSL/TLS (default is `8883`).
- **`WEBSOCKET_PORT`**: The port number on which the MQTT broker will listen for MQTT over WebSockets with SSL/TLS (default is `9443`).

### Directory Structure & Files

- **`certs/`**: Stores SSL/TLS certificates. See [SSL/TLS Certificates](#ssltls-certificates) for more information. This directory is excluded from source control!
- **`scripts/`**: Contains startup scripts.
- **`compose.yml`**: Docker Compose configuration file.
- **`Dockerfile`**: Docker image definition.
- **`.env`**: Environment variables file.
- **`mosquitto.conf`**: Mosquitto configuration file.

## Usage

### Build and Run the Docker Container

Once you have created your **.env** file, build the Docker image and start the container using Docker Compose:

```bash
docker-compose up -d --build
```

- The `-d` flag runs the container in detached mode (in the background).
- The `--build` flag rebuilds the image if there have been changes.

### Stopping the Container

To stop and remove the container, run:

```bash
docker-compose down --volumes
```

(The `--volumes` flag removes the volumes associated with the container. If you instead want to keep the volumes, omit this flag.)

## Configuration

### Mosquitto Configuration

The Mosquitto configuration file is located at `mosquitto.conf` and uses environment variable placeholders that are substituted at runtime by **`/scripts/docker-entrypoint.sh`**.

The provided `mosquitto.conf` is a very basic configuration file that can be customized to suit your needs. It includes settings for SSL/TLS encryption, user authentication, logging, and now supports MQTT over WebSockets on port **9443**. See the [Mosquitto Configuration Manual](https://mosquitto.org/man/mosquitto-conf-5.html) for full config details.

**Provided `mosquitto.conf`:**

```conf
persistence true
persistence_location /mosquitto/data/

# Log to stdout
log_dest stdout
log_type ${LOG_TYPE}

# Define MQTT listener (SSL/TLS)
listener ${MQTT_PORT}
protocol mqtt
socket_domain ipv4

# SSL/TLS settings for MQTT listener
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key

# Define WebSockets listener (SSL/TLS)
listener ${WEBSOCKET_PORT}
protocol websockets
socket_domain ipv4

# SSL/TLS settings for WebSockets listener
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key

# Authentication
allow_anonymous false
password_file /mosquitto/password/passwd
```

If you make any changes to this config file, you should re-run the **build** to ensure they're incorporated into the container image.

We recommend you use variables where possible rather than a static configuration. To add more variable substitutions, add the variable to the `.env` file and update the `docker-entrypoint.sh` script:

```bash
# Set default values if not set
LOG_TYPE=${LOG_TYPE:-notice}
MQTT_PORT=${MQTT_PORT:-8883}
WEBSOCKET_PORT=${WEBSOCKET_PORT:-9443}

## Add more variables here following the above pattern including the default value.
## Also update the `envsubst` command in the script to include the new variable.

# Use envsubst to replace environment variables in mosquitto.conf
envsubst '${LOG_TYPE} ${MQTT_PORT} ${WEBSOCKET_PORT}' < /mosquitto/config/mosquitto.conf > /tmp/mosquitto.conf
```

### SSL/TLS Certificates

- **Automatic Generation**: If SSL certificates are not present in the `certs/` directory, they will be automatically generated when the container starts using a self-signed certificate.
- **Contents**:
  - `ca.crt`: CA certificate to distribute to clients.
  - `server.crt`: Server certificate used by Mosquitto.
  - `server.key`: Private key corresponding to the server certificate.

**For more details, see the [`certs/README.md`](certs/README.md).**

> **Note:** The self-signed certificates are not suitable for production use. You should replace them with certificates signed by a trusted CA before using this in a production environment.

### Logging

- **Logs Output to Console**: Logs are directed to `stdout` and can be viewed using Docker logs.
- **Adjust Logging Level**: Set the `LOG_TYPE` variable in your `.env` file to adjust the verbosity.

**Valid Log Types**:

- `error`: Error messages
- `warning`: Warning messages
- `notice`: Normal operational messages (default)
- `information`: Informational messages
- `debug`: Debugging messages

**Viewing Logs:**

```bash
docker-compose logs
```

## Client Setup

### MQTT over SSL/TLS (Port 8883)

Clients connecting over MQTT need to use SSL/TLS and provide authentication credentials.

**Example Using `mosquitto_sub`:**

```bash
mosquitto_sub -h yourhostname -p 8883 -t 'test/topic' \
  --cafile certs/ca.crt \
  -u 'mqttuser' -P 'yourpassword' -d
```

- **Replace**:
  - `yourhostname` with your broker's hostname.
  - `mqttuser` and `yourpassword` with your actual username and password.

#### mosquitto_sub/mosquitto_pub

The `mosquitto_sub` and `mosquitto_pub` commands are part of the Mosquitto MQTT client tools. You can install them on your system using your package manager or by building from source. See more details in the [Mosquitto Documentation](https://mosquitto.org/download/).

### MQTT over WebSockets with SSL/TLS (Port 9443)

Clients can connect using MQTT over WebSockets on port **9443** with SSL/TLS enabled.

**Example Using `mqtt.js`:**

```javascript
const mqtt = require('mqtt');
const fs = require('fs');

const options = {
  protocol: 'wss',
  host: 'yourhostname',
  port: 9443,
  username: 'mqttuser',
  password: 'yourpassword',
  rejectUnauthorized: false, // Set to true if using valid certificates
  ca: fs.readFileSync('path/to/ca.crt'), // Provide the CA certificate
};

const client = mqtt.connect(options);

client.on('connect', () => {
  console.log('Connected over secure WebSockets');
  client.subscribe('test/topic', (err) => {
    if (!err) {
      client.publish('test/topic', 'Hello MQTT over WebSockets with SSL/TLS!');
    }
  });
});

client.on('message', (topic, message) => {
  console.log(`Received message: ${message.toString()}`);
  client.end();
});
```

- **Ensure**:
  - The client uses the `wss` protocol for secure WebSockets.
  - The correct port (`9443`) is specified.
  - The `ca.crt` file is provided to the client to trust the server's certificate.

### MQTT Clients

There are many MQTT clients available for different platforms and languages. Here are a few popular ones:

- **[MQTT Explorer](http://mqtt-explorer.com/)**: A comprehensive MQTT client for Windows, macOS, and Linux.
- **[MQTT.fx](https://mqttfx.jensd.de/)**: A JavaFX-based MQTT client for Windows, macOS, and Linux.
- **[MQTT.js](https://github.com/mqttjs/MQTT.js/)**: A JavaScript MQTT client for Node.js and the browser.
- **[Paho MQTT Clients](https://www.eclipse.org/paho/)**: MQTT client libraries for various programming languages.
- **[Node-RED](https://nodered.org/)**: A flow-based development tool for visual programming using MQTT.

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork the Repository**: Click the "Fork" button at the top right of this page.
2. **Clone Your Fork**: `git clone https://github.com/ericwastaken/docker-mqtt.git`
3. **Create a Feature Branch**: `git checkout -b feature/YourFeature`
4. **Commit Your Changes**: `git commit -am 'Add new feature'`
5. **Push to the Branch**: `git push origin feature/YourFeature`
6. **Open a Pull Request**: Submit your pull request for review.

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

- [Eclipse Mosquitto](https://mosquitto.org/) for the MQTT broker.
- [Docker](https://www.docker.com/) for containerization technology.
- [OpenSSL](https://www.openssl.org/) for SSL/TLS support.

---

**Disclaimer**: This project is provided as-is without any warranties. Use at your own risk.