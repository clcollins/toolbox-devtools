REGISTRY_NAME := quay.io
ORG_NAME := chcollin
AUTHFILE := ${HOME}/.config/quay.io/bot_auth.json

IMAGE_NAME := devtools
GIT_HASH := $(shell git rev-parse --short HEAD)

TAG := ${REGISTRY_NAME}/${ORG_NAME}/toolbox-${IMAGE_NAME}:${GIT_HASH}
TAG_LATEST := ${REGISTRY_NAME}/${ORG_NAME}/toolbox-${IMAGE_NAME}:latest

CONTAINER_SUBSYS ?= podman

BUILD_ARGS ?= --build-arg=GIT_HASH=${GIT_HASH}
CACHE ?=
IMAGE_PULL_POLICY ?= --pull=always

ALLOW_DIRTY_CHECKOUT ?= false

default: all

.PHONY: all
all: isclean build tag push

.PHONY: isclean
isclean:
	@(test "$(ALLOW_DIRTY_CHECKOUT)" != "false" || test 0 -eq $$(git status --porcelain | wc -l)) || (echo "Local git checkout is not clean, commit changes and try again." >&2 && git --no-pager diff && exit 1)

.PHONY: validate-fedora-version
validate-fedora-version:
	@echo "Validating Fedora version consistency..."
	@CONTAINERFILE_VERSION=$$(grep -E '^FROM registry.fedoraproject.org/fedora-toolbox:' Containerfile | sed -E 's/.*:([0-9]+).*/\1/'); \
	CI_VERSION=$$(grep -E 'image: fedora:' .github/workflows/test.yml | sed -E 's/.*fedora:([0-9]+).*/\1/'); \
	echo "  Containerfile: Fedora $$CONTAINERFILE_VERSION"; \
	echo "  CI workflow:   Fedora $$CI_VERSION"; \
	if [ "$$CONTAINERFILE_VERSION" != "$$CI_VERSION" ]; then \
		echo "Error: Fedora version mismatch between Containerfile and CI workflow!" >&2; \
		exit 1; \
	fi; \
	echo "✓ Fedora versions match ($$CONTAINERFILE_VERSION)"

.PHONY: validate
validate: validate-fedora-version

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build ${CACHE} ${IMAGE_PULL_POLICY} ${BUILD_ARGS} -t ${TAG} .

.PHONY: test
test: TAG=toolbox-${IMAGE_NAME}:test
test: CACHE=--no-cache
test: IMAGE_PULL_POLICY=--pull=always
test: BUILD_ARGS=--build-arg=GIT_HASH=TEST
test: validate build

.PHONY: tag
tag: 
	${CONTAINER_SUBSYS} tag ${TAG} ${TAG_LATEST}
	${CONTAINER_SUBSYS} tag ${TAG} ${IMAGE_NAME}:latest

.PHONY: push
push:
	${CONTAINER_SUBSYS} push ${TAG} --authfile=${AUTHFILE}
	${CONTAINER_SUBSYS} push ${TAG_LATEST} --authfile=${AUTHFILE}

.PHONY: cleanup-bootstrap
cleanup-bootstrap:
	${CONTAINER_SUBSYS} stop bootstrap
	${CONTAINER_SUBSYS} rm bootstrap

.PHONY: cleanup-test
cleanup-test:
	${CONTAINER_SUBSYS} rmi -f toolbox-${IMAGE_NAME}:test 2>/dev/null || true

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all                      - Run isclean, build, tag, and push (default)"
	@echo "  build                    - Build the devtools image"
	@echo "  test                     - Run validations and build/test image with no cache"
	@echo "  tag                      - Tag the built image"
	@echo "  push                     - Push images to registry"
	@echo "  isclean                  - Check if git working directory is clean"
	@echo "  validate                 - Run all validation checks"
	@echo "  validate-fedora-version  - Validate Containerfile and CI use same Fedora version"
	@echo "  cleanup-test             - Remove test images"
	@echo "  cleanup-bootstrap        - Stop and remove bootstrap container"
