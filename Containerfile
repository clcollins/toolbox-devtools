# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:43 as base
RUN dnf install --assumeyes jq \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

FROM base as claude
# Install Claude Code
# Download, verify checksum, and install; then update to latest
ARG CLAUDE_VERSION="2.1.39"
ARG CLAUDE_CHECKSUM="68e4775b293d95e06d168581c523fc5c1523968179229d31a029f285b2aceaff"
ARG CLAUDE_PLATFORM="linux-x64"
ARG CLAUDE_GCS_BUCKET="https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases"

RUN curl -fSL "${CLAUDE_GCS_BUCKET}/${CLAUDE_VERSION}/${CLAUDE_PLATFORM}/claude" -o /usr/local/bin/claude \
  && echo "${CLAUDE_CHECKSUM}  /usr/local/bin/claude" | sha256sum --check --status \
  && chmod +x /usr/local/bin/claude

FROM base as promtool
# Install promtool (from Prometheus release)
# Download, verify checksum, and install
ARG PROMTOOL_VERSION="3.13.1"
ARG PROMTOOL_CHECKSUM="962b812371aff838d152b6ff2d56fdb7a6396f5542f48ebf73421b9721f0d103"

RUN curl -fSL "https://github.com/prometheus/prometheus/releases/download/v${PROMTOOL_VERSION}/prometheus-${PROMTOOL_VERSION}.linux-amd64.tar.gz" -o /tmp/promtool.tar.gz \
  && echo "${PROMTOOL_CHECKSUM}  /tmp/promtool.tar.gz" | sha256sum --check --status \
  && tar xz --strip-components=1 -C /usr/local/bin -f /tmp/promtool.tar.gz "prometheus-${PROMTOOL_VERSION}.linux-amd64/promtool" \
  && rm /tmp/promtool.tar.gz

FROM base as kustomize
# Install kustomize
# Download, verify checksum, and install
ARG KUSTOMIZE_VERSION="5.8.1"
ARG KUSTOMIZE_CHECKSUM="029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d"

RUN curl -fSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tar.gz \
  && echo "${KUSTOMIZE_CHECKSUM}  /tmp/kustomize.tar.gz" | sha256sum --check --status \
  && tar xz -C /usr/local/bin -f /tmp/kustomize.tar.gz kustomize \
  && rm /tmp/kustomize.tar.gz

FROM base as kubeseal
# Install kubeseal
# Download, verify checksum, and install
ARG KUBESEAL_VERSION="0.38.4"
ARG KUBESEAL_CHECKSUM="ab5ae808b0efcb167a825b6cf7f3a7c0034bd99a6301d78db2012da651a8c0b9"

RUN curl -fSL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz" -o /tmp/kubeseal.tar.gz \
  && echo "${KUBESEAL_CHECKSUM}  /tmp/kubeseal.tar.gz" | sha256sum --check --status \
  && tar xz -C /usr/local/bin -f /tmp/kubeseal.tar.gz kubeseal \
  && rm /tmp/kubeseal.tar.gz

FROM base as kubectl
# Install kubectl
# Download and verify checksum
ARG KUBECTL_VERSION="v1.36.3"
ARG KUBECTL_CHECKSUM="ebbd080e7c2e275093b55915722043257eb24004363e20acb3c4d71919f88336"

RUN curl -fSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && echo "${KUBECTL_CHECKSUM}  /usr/local/bin/kubectl" | sha256sum --check --status \
  && chmod +x /usr/local/bin/kubectl

FROM base as jira-cli
# Install Jira CLI (ankitpokhrel/jira-cli)
# Download, verify checksum, and install
ARG JIRA_VERSION="1.7.0"
ARG JIRA_CHECKSUM="b5e0ba4804f3f11f92c483d9a6ea9ebccec1c735cd2e12b0440cab9d7afd626a"

RUN curl -fSL "https://github.com/ankitpokhrel/jira-cli/releases/download/v${JIRA_VERSION}/jira_${JIRA_VERSION}_linux_x86_64.tar.gz" -o /tmp/jira.tar.gz \
  && echo "${JIRA_CHECKSUM}  /tmp/jira.tar.gz" | sha256sum --check --status \
  && tar xz --strip-components=2 -C /usr/local/bin -f /tmp/jira.tar.gz "jira_${JIRA_VERSION}_linux_x86_64/bin/jira" \
  && rm /tmp/jira.tar.gz \
  && mkdir -p /etc/bash_completion.d \
  && jira completion bash > /etc/bash_completion.d/jira

FROM base
LABEL author="Chris Collins <collins.christopher@gmail.com>"

ENV EDITOR=vi
ENV CONTAINER_SUBSYS="flatpak-spawn --host podman"

