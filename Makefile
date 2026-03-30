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

.PHONY: default
default: all

.PHONY: all
all: isclean build tag push

.PHONY: isclean
isclean:
	@(test "$(ALLOW_DIRTY_CHECKOUT)" != "false" || test 0 -eq $$(git status --porcelain | wc -l)) || (echo "Local git checkout is not clean, commit changes and try again." >&2 && git --no-pager diff && exit 1)

.PHONY: validate-fedora-version
validate-fedora-version:
	@./scripts/validate-fedora-version.sh

.PHONY: validate
validate: validate-fedora-version

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build ${CACHE} ${IMAGE_PULL_POLICY} ${BUILD_ARGS} -t ${TAG} .

.PHONY: test
test: validate
	$(CONTAINER_SUBSYS) build --no-cache --pull=always --build-arg=GIT_HASH=TEST -t toolbox-$(IMAGE_NAME):test .

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

.PHONY: clean
clean: cleanup-test cleanup-bootstrap

.PHONY: help
help:
	@echo "Targets: all build test tag push isclean validate clean help"
	@echo "  all       - isclean, build, tag, push (default)"
	@echo "  build     - Build the devtools image"
	@echo "  test      - Validate and build image (no cache)"
	@echo "  clean     - Remove test images and bootstrap container"
