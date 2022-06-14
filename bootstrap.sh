#!/bin/sh

sudo dnf install -y make git
CONTAINER_SUBSYS="flatpak-spawn --host podman" make
