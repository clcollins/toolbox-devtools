IMAGE_NAME = "devtools"
GIT_TAG := $(git log -1 --abbrev-commit)

TMPDIR := $(shell mktemp -d /tmp/ocm-container-custom.XXXXX)

CONTAINER_SUBSYS?="podman"

default: all

.PHONY: all
all: build tag

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build -t ${IMAGE_NAME}:${GIT_TAG} .

.PHONY: tag
tag: 
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME}:${GIT_TAG} ${IMAGE_NAME}:latest
