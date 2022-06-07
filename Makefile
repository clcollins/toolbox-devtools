IMAGE_NAME = "devtools"
GIT_HASH := $(shell git rev-parse --short HEAD)

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
