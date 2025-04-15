#!/bin/bash

# Output executed commands and stop on errors.
set -e -x

# Source common functions and variables
source "$(dirname "$0")/scripts/common.sh"

# Load environment variables and check required variables
load_env
check_required_vars

# Set SecureEdge URL
set_secure_edge_url

# Source and call authentication script
source "$(dirname "$0")/scripts/authenticate.sh"
authenticate

# Source and call setup_buildx script
source "$(dirname "$0")/scripts/setup_buildx.sh"
setup_buildx

# Source build_push_image script
source "$(dirname "$0")/scripts/build_push_image.sh"

# Define registry prefix and platform
REGISTRY_PREFIX="192.168.140.1:5000/"
PLATFORM="linux/arm64/v8"

# Build and push images
build_push_image "nginx-proxy" "nginx-proxy" "latest" "$REGISTRY_PREFIX" "$PLATFORM" "false"
build_push_image "backend-service1" "backend-service1" "latest" "$REGISTRY_PREFIX" "$PLATFORM" "false"
build_push_image "backend-service2" "backend-service2" "latest" "$REGISTRY_PREFIX" "$PLATFORM" "false"

# Source manage_container script
source "$(dirname "$0")/scripts/manage_container.sh"

# Check for required tools jq and envsubst
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install jq to continue."
    exit 1
fi
if ! command -v envsubst &> /dev/null; then
    echo "Error: envsubst (part of gettext) is not installed. Please install gettext to continue."
    exit 1
fi

# Define container names in an indexed array
container_names=(
  "nginx-proxy"
  "backend-service1"
  "backend-service2"
)

# Define the list of environment variables used in the JSON config for substitution
export PORT NODE_ENV NGINX_PORT
ENV_VARS_TO_SUBST='$PORT $NODE_ENV $NGINX_PORT'

# Define the path to the config file
CONFIG_FILE="$(dirname "$0")/container_configs.json"

# Check if the config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Loop through container names, find their config in JSON, substitute env vars, and manage them
for name in "${container_names[@]}"; do
  echo "--------------------------------------------------"
  echo "Processing container: $name"
  echo "--------------------------------------------------"

  # Extract the specific container config JSON object using jq based on the name
  config_json=$(jq -c '.[] | select(.container.name=="'"$name"'")' "$CONFIG_FILE")

  if [ -z "$config_json" ]; then
      echo "Error: Configuration for container '$name' not found in $CONFIG_FILE"
      continue # Skip to the next container
  fi

  # Substitute environment variables in the extracted JSON config string
  config=$(echo "$config_json" | envsubst "$ENV_VARS_TO_SUBST")

  manage_container "$name" "$config"
done

echo "--------------------------------------------------"
echo "Script finished."
echo "--------------------------------------------------" 
