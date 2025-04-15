# Edge App - Reverse Proxy

This project provides a reverse proxy solution for using multiple backend services on the IXON SecureEdge Pro gateway via a single Web Access entry point. It includes an NGINX reverse proxy and two backend services, all containerized and ready for deployment.

## Prerequisites

1. Ensure your environment is properly set up by following this guide: [Running custom Docker applications on the SecureEdge Pro](https://support.ixon.cloud/hc/en-us/articles/14231117531420-Running-custom-Docker-applications-on-the-SecureEdge-Pro)
2. Required tools:
   - Docker and Docker Buildx
   - `jq` for JSON processing
   - `gettext` package (for `envsubst` command)
   - Access to IXON SecureEdge Pro gateway

## Application Overview

The application consists of three main components:

1. **NGINX Reverse Proxy** (`nginx-proxy`)

   - Serves as the main entry point (port 8000)
   - Routes traffic to appropriate backend services
   - Configurable through environment variables

2. **Backend Service 1** (`backend-service1`)

   - Runs on port 8081
   - Includes persistent data storage

3. **Backend Service 2** (`backend-service2`)
   - Runs on port 8082
   - Includes persistent data storage

All services run in their own containers and are connected through the `machine-builder` network.

## Configuration

1. Copy `.env-example` to `.env` and configure your environment variables:

   ```bash
   cp .env-example .env
   ```

2. The `container_configs.json` file contains the configuration for all containers, including:
   - Container names and image tags
   - Port mappings
   - Volume mounts
   - Environment variables
   - Network settings

## Configuring Web Access in IXON Cloud

To enable remote access to your reverse proxy and backend services through IXON Cloud:

1. **Add HTTP WebAccess in Fleet Manager**

   - Navigate to Fleet Manager > Devices and select your device
   - Click the add icon in the Services section
   - Select "HTTP server"
   - Configure the following settings:
     - Name: Choose a descriptive name (e.g., "Reverse Proxy")
     - Service group: (Optional) Group related services
     - Protocol: HTTP
     - Port: 8000 (default port for the reverse proxy)
     - Default landing page: "/"
     - Access Category: Configure who can access this service
     - Show in device overview: Enable for easy access

2. **Push Configuration**

   - After adding the HTTP WebAccess, click "Push config to device"
   - Note: The device may temporarily disconnect while applying new settings

3. **Accessing the Services**
   - Go to IXON Portal > Devices
   - Find your device and click the HTTP WebAccess button
   - The reverse proxy will route requests to the appropriate backend service based on the URL path

Note: All communication between your computer and the device will be secure, regardless of using HTTP internally.

## Steps to Deploy and Run

1. **Prepare the Environment**

   ```bash
   # Make the deployment script executable
   chmod +x deploy_edge_services.sh
   ```

2. **Deploy the Services**

   ```bash
   ./deploy_edge_services.sh
   ```

   This script will:

   - Authenticate with the SecureEdge Pro
   - Set up Docker Buildx
   - Build and push container images
   - Deploy and start all services

3. **Verify Deployment**
   - Access the NGINX proxy at `http://<your-gateway-ip>:8000`
   - Backend services will be available at their respective endpoints

## Project Structure

```
.
├── nginx-proxy/           # NGINX reverse proxy configuration
├── backend-service1/      # First backend service
├── backend-service2/      # Second backend service
├── scripts/              # Deployment and utility scripts
├── container_configs.json # Container configurations
├── deploy_edge_services.sh # Main deployment script
└── .env-example          # Example environment variables
```

## Troubleshooting

1. **Container Issues**

   - Check container logs using Docker commands
   - Verify network connectivity between containers
   - Ensure all required ports are accessible

2. **Deployment Issues**
   - Verify your `.env` configuration
   - Check SecureEdge Pro connectivity
   - Ensure all required tools are installed

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

See the [LICENSE.md](LICENSE.md) file for details.
