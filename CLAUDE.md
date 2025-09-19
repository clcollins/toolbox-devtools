# Claude Configuration for toolbox-devtools

<!-- cSpell:ignore Containerfile SUBSYS isclean clcollins -->

This repository contains a Containerfile and build scripts for creating a Fedora Toolbox development environment image.

## Project Context

- **Purpose**: Developer tools image for Fedora Toolbox use
- **Main Files**:
  - `Containerfile`: Defines the development environment with tools like make, gcc, jq, npm, gcloud CLI, vault, gh CLI, etc.
  - `Makefile`: Build automation with podman/flatpak-spawn integration
  - `bootstrap.sh`: Bootstrap script for initial setup
  - `replace-container.sh`: Container replacement utilities

## Build Commands

- **Build image**: `make build` or `CONTAINER_SUBSYS="flatpak-spawn --host podman" make`
- **Full build process**: `make all` (includes isclean, build, tag, push)
- **Clean check**: `make isclean` (ensures git repo is clean)
- **Tag images**: `make tag`
- **Push to registry**: `make push`

## Development Workflow

1. Create bootstrap toolbox: `toolbox create bootstrap`
2. Install build dependencies: `sudo dnf install -y make git`
3. Build the devtools image using make
4. Create devtools container: `toolbox create devtools --image devtools:latest`

## Container Tools

- Uses `flatpak-spawn --host podman` to access host podman from within toolbox
- Installs development tools: Python, Node.js, Go, gcloud CLI, Vault, GitHub CLI
- Includes linting tools: ShellCheck, yamllint, markdownlint

## Testing/Validation

- Ensure git repo is clean before building (`make isclean`)
- Test container creation and tool accessibility after build
- **REQUIRED**: Before committing changes, run `make test` to validate all changes
- **NOTE**: Tests may take 10+ minutes due to extensive package installation and require extended timeout

## Git Workflow

When making changes to this repository:

1. Test and validate changes using `make test`
2. **ALWAYS** ask for explicit permission before committing changes to git
3. If tests pass and commit is explicitly requested:
   - Add changed files to git
   - Create commit message with descriptive body that accurately describes what is included in the commit
   - Include note that code changes, commit message, and commit were created by Claude and signed-off by @clcollins
   - Use `-s` and `-S` flags for signed commits: `git commit -s -S -m "message"`
4. After committing, offer to create pull request using `gh pr create`
5. After PR creation, offer to build and publish full image using `make`

**IMPORTANT**: Never offer to always allow commits without prompting. Always request permission for each commit operation.
