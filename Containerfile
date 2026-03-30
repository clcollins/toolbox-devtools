# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the
# host to be used from within the toolbox via the flatpak-spawn command.

# Claude Code Builder
# hadolint ignore=DL3007
FROM quay.io/redhat-services-prod/openshift/ocm-container:latest AS claude-builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Version 2.1.39 released 2026-02-10T21:13:30Z
# Will update to latest with `claude install latest` further in the build
# Only needs to happen on a fresh build with a fresh host since the binary directory is shared with the toolbox
ARG CLAUDE_VERSION="2.1.39"
ARG CLAUDE_CHECKSUM="68e4775b293d95e06d168581c523fc5c1523968179229d31a029f285b2aceaff"
ARG CLAUDE_PLATFORM="linux-x64"
ARG CLAUDE_GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

# Download and verify Claude Code binary
RUN curl -sL "${CLAUDE_GCS_BUCKET}/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" -o /tmp/claude \
    && echo "${CLAUDE_CHECKSUM}  /tmp/claude" | sha256sum --check --status \
    && chmod +x /tmp/claude

FROM registry.fedoraproject.org/fedora-toolbox:43
LABEL author="Chris Collins <collins.christopher@gmail.com>"

ARG GIT_HASH
LABEL toolbox-devtools-version=${GIT_HASH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV EDITOR=vi
ENV CONTAINER_SUBSYS="flatpak-spawn --host podman"

# Define package lists
# Pinentry/gnome-keyring needed for GPG signing,etc
# flatpak-xdg-open allows for opening the browser outside of the toolbox
# guestfs-tools provides virt-builder for building custom disk images
ENV PKGS="make gcc bison binutils jq flatpak flatpak-spawn glab httpie NetworkManager nodejs-npm tmux flatpak-xdg-open gnome-keyring glab pinentry ShellCheck skopeo tox yamllint yq guestfs-tools"
ENV LANGUAGE_PKGS="python3 python3-pip tinygo"
ENV DOCUMENT_PKGS="pandoc texlive"

# Update system and install base packages plus config-manager
RUN dnf update --assumeyes \
  && dnf install --assumeyes 'dnf-command(config-manager)' $PKGS $LANGUAGE_PKGS $DOCUMENT_PACKAGES \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Use flatpak-xdg-open to open browsers external to the toolbox
RUN ln -s /usr/bin/flatpak-xdg-open /usr/bin/xdg-open

# Install Google Cloud CLI
# Repository: https://cloud.google.com/sdk/docs/install#rpm
ENV GCLOUD_CLI="https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64"
ENV GCLOUD_CLI_REPO_NAME="packages.cloud.google.com_yum_repos_cloud-sdk-el9-x86_64"
ENV GCLOUD_KEYS="https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"

RUN dnf config-manager addrepo --set=baseurl=${GCLOUD_CLI} --id=${GCLOUD_CLI_REPO_NAME} --set=enabled=0 \
  && rpm --import ${GCLOUD_KEYS} \
  && dnf install --assumeyes libxcrypt-compat.x86_64 \
  && dnf install --assumeyes --from-repo=${GCLOUD_CLI_REPO_NAME} google-cloud-cli \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install Hashicorp Vault
# Note: Exclude openbao packages as they also provide vault binary and conflict with hashicorp vault
ENV VAULT_CLI_REPO="https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
ENV VAULT_CLI_REPO_NAME="hashicorp"

RUN dnf config-manager addrepo --from-repofile=${VAULT_CLI_REPO} \
  && dnf config-manager setopt ${VAULT_CLI_REPO_NAME}.enabled=0 \
  && dnf install --assumeyes --from-repo=${VAULT_CLI_REPO_NAME} --exclude=openbao --exclude=openbao-vault-compat vault \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install GitHub CLI
ENV GH_CLI="https://cli.github.com/packages/rpm/gh-cli.repo"
ENV GH_CLI_REPO_NAME="gh-cli"

RUN dnf config-manager addrepo --from-repofile=${GH_CLI} \
  && dnf config-manager setopt ${GH_CLI_REPO_NAME}.enabled=0 \
  && dnf install --assumeyes --from-repo=${GH_CLI_REPO_NAME} gh \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install Claude Code
COPY --from=claude-builder /tmp/claude ${BIN_DIR}/claude
RUN claude install latest

# Create podman wrapper script to use host podman via flatpak-spawn
# This allows the toolbox container to interact with the host's podman daemon
RUN printf '#!/bin/sh\nexec ${CONTAINER_SUBSYS} "$@"\n' > /usr/bin/podman \
  && chmod +x /usr/bin/podman

