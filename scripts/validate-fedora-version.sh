#!/bin/sh

set -o errexit
set -o nounset

echo "Validating Fedora version consistency..."
CONTAINERFILE_VERSION=$(grep -E '^FROM registry.fedoraproject.org/fedora-toolbox:' Containerfile | sed -E 's/.*:([0-9]+).*/\1/' || true)
if [ -z "${CONTAINERFILE_VERSION}" ]; then
	echo "Error: could not determine Containerfile Fedora version" >&2
	exit 1
fi

CI_VERSIONS_RAW=$(grep -E 'image: fedora:' .github/workflows/ci.yaml | sed -E 's/.*fedora:([0-9]+).*/\1/' | sort -u || true)
if [ -z "${CI_VERSIONS_RAW}" ]; then
	echo "Error: could not determine CI workflow Fedora version" >&2
	exit 1
fi
CI_VERSION_COUNT=$(printf '%s\n' "${CI_VERSIONS_RAW}" | sed '/^$/d' | wc -l | tr -d ' ')
if [ "${CI_VERSION_COUNT}" -ne 1 ]; then
	echo "Error: Expected one unique Fedora version in CI, found ${CI_VERSION_COUNT}: ${CI_VERSIONS_RAW}" >&2
	exit 1
fi
CI_VERSION="${CI_VERSIONS_RAW}"

echo "  Containerfile: Fedora ${CONTAINERFILE_VERSION}"
echo "  CI workflow:   Fedora ${CI_VERSION}"
if [ "${CONTAINERFILE_VERSION}" != "${CI_VERSION}" ]; then
	echo "Error: Fedora version mismatch between Containerfile and CI workflow!" >&2
	exit 1
fi
echo "Fedora versions match (${CONTAINERFILE_VERSION})"
