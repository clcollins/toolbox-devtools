#!/bin/sh

sudo dnf install -y make git
CONTAINER_SUBSYS="flatpak-spawn --host podman" make
toolbox create devtools --image localhost/devtools:latest
