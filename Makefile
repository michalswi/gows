GOLANG_VERSION := 1.15.6
ALPINE_VERSION := 3.13

GIT_REPO := github.com/michalswi/gowsserver
DOCKER_REPO := michalsw
APPNAME := wsserver

VERSION ?= $(shell git describe --tags --always)
BUILD_TIME ?= $(shell date -u '+%Y-%m-%d %H:%M:%S')
LAST_COMMIT_USER ?= $(shell git log -1 --format='%cn <%ce>')
LAST_COMMIT_HASH ?= $(shell git log -1 --format=%H)
LAST_COMMIT_TIME ?= $(shell git log -1 --format=%cd --date=format:'%Y-%m-%d %H:%M:%S')

SERVICE_PORT ?= 8080

.DEFAULT_GOAL := help
.PHONY: test go-run go-build all docker-build docker-run docker-stop

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

test:
	go test -v ./...

go-run: 		## Run wsserver
	go run .	

go-build: 		## Build binary
	$(info -build wsserver binary-)
	CGO_ENABLED=0 \
	go build \
	-v \
	-ldflags "-s -w -X '$(GIT_REPO)/version.AppVersion=$(VERSION)' \
	-X '$(GIT_REPO)/version.BuildTime=$(BUILD_TIME)' \
	-X '$(GIT_REPO)/version.LastCommitUser=$(LAST_COMMIT_USER)' \
	-X '$(GIT_REPO)/version.LastCommitHash=$(LAST_COMMIT_HASH)' \
	-X '$(GIT_REPO)/version.LastCommitTime=$(LAST_COMMIT_TIME)'" \
	-o $(APPNAME)-$(VERSION) .

all: test go-build

docker-build:	## Build docker image
	$(info -build wsserver docker image-)
	docker build \
	--pull \
	--build-arg GOLANG_VERSION="$(GOLANG_VERSION)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--build-arg APPNAME="$(APPNAME)" \
	--build-arg VERSION="$(VERSION)" \
	--build-arg BUILD_TIME="$(BUILD_TIME)" \
	--build-arg LAST_COMMIT_USER="$(LAST_COMMIT_USER)" \
	--build-arg LAST_COMMIT_HASH="$(LAST_COMMIT_HASH)" \
	--build-arg LAST_COMMIT_TIME="$(LAST_COMMIT_TIME)" \
	--label="build.version=$(VERSION)" \
	--tag="$(DOCKER_REPO)/$(APPNAME):latest" \
	.

docker-run:		## Run docker image with default parameters (or overwrite)
	$(info -run wsserver in docker-)
	docker run -d --rm \
	--name $(APPNAME) \
	-p $(SERVICE_PORT):$(SERVICE_PORT) \
	$(DOCKER_REPO)/$(APPNAME):latest

docker-stop:	## Stop running docker
	$(info -stop wsserver in docker-)
	docker stop $(APPNAME)
