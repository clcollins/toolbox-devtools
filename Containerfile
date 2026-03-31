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
# Download, verify checksum, and install; then update to latest
ARG CLAUDE_VERSION="2.1.39"
ARG CLAUDE_CHECKSUM="68e4775b293d95e06d168581c523fc5c1523968179229d31a029f285b2aceaff"
ARG CLAUDE_PLATFORM="linux-x64"
ARG CLAUDE_GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

RUN curl -fSL "${CLAUDE_GCS_BUCKET}/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" -o /usr/local/bin/claude \
  && echo "${CLAUDE_CHECKSUM}  /usr/local/bin/claude" | sha256sum --check --status \
  && chmod +x /usr/local/bin/claude \
  && claude install latest

# Install promtool (from Prometheus release)
RUN PROMTOOL_VERSION=$(curl -sL https://api.github.com/repos/prometheus/prometheus/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
  && curl -sL "https://github.com/prometheus/prometheus/releases/download/v${PROMTOOL_VERSION}/prometheus-${PROMTOOL_VERSION}.linux-amd64.tar.gz" \
  | tar xz --strip-components=1 -C /usr/local/bin "prometheus-${PROMTOOL_VERSION}.linux-amd64/promtool"

# Install kustomize
RUN KUSTOMIZE_VERSION=$(curl -sL https://api.github.com/repos/kubernetes-sigs/kustomize/releases | jq -r '[.[] | select(.tag_name | startswith("kustomize/"))][0].tag_name' | sed 's|kustomize/||') \
  && curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" \
  | tar xz -C /usr/local/bin kustomize

# Install kubeseal
RUN KUBESEAL_VERSION=$(curl -sL https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | jq -r '.tag_name' | sed 's/^v//') \
  && curl -sL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" \
  | tar xz -C /usr/local/bin kubeseal

# Install kubectl
RUN KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt) \
  && curl -sL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

# Create podman wrapper script to use host podman via flatpak-spawn.
# Forwards all environment variables to the host's podman using --env-fd
# with null-delimited output, so env vars (e.g., GITHUB_TOKEN) are available
# to podman build --secret env= and other commands that need them.
RUN printf '#!/bin/sh\nexec 3< <(env -0)\nexec flatpak-spawn --host --env-fd=3 podman "$@"\n' > /usr/bin/podman \
  && chmod +x /usr/bin/podman