# Define package lists
# Pinentry/gnome-keyring needed for GPG signing,etc
# flatpak-xdg-open allows for opening the browser outside of the toolbox
# guestfs-tools provides virt-builder for building custom disk images
ENV PKGS="make gcc bison binutils jq flatpak flatpak-spawn glab httpie NetworkManager tmux flatpak-xdg-open gnome-keyring pinentry ShellCheck skopeo tox yamllint yq guestfs-tools pipewire-utils bats python3-ansible-lint ansible buildah bind-utils xdg-utils"

ENV PKGS="${PKGS} python3 python3-pip tinygo"
ENV PKGS="${PKGS} pandoc texlive"

# Google Cloud CLI
# Repository: https://cloud.google.com/sdk/docs/install#rpm
ENV GCLOUD_CLI="https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64"
ENV GCLOUD_CLI_REPO_NAME="packages.cloud.google.com_yum_repos_cloud-sdk-el9-x86_64"
ENV GCLOUD_KEYS="https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"
ENV PKGS="${PKGS} libxcrypt-compat.x86_64 google-cloud-cli"

# Charm repository
ENV CHARM_REPO="https://repo.charm.sh/yum/"
ENV CHARM_REPO_NAME="Charm"
ENV CHARM_KEYS="https://repo.charm.sh/yum/gpg.key"
ENV PKGS="${PKGS} crush"

# Hashicorp repository
# Note: Exclude openbao packages as they also provide vault binary and conflict with hashicorp vault
ENV VAULT_CLI_REPO="https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
ENV VAULT_CLI_REPO_NAME="hashicorp"
ENV PKGS="${PKGS} vault"

# GitHub CLI repo
ENV GH_CLI="https://cli.github.com/packages/rpm/gh-cli.repo"
ENV GH_CLI_REPO_NAME="gh-cli"
ENV PKGS="${PKGS} gh"

# VS Code repository
ENV VSCODE_REPO="https://packages.microsoft.com/yumrepos/vscode"
ENV VSCODE_REPO_NAME="vscode"
ENV VSCODE_KEYS="https://packages.microsoft.com/keys/microsoft.asc"
ENV PKGS="${PKGS} code"

# Install config-manager, create repo files, and import keys
RUN dnf install --assumeyes 'dnf-command(config-manager)' \
  && dnf config-manager addrepo --set=baseurl=${GCLOUD_CLI} --id=${GCLOUD_CLI_REPO_NAME} \
  && dnf config-manager addrepo --set=baseurl=${CHARM_REPO} --id=${CHARM_REPO_NAME} \
  && dnf config-manager addrepo --from-repofile=${VAULT_CLI_REPO} \
  && dnf config-manager addrepo --from-repofile=${GH_CLI} \
  && dnf config-manager addrepo --set=baseurl=${VSCODE_REPO} --id=${VSCODE_REPO_NAME} \
  && rpm --import ${GCLOUD_KEYS} \
  && rpm --import ${CHARM_KEYS} \
  && rpm --import ${VSCODE_KEYS} \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Update system, then install packages
# Skip weak dependencies and docs to reduce image size
RUN dnf update --assumeyes \
  && dnf install --assumeyes --setopt=install_weak_deps=False --setopt=tsflags=nodocs --exclude=openbao --exclude=openbao-vault-compat $PKGS \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Use flatpak-xdg-open to open browsers external to the toolbox
# Force the symlink since xdg-utils also installs its own /usr/bin/xdg-open
RUN ln -sf /usr/bin/flatpak-xdg-open /usr/bin/xdg-open

# Create podman wrapper script to use host podman via flatpak-spawn.
# Forwards all environment variables to the host's podman using --env-fd
# with null-delimited output, so env vars (e.g., GITHUB_TOKEN) are available
# to podman build --secret env= and other commands that need them.
RUN printf '#!/bin/bash\nexec 3< <(env -0)\nexec flatpak-spawn --host --env-fd=3 podman "$@"\n' > /usr/bin/podman \
  && chmod +x /usr/bin/podman

# Copy binaries from multi-stage containers
COPY --from=claude /usr/local/bin/claude /usr/local/bin/claude
COPY --from=promtool /usr/local/bin/promtool /usr/local/bin/promtool
COPY --from=kustomize /usr/local/bin/kustomize /usr/local/bin/kustomize
COPY --from=kubeseal /usr/local/bin/kubeseal /usr/local/bin/kubeseal
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=jira-cli /usr/local/bin/jira /usr/local/bin/jira
COPY --from=jira-cli /etc/bash_completion.d/jira /etc/bash_completion.d/jira

# Placed last so that GIT_HASH changing on every commit only busts this
# layer's cache, not the expensive package-install layers above it.
# The RUN step forces a genuine cache-key change when GIT_HASH changes;
# LABEL alone does not reliably bust cache on a changed ARG value.
ARG GIT_HASH
RUN echo "${GIT_HASH}" > /etc/toolbox-devtools-version
LABEL toolbox-devtools-version=${GIT_HASH}
