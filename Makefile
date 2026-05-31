APP=$(shell basename -s .git $(shell git remote get-url origin))
REGISTRY ?= docker.io
REPO ?= opidoc
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
RMI ?= false
#TARGETOS options: linux windows darwin
TARGETOS=linux
#TARGETARCH options: amd64 arm64
TARGETARCH=amd64

# Assign target image
ifeq ($(REGISTRY),docker.io)
TARGETIMAGE := $(REPO)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)
else
TARGETIMAGE := $(REGISTRY)/$(REPO)/$(APP):$(VERSION)-$(TARGETOS)-$(TARGETARCH)
endif

print-env:
	@echo "TARGETIMAGE: $(TARGETIMAGE)"
format:
	gofmt -s -w ./
lint:
	golangci-lint run 
test:
	go test -v
get:
	go get
build: format get
	CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -v -o kbot -ldflags "-X="github.com/dmzopi/kbot/cmd.appVersion=${VERSION}
image: print-env
	docker build . -t ${TARGETIMAGE}
push:
	docker push ${TARGETIMAGE}
clean:
	rm -rf kbot
ifeq ($(RMI),true)
	-docker rmi ${TARGETIMAGE}
endif