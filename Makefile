# https://github.com/dmzopi/kbot.git -> kbot
APP=$(shell basename -s .git $(shell git remote get-url origin))
REGISTRY=opidoc
# Version: v1.0.3-41a00aa
VERSION=$(shell git describe --tags --abbrev=0)-$(shell git rev-parse --short HEAD)
TARGETOS=darwin #linux windows
TARGETARCH=arm64 #amd64

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
image:
	docker build . -t ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}
push:
	docker push ${REGISTRY}/${APP}:${VERSION}-${TARGETARCH}

clean:
	rm -rf kbot