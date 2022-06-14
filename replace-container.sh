#!/bin/sh

set -o errexit
set -o nounset

CONTAINER="devtools"
IMAGE="localhost/${CONTAINER}:latest"

if [[ ${HOSTNAME} == "toolbox" ]] ;
then
  echo "Cannot replace container from inside itself."
  exit 1
fi

podman stop --ignore $CONTAINER
toolbox rm $CONTAINER
toolbox create $CONTAINER --image $IMAGE

