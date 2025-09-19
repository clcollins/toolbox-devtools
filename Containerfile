# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the 
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:42
LABEL author "Chris Collins <collins.christopher@gmail.com>"

ARG GIT_HASH
LABEL toolbox-devtools-version=${GIT_HASH}

ENV EDITOR=vi

ENV CONTAINER_SUBSYS "flatpak-spawn --host podman"
ENV PKGS "make gcc bison binutils jq flatpak flatpak-spawn httpie NetworkManager nodejs-npm tmux gnome-keyring glab ShellCheck skopeo tox yamllint yq"
ENV LANGUAGE_PKGS "python3 python3-pip tinygo"

ENV NPM_PKGS "@anthropic-ai/claude-code markdownlint-cli2"

RUN  dnf update --assumeyes \
  && dnf install --assumeyes 'dnf-command(config-manager)' \
  && dnf install --assumeyes $PKGS $LANGUAGE_PKGS \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

RUN npm install -g $NPM_PKGS

# Install Google Cloud CLI
ENV GCLOUD_CLI "https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64"
ENV GCLOUD_CLI_REPO_NAME "packages.cloud.google.com_yum_repos_cloud-sdk-el9-x86_64"
ENV GCLOUD_KEYS "https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"

RUN dnf config-manager addrepo --set=baseurl=${GCLOUD_CLI} --id=${GCLOUD_CLI_REPO_NAME} --set=enabled=0 \
  && rpm --import $GCLOUD_KEYS \
  && dnf install --assumeyes libxcrypt-compat.x86_64 \
  && dnf install --assumeyes --from-repo=${GCLOUD_CLI_REPO_NAME} google-cloud-cli \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install Hashicorp Vault
ENV VAULT_CLI_REPO "https://rpm.releases.hashicorp.com/fedora/hashicorp.repo"
ENV VAULT_CLI_REPO_NAME "hashicorp"

RUN dnf config-manager addrepo --from-repofile=${VAULT_CLI_REPO} \
  && dnf install --assumeyes --from-repo=${VAULT_CLI_REPO_NAME} vault \
  && dnf config-manager setopt ${VAULT_CLI_REPO_NAME}.enabled=0 \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install gh cli
ENV GH_CLI "https://cli.github.com/packages/rpm/gh-cli.repo"
ENV GH_CLI_REPO_NAME "gh-cli"

RUN dnf config-manager addrepo --from-repofile=${GH_CLI} \
  && dnf config-manager setopt ${GH_CLI_REPO_NAME}.enabled=0 \
  && dnf install --assumeyes --from-repo=${GH_CLI_REPO} gh \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Create podman cmd
RUN echo -e '#!/bin/sh\nexec ${CONTAINER_SUBSYS} $@' > /usr/bin/podman \
  && chmod +x /usr/bin/podman

