#!/bin/bash

# Output executed commands and stop on errors.
# set -e -x # Enable these if needed for debugging this specific script

generate_buildkitd_config() {
  # Source the .env file to get SECURE_EDGE_IP
  if [ ! -f .env ]; then
      echo "Error: .env file not found in the root directory."
      exit 1
  fi
  source .env

  # Generate the buildkitd configuration file
  cat > buildkitd-secure-edge-pro.toml << EOF
[registry."${SECURE_EDGE_IP}:5000"]
http = true
EOF

  echo "Generated buildkitd-secure-edge-pro.toml with IP from .env"
}

setup_buildx() {
  echo "Setting up Docker Buildx environment 'secure-edge-pro'..."

  # Remove the existing instance if necessary, ignore errors if it doesn't exist
  echo "Removing existing buildx instance 'secure-edge-pro' (if any)..."
  docker buildx rm secure-edge-pro > /dev/null 2>&1 || true

  # Generate the buildkitd configuration file
  generate_buildkitd_config

  # Create and initialize the build environment.
  echo "Creating new buildx instance 'secure-edge-pro'..."
  docker buildx create --name secure-edge-pro \
                       --config buildkitd-secure-edge-pro.toml

  echo "Setting 'secure-edge-pro' as the current buildx builder..."
  docker buildx use secure-edge-pro

  echo "Docker Buildx setup complete."
}

# --- Main execution ---
# This script is intended to be sourced or called by another script.
# The setup_buildx function should be called explicitly.
# Example usage in main script:
# source scripts/setup_buildx.sh
# setup_buildx
#
# If running this script directly for testing:
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   setup_buildx
# fi 
