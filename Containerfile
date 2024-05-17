# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the 
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:40
ARG GIT_HASH

LABEL toolbox-devtools-version=${GIT_HASH}
LABEL author "Chris Collins <collins.christopher@gmail.com>"

ENV EDITOR=vi

ENV   toolbox-devtools-version=${GIT_HASH}
ENV CONTAINER_SUBSYS "flatpak-spawn --host podman"
ENV PKGS "make gcc bison binutils jq flatpak httpie NetworkManager tmux gnome-keyring glab yamllint"
ENV LANGUAGE_PKGS "python3 python3-pip tinygo"

RUN  dnf update --assumeyes \
  && dnf install --assumeyes 'dnf-command(config-manager)' \
  && dnf install --assumeyes $PKGS $LANGUAGE_PKGS \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install Google Cloud CLI
ENV GCLOUD_CLI "https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64"
ENV GCLOUD_CLI_REPO_NAME "packages.cloud.google.com_yum_repos_cloud-sdk-el8-x86_64"
ENV GCLOUD_KEYS "https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"

RUN dnf config-manager --add-repo ${GCLOUD_CLI} \
  && rpm --import $GCLOUD_KEYS \
  && dnf install --assumeyes libxcrypt-compat.x86_64 \
  && dnf install --assumeyes google-cloud-cli \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/ \
  && dnf config-manager --set-disabled ${GCLOUD_CLI_REPO_NAME}

# Install gh cli
ENV GH_CLI "https://cli.github.com/packages/rpm/gh-cli.repo"
ENV GH_CLI_REPO_NAME "gh-cli"

RUN dnf config-manager --add-repo ${GH_CLI} \
  && dnf install --assumeyes gh \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/ \
  && dnf config-manager --set-disabled ${GH_CLI_REPO_NAME}

# Create podman cmd
RUN echo -e '#!/bin/sh\nexec ${CONTAINER_SUBSYS} $@' > /usr/bin/podman \
  && chmod +x /usr/bin/podman

# Add RH CA Certs
RUN curl -sSL -o /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt https://certs.corp.redhat.com/certs/2015-IT-Root-CA.pem
RUN curl -sSL -o /etc/pki/ca-trust/source/anchors/2022-IT-Root-CA.pem https://certs.corp.redhat.com/certs/2022-IT-Root-CA.pem
RUN update-ca-trust

