# This is intended to be built into an image for use with Fedora Toolbox
# and run with `toolbox create --image NAME`. This allows podman on the 
# host to be used from within the toolbox via the flatpak-spawn command.

FROM registry.fedoraproject.org/fedora-toolbox:36
MAINTAINER "Chris Collins <collins.christopher@gmail.com>"

ENV CONTAINER_SUBSYS "flatpak-spawn --host podman"
ENV PKGS "make gh"
ENV PYTHON_PKGS "python3 python3-pip"
ENV GH_CLI "https://cli.github.com/packages/rpm/gh-cli.repo"

RUN dnf install 'dnf-command(config-manager)' \
  && dnf config-manager --add-repo $GH_CLI \
  && dnf install --assumeyes $PKGS $PYTHON_PKGS \
  && dnf clean all \
  && rm --recursive --force /var/cache/yum/

# Validate gh install
RUN gh --version
