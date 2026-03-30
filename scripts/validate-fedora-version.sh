#!/bin/sh

set -o errexit
set -o nounset

echo "Validating Fedora version consistency..."
CONTAINERFILE_VERSION=$(grep -E '^FROM registry.fedoraproject.org/fedora-toolbox:' Containerfile | sed -E 's/.*:([0-9]+).*/\1/')
CI_VERSION=$(grep -E 'image: fedora:' .github/workflows/ci.yaml | sed -E 's/.*fedora:([0-9]+).*/\1/' | head -1)
echo "  Containerfile: Fedora ${CONTAINERFILE_VERSION}"
echo "  CI workflow:   Fedora ${CI_VERSION}"
if [ "${CONTAINERFILE_VERSION}" != "${CI_VERSION}" ]; then
	echo "Error: Fedora version mismatch between Containerfile and CI workflow!" >&2
	exit 1
fi
echo "Fedora versions match (${CONTAINERFILE_VERSION})"
