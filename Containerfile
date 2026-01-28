# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:43
LABEL author="Chris Collins <collins.christopher@gmail.com>"

ARG GIT_HASH
LABEL toolbox-devtools-version=${GIT_HASH}

ENV EDITOR=vi
ENV CONTAINER_SUBSYS="flatpak-spawn --host podman"

# Define package lists
# Pinentry/gnome-keyring needed for GPG signing,etc
# flatpak-xdg-open allows for opening the browser outside of the toolbox
ENV PKGS="make gcc bison binutils jq flatpak flatpak-spawn glab httpie NetworkManager nodejs-npm tmux flatpak-xdg-open gnome-keyring glab pinentry ShellCheck skopeo tox yamllint yq"
ENV LANGUAGE_PKGS="python3 python3-pip tinygo"
ENV DOCUMENT_PKGS="pandoc texlive"
ENV NPM_PKGS="@anthropic-ai/claude-code markdownlint-cli2"

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

# Install NPM packages (separate layer allows caching when only NPM deps change)
RUN npm install -g ${NPM_PKGS}

# Create podman wrapper script to use host podman via flatpak-spawn
# This allows the toolbox container to interact with the host's podman daemon
RUN printf '#!/bin/sh\nexec ${CONTAINER_SUBSYS} "$@"\n' > /usr/bin/podman \
  && chmod +x /usr/bin/podman

