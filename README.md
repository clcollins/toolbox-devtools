# toolbox-devtools
Developer tools image for Fedora Toolbox use

This is intended to be built into an image for use with [Fedora Toolbox](https://docs.fedoraproject.org/en-US/fedora-silverblue/toolbox/) and run with `toolbox create --image NAME`. This allows podman on the host to be used from within the toolbox via the flatpak-spawn command.

## Building

Building on a Fedora Silverblue host requires bootstrapping a dev image first, but the image itself only requires `make` and `git`.  You can do so with:

```shell
toolbox create bootstrap
toolbox enter bootstrap

# Then, within the boostrap container:
sudo dnf install -y make git
CONTAINER_SUBSYS="flatpak-spawn --host podman" make
```

This will create a "devtools" image locally on the Silverblue host.  From there, you can create a "devtools" container:

```shell
toolbox create devtools --image devtools:latest
toolbox enter devtools
```

The devtools image will contain tools and packages from the Container file and can be customized by modifying the Container file.

Subsequent builds of the container image will not automatically update the "devtools" toolbox.  
It will need to be removed and recreated from the latest image.
