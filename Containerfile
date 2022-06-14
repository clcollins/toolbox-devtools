# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the 
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:36
MAINTAINER "Chris Collins <collins.christopher@gmail.com>"

ENV CONTAINER_SUBSYS "flatpak-spawn --host podman"
ENV PKGS "make gcc bison binutils jq"
ENV LANGUAGE_PKGS "python3 python3-pip golang"

RUN dnf install --assumeyes 'dnf-command(config-manager)' \
  && dnf install --assumeyes $PKGS $PYTHON_PKGS \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install Google Cloud CLI
ENV GCLOUD_CLI "https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64"
ENV GCLOUD_KEYS "https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg"
RUN dnf config-manager --add-repo ${GCLOUD_CLI} \
  && rpm --import $GCLOUD_KEYS \
  && dnf install --assumeyes libxcrypt-compat.x86_64 \
  && dnf install --assumeyes google-cloud-cli \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Install gh cli
ENV GH_CLI "https://cli.github.com/packages/rpm/gh-cli.repo"
RUN dnf config-manager --add-repo ${GH_CLI} \
  && dnf install --assumeyes gh \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Create podman cmd
RUN echo -e '#!/bin/sh\nexec ${CONTAINER_SUBSYS} $@' > /usr/bin/podman \
  && chmod +x /usr/bin/podman
