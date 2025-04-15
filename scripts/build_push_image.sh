#!/bin/bash

# Output executed commands and stop on errors.
# set -e -x # Enable these if needed for debugging this specific script

# Function to build and push a single Docker image
# Arguments:
# $1: Source directory (relative to the project root)
# $2: Image name
# $3: Image tag (e.g., latest)
# $4: Registry prefix (e.g., 192.168.140.1:5000/)
# $5: Platform (e.g., linux/arm64/v8)
# $6: Use cache (boolean: true/false)
build_push_image() {
  local source_dir="$1"
  local image_name="$2"
  local image_tag="$3"
  local registry_prefix="$4"
  local platform="$5"
  local use_cache="$6"

  if [ -z "$source_dir" ] || [ -z "$image_name" ] || [ -z "$image_tag" ] || [ -z "$registry_prefix" ] || [ -z "$platform" ] || [ -z "$use_cache" ]; then
    echo "Error: Missing arguments for build_push_image function."
    echo "Usage: build_push_image <source_dir> <image_name> <tag> <registry_prefix> <platform> <use_cache (true|false)>"
    return 1 # Use return instead of exit if sourced
  fi

  local full_image_tag="${registry_prefix}${image_name}:${image_tag}"

  echo "--------------------------------------------------"
  echo "Building and pushing image: $full_image_tag from directory: $source_dir"
  echo "Platform: $platform, Use Cache: $use_cache"
  echo "--------------------------------------------------"

  local original_dir=$(pwd)
  if [ ! -d "$source_dir" ]; then
      echo "Error: Source directory '$source_dir' not found."
      return 1
  fi

  cd "$source_dir"

  local build_cmd="docker buildx build --platform \"$platform\" --tag \"$full_image_tag\""

  if [ "$use_cache" == "false" ]; then
    build_cmd+=" --no-cache"
  fi

  build_cmd+=" --push ."

  echo "Executing build command: $build_cmd"
  eval $build_cmd # Using eval to handle potential spaces/quotes in args correctly

  if [ $? -ne 0 ]; then
      echo "Error building/pushing image $full_image_tag."
      cd "$original_dir"
      return 1
  fi

  cd "$original_dir"
  echo "Successfully built and pushed $full_image_tag."
  echo "--------------------------------------------------"
  return 0
}

# --- Main execution ---
# This script is intended to be sourced or called by another script.
# The build_push_image function should be called explicitly with arguments.
# Example usage in main script:
# source scripts/build_push_image.sh
# build_push_image "nginx-proxy" "nginx-proxy" "latest" "192.168.140.1:5000/" "linux/arm64/v8" "true"
# build_push_image "backend-service1" "backend-service1" "latest" "192.168.140.1:5000/" "linux/arm64/v8" "false"
# ...
#
# If running this script directly for testing:
# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
#   # Example call for testing - replace with actual values
#   build_push_image "nginx-proxy" "nginx-proxy" "latest" "localhost:5000/" "linux/amd64" "true"
# fi 
