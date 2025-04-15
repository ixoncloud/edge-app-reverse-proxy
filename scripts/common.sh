#!/bin/bash

# Function to load environment variables from .env file
load_env() {
  if [ -f .env ]; then
    # Export variables, ignoring lines starting with # and empty lines
    export $(grep -v '^\s*\(#\|$\)' .env | xargs)
  else
    echo "Error: .env file not found."
    exit 1
  fi
}

# Function to check if all required environment variables are set
check_required_vars() {
  local required_vars=(
    "SECURE_EDGE_IP"
    "SECURE_EDGE_PASSWORD"
  )

  for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
      echo "Error: Required environment variable $var is not set"
      exit 1
    fi
  done
}

# SecureEdge API details (will be set after loading env)
# Only initialize if not already set
if [ -z "$SECURE_EDGE_URL" ]; then
    SECURE_EDGE_URL=""
fi
if [ -z "$COOKIE_JAR" ]; then
    COOKIE_JAR="session.jar"
fi

# Function to set the SecureEdge URL
set_secure_edge_url() {
  SECURE_EDGE_URL="http://${SECURE_EDGE_IP}"
  export SECURE_EDGE_URL
}

# Clean up cookie jar on exit
# Note: This trap will be active in any script that sources common.sh
trap 'rm -f $COOKIE_JAR' EXIT

# Define container names and configurations (consider moving these definitions here later if beneficial)

echo "Common functions loaded." 
