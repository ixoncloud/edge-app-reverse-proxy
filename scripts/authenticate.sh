#!/bin/bash

# Source common functions and variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Function to authenticate and get session cookie
authenticate() {
  # Ensure SecureEdge URL is set (needs SECURE_EDGE_IP from env)
  if [ -z "$SECURE_EDGE_URL" ]; then
      echo "Error: SECURE_EDGE_URL is not set. Ensure common.sh sourced and set_secure_edge_url was called."
      exit 1
  fi
  if [ -z "$SECURE_EDGE_PASSWORD" ]; then
      echo "Error: SECURE_EDGE_PASSWORD is not set."
      exit 1
  fi

  echo "Authenticating to SecureEdge at ${SECURE_EDGE_IP}..."
  # Use the COOKIE_JAR defined in common.sh
  curl --request POST \
       --url "${SECURE_EDGE_URL}/auth/login" \
       --cookie-jar "$COOKIE_JAR" \
       --data "username=admin" \
       --data "password=${SECURE_EDGE_PASSWORD}" \
       --fail --silent --show-error # Fail silently but show errors

  # Check if cookie jar was created
  if [ ! -f "$COOKIE_JAR" ]; then
      echo "Authentication failed. Cookie jar not created."
      exit 1
  else
      echo "Authentication successful. Session cookie stored in $COOKIE_JAR."
  fi
}

# --- Main execution ---
# This script is intended to be sourced or called by another script.
# The authenticate function should be called explicitly after sourcing common.sh
# and ensuring environment variables are loaded.
# Example usage in main script:
# source scripts/common.sh
# load_env
# check_required_vars
# set_secure_edge_url
# source scripts/authenticate.sh
# authenticate
#
# If running this script directly for testing:
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   # Load env vars if run directly
#   load_env
#   check_required_vars
#   set_secure_edge_url
#   authenticate
# fi 
