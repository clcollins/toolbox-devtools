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

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build ${CACHE} ${IMAGE_PULL_POLICY} ${BUILD_ARGS} -t ${TAG} .

.PHONY: test
test: TAG=toolbox-${IMAGE_NAME}:test
test: CACHE=--no-cache
test: IMAGE_PULL_POLICY=--pull=always
test: BUILD_ARGS=--build-arg=GIT_HASH=TEST
test: build

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
	@echo "  all                - Run isclean, build, tag, and push (default)"
	@echo "  build              - Build the devtools image"
	@echo "  test               - Build and test the image with no cache"
	@echo "  tag                - Tag the built image"
	@echo "  push               - Push images to registry"
	@echo "  isclean            - Check if git working directory is clean"
	@echo "  cleanup-test       - Remove test images"
	@echo "  cleanup-bootstrap  - Stop and remove bootstrap container"
