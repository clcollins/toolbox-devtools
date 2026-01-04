#!/bin/sh

set -o errexit
set -o nounset

echo "Installing build dependencies..."
sudo dnf install -y make git

echo "Building devtools image..."
CONTAINER_SUBSYS="flatpak-spawn --host podman" make build

# Verify the image was built successfully
if ! flatpak-spawn --host podman image exists localhost/devtools:latest; then
  echo "Error: Image build failed. Please check the build output above." >&2
  exit 1
fi

echo "Creating devtools toolbox container..."
toolbox create devtools --image localhost/devtools:latest

echo "Bootstrap complete! Enter the devtools container with: toolbox enter devtools"
