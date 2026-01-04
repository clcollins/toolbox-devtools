# toolbox-devtools

Developer tools image for Fedora Toolbox use

This is intended to be built into an image for use with [Fedora Toolbox](https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/) and run with `toolbox create --image NAME`. This allows podman on the host to be used from within the toolbox via the flatpak-spawn command.

## Features

The devtools image includes:
- Build tools: make, gcc, bison, binutils
- Container tools: podman (via host), skopeo, flatpak
- Development languages: Python 3, Node.js, TinyGo
- Cloud CLIs: Google Cloud CLI, HashiCorp Vault, GitHub CLI (gh), GitLab CLI (glab)
- Utilities: jq, yq, httpie, tmux
- Linting tools: ShellCheck, yamllint, markdownlint, tox
- Claude Code CLI

## Building

### Quick Start (Automated Bootstrap)

On a Fedora Silverblue host, the easiest way to get started is:

```shell
toolbox create bootstrap
toolbox enter bootstrap
./bootstrap.sh
```

This script will:
1. Install build dependencies (make and git)
2. Build the devtools image
3. Create a devtools toolbox container
4. Provide instructions for next steps

### Manual Build

Building on a Fedora Silverblue host requires bootstrapping a dev image first:

```shell
toolbox create bootstrap
toolbox enter bootstrap

# Install build dependencies
sudo dnf install -y make git

# Build the image
CONTAINER_SUBSYS="flatpak-spawn --host podman" make build
```

This will create a "devtools" image locally on the Silverblue host. From there, you can create a "devtools" container:

```shell
toolbox create devtools --image localhost/devtools:latest
toolbox enter devtools
```

### Build on Standard Fedora

If you're on a standard Fedora installation (not Silverblue):

```shell
make build
toolbox create devtools --image localhost/devtools:latest
```

## Customization

The devtools image can be customized by modifying the `Containerfile`:

1. Edit package lists in the `PKGS`, `LANGUAGE_PKGS`, or `NPM_PKGS` environment variables
2. Add new external repositories in the repository sections
3. Rebuild the image with `make build`

## Updating

Subsequent builds of the container image will not automatically update an existing "devtools" toolbox container. To use a newly built image:

### Option 1: Use the replace script

```shell
./replace-container.sh
```

This script will stop and remove the existing devtools container, then create a new one from the latest built image.

### Option 2: Manual update

```shell
podman stop devtools
toolbox rm devtools
toolbox create devtools --image localhost/devtools:latest
```

## Available Make Targets

Run `make help` to see all available targets:

- `make build` - Build the devtools image (default uses caching)
- `make test` - Build and validate the image with no cache
- `make all` - Run isclean, build, tag, and push
- `make cleanup-test` - Remove test images
- `make cleanup-bootstrap` - Stop and remove bootstrap container

## Troubleshooting

### podman command not found inside toolbox

Ensure you're using the devtools image that includes the podman wrapper script. The wrapper uses `flatpak-spawn` to access the host's podman.

### Image build is slow

By default, builds use layer caching for faster iteration. The base image is always pulled (`--pull=always`) to ensure up-to-date packages. To disable base image pulls during development:

```shell
IMAGE_PULL_POLICY= make build
```

### Can't access host podman from inside toolbox

Ensure you have `flatpak-spawn` available and the toolbox was created from the devtools image. The podman wrapper relies on the `CONTAINER_SUBSYS` environment variable being set correctly.

### Bootstrap toolbox still running

Remove it with:

```shell
make cleanup-bootstrap
```

Or manually:

```shell
podman stop bootstrap
toolbox rm bootstrap
```
