#!/bin/sh

set -o errexit
set -o nounset

CONTAINER="devtools"
IMAGE="localhost/${CONTAINER}:latest"

# Check if running inside a toolbox container
if [ "${HOSTNAME}" = "toolbox" ]; then
  echo "Error: Cannot replace container from inside itself." >&2
  exit 1
fi

# Verify image exists before attempting to replace container
if ! podman image exists "${IMAGE}"; then
  echo "Error: Image ${IMAGE} does not exist. Build it first with 'make build'." >&2
  exit 1
fi

# Stop and remove existing container if it exists
podman stop --ignore "${CONTAINER}"
toolbox rm "${CONTAINER}" 2>/dev/null || true

# Create new container from latest image
toolbox create "${CONTAINER}" --image "${IMAGE}"

