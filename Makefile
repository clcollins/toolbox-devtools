IMAGE_NAME = "devtools"
GIT_HASH := $(shell git rev-parse --short HEAD)

TMPDIR := $(shell mktemp -d /tmp/ocm-container-custom.XXXXX)

CONTAINER_SUBSYS?="podman"

default: all

.PHONY: all
all: build tag

.PHONY: build
build: 
	${CONTAINER_SUBSYS} build -t ${IMAGE_NAME}:${GIT_HASH} .

.PHONY: tag
tag: 
	${CONTAINER_SUBSYS} tag ${IMAGE_NAME}:${GIT_HASH} ${IMAGE_NAME}:latest
