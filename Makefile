GOLANG_VERSION := 1.23.2
ALPINE_VERSION := 3.20

GIT_REPO := github.com/michalswi/gowsserver
DOCKER_REPO := michalsw
APPNAME := wsserver
VERSION := 0.1.0

PORT ?= 80
SERVICE_PORT ?= 8080

AZ_RG ?= wsserverrg
AZ_LOCATION ?= westeurope
AZ_DNS_LABEL ?= $(APPNAME)-$(AZ_LOCATION)

.DEFAULT_GOAL := help
.PHONY: test go-run go-build docker-build-arm docker-build-linux docker-run docker-stop azure-rg azure-rg-del azure-aci

help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ \
	{ printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

test:
	go test -v ./...

go-run: ## Run wsserver
	go run .	

go-build: ## Build binary
	CGO_ENABLED=0 \
	go build \
	-v \
	-ldflags "-s -w -X '$(GIT_REPO)/version.AppVersion=$(VERSION)'" \
	-o $(APPNAME)-$(VERSION) .

# all: test go-build

docker-build-arm: ## Build arm docker image
	docker build \
	--pull \
	--build-arg GOLANG_VERSION="$(GOLANG_VERSION)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--build-arg APPNAME="$(APPNAME)" \
	--build-arg VERSION="$(VERSION)" \
	--label="build.version=$(VERSION)" \
	--tag="$(DOCKER_REPO)/$(APPNAME):latest" \
	.

docker-build-linux: ## Build linux docker image
	docker build \
	--pull \
	--build-arg GOLANG_VERSION="$(GOLANG_VERSION)" \
	--build-arg ALPINE_VERSION="$(ALPINE_VERSION)" \
	--build-arg APPNAME="$(APPNAME)" \
	--build-arg VERSION="$(VERSION)" \
	--label="build.version=$(VERSION)" \
	--platform linux/amd64 \
	--tag="$(DOCKER_REPO)/$(APPNAME):latest" \
	.

docker-run: ## Run docker image with default parameters (or overwrite)
	docker run -d --rm \
	--name $(APPNAME) \
	-p $(SERVICE_PORT):$(PORT) \
	$(DOCKER_REPO)/$(APPNAME):latest

docker-stop: ## Stop running docker
	docker stop $(APPNAME)

azure-rg: ## Create the Azure Resource Group
	az group create --name $(AZ_RG) --location $(AZ_LOCATION)

azure-rg-del: ## Delete the Azure Resource Group
	az group delete --name $(AZ_RG)

azure-aci: ## Run wsserver app (Azure Container Instance)
	az container create \
	--resource-group $(AZ_RG) \
	--name $(APPNAME) \
	--image $(DOCKER_REPO)/$(APPNAME):latest \
	--restart-policy Always \
	--ports $(PORT) \
	--dns-name-label $(AZ_DNS_LABEL) \
	--location $(AZ_LOCATION) \
	--verbose

azure-aci-fqdn: ## Get wsserver fqdn
	az container list \
	--resource-group $(AZ_RG) \
	--query "[].ipAddress.fqdn" -o tsv

azure-aci-logs: ## Get wsserver app logs (Azure Container Instance)
	az container logs \
	--resource-group $(AZ_RG) \
	--name $(APPNAME) \
	--follow
