#!/bin/bash

# Output executed commands and stop on errors.
# set -e -x # Enable these if needed for debugging this specific script

# Function to manage a single container (check, stop, remove, create, start)
# Arguments:
# $1: Container name
# $2: Container configuration JSON
manage_container() {
  local container_name="$1"
  local container_config="$2"

  if [ -z "$container_name" ] || [ -z "$container_config" ]; then
    echo "Error: Missing arguments for manage_container function."
    echo "Usage: manage_container <container_name> <container_config_json>"
    return 1 # Use return instead of exit if sourced
  fi

  # Ensure SecureEdge URL and cookie jar are set
  if [ -z "$SECURE_EDGE_URL" ] || [ ! -f "$COOKIE_JAR" ]; then
    echo "Error: SECURE_EDGE_URL or COOKIE_JAR not set. Ensure common.sh sourced and authentication is done."
    return 1
  fi

  echo "--------------------------------------------------"
  echo "Processing container: $container_name"
  echo "--------------------------------------------------"

  # --- Check if container already exists ---
  echo "Checking if container '$container_name' already exists..."
  local status_code=$(curl --request GET \
       --url "${SECURE_EDGE_URL}/api/v1/docker/containers/${container_name}/status" \
       --cookie "$COOKIE_JAR" \
       --write-out "%{http_code}" --silent --output /dev/null)

  if [ "$status_code" -eq 200 ]; then
    echo "Container '$container_name' already exists. Stopping and removing it first."

    # --- Stop existing container ---
    echo "Stopping container '$container_name'..."
    curl --request POST \
         --url "${SECURE_EDGE_URL}/api/v1/docker/containers/${container_name}/stop" \
         --cookie "$COOKIE_JAR" \
         --fail --silent --show-error || echo "Warning: Failed to stop container '$container_name'. It might already be stopped."

    # Add a small delay to allow container to stop
    sleep 2

    # --- Remove existing container ---
    echo "Removing container '$container_name'..."
    local remove_container_response_code=$(curl --request DELETE \
         --url "${SECURE_EDGE_URL}/api/v1/docker/containers/${container_name}" \
         --cookie "$COOKIE_JAR" \
         --write-out "%{http_code}" --silent --output /dev/null)

    # Check if removal was successful (200 OK or 204 No Content)
    if [ "$remove_container_response_code" -eq 200 ] || [ "$remove_container_response_code" -eq 204 ]; then
      echo "Container '$container_name' removed successfully."

      echo "Removing volumes based on container configuration..."

      # Parse volumes from the JSON string using echo to pipe the content to jq
      echo "$container_config" | jq -r '.volumes[]?.name // empty' | while read -r volume_to_delete; do
        if [ -n "$volume_to_delete" ]; then
          echo "Removing volume '$volume_to_delete'..."
          curl --request DELETE \
               --url "${SECURE_EDGE_URL}/api/v1/docker/volumes/${volume_to_delete}" \
               --cookie "$COOKIE_JAR" \
               --fail --silent --show-error || echo "Warning: Could not remove volume '$volume_to_delete' (it might not exist or deletion failed)."
        fi
      done
    else
      echo "Warning: Failed to remove container '$container_name' (HTTP status: $remove_container_response_code). Skipping volume removal."
    fi

    # Add a small delay after removal
    sleep 1
  elif [ "$status_code" -eq 404 ]; then
    echo "Container '$container_name' does not exist. Proceeding with creation."
  else
    echo "Error checking status for container '$container_name'. HTTP status: $status_code"
    return 1
  fi

  # --- Create container ---
  echo "Creating container '$container_name' with configuration:"
  echo "$container_config"
  local create_response_code=$(curl --request POST \
       --url "${SECURE_EDGE_URL}/api/v1/docker/containers" \
       --cookie "$COOKIE_JAR" \
       --header 'Content-Type: application/json' \
       --data "$container_config" \
       --write-out "%{http_code}" --output create_output.txt)

  if [ "$create_response_code" -eq 200 ]; then
    echo "Container '$container_name' created successfully (or image was cached)."
  elif [ "$create_response_code" -eq 504 ]; then
    echo "Container '$container_name' creation timed out (HTTP 504). This is expected for large images on first creation. Continuing in background."
    # Add a delay to allow background creation to progress
    echo "Waiting for potential background creation..."
    sleep 15 # Adjust sleep time as needed
  else
    echo "Error creating container '$container_name'. HTTP status: $create_response_code"
    echo "Response body:"
    cat create_output.txt
    rm -f create_output.txt # Clean up output file if it exists
    return 1
  fi
  rm -f create_output.txt # Clean up output file if it exists

  # --- Start container ---
  # Wait a bit before starting, especially after a potential timeout
  sleep 2
  echo "Starting container '$container_name'..."
  local start_response_code=$(curl --request POST \
       --url "${SECURE_EDGE_URL}/api/v1/docker/containers/${container_name}/start" \
       --cookie "$COOKIE_JAR" \
       --write-out "%{http_code}" --silent --output /dev/null)

  if [ "$start_response_code" -eq 200 ] || [ "$start_response_code" -eq 204 ]; then # 204 No Content is also sometimes returned on success
    echo "Container '$container_name' started successfully."
  else
    echo "Error starting container '$container_name'. HTTP status: $start_response_code"
    # Attempt to get status to see if it's running despite the error
    sleep 1
    if curl --request GET --url "${SECURE_EDGE_URL}/api/v1/docker/containers/${container_name}/status" --cookie "$COOKIE_JAR" --silent | grep -q '"status":"running"'; then
      echo "Container '$container_name' appears to be running despite the start command error code."
    else
      echo "Failed to start container '$container_name' and it does not appear to be running."
      return 1
    fi
  fi

  echo "--------------------------------------------------"
  return 0
}

# --- Main execution ---
# This script is intended to be sourced or called by another script.
# The manage_container function should be called explicitly with arguments.
# Example usage in main script:
# source scripts/common.sh
# load_env
# check_required_vars
# set_secure_edge_url
# source scripts/authenticate.sh
# authenticate
# source scripts/manage_container.sh
# manage_container "nginx-proxy" "{ \"container\": { \"name\": \"nginx-proxy\" }, ... }"
#
# If running this script directly for testing:
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   # Example call for testing - replace with actual values
#   source "$(dirname "$0")/common.sh"
#   load_env
#   check_required_vars
#   set_secure_edge_url
#   source "$(dirname "$0")/authenticate.sh"
#   authenticate
#   manage_container "nginx-proxy" "{ \"container\": { \"name\": \"nginx-proxy\" }, ... }"
# fi 
