# Telegram Bot (kbot)

## 🧩 Code

### Initialize Project
```bash
go mod init github.com/dmzopi/kbot
```
### Install Cobra CLI
```bash
go install github.com/spf13/cobra-cli@latest
export PATH=$PATH:$(go env GOPATH)/bin
```
### Generate Initial Project
```bash
cobra-cli init
```
### Add `version` Command
```bash
cobra-cli add version
```
Update `version.go`:
```go
var appVersion string
```
* Replace hardcoded version string with `appVersion`
### Test Run
```bash
go run main.go help
go run main.go version
```
### Add Main Command
```bash
cobra-cli add kbot
```

## 🤖 Telegram Bot Logic (Telebot)

* Initialize bot with token from environment
* Configure poller
* Handle fatal error (missing/invalid token)
* Implement `OnText` handler
* Start bot
* Add alias:

```go
Aliases: []string{"start"},
```
### Format Code
```bash
gofmt -s -w ./
```
### Install Dependencies

```bash
go get ./...
```
### Secure Token Setup
```bash
read -s TELE_TOKEN
export TELE_TOKEN
```

---

## 🏗️ Build

### Build Binary (with version injection)
```bash
go build -ldflags "-X=github.com/dmzopi/kbot/cmd.appVersion=v1.0.3" -o bin/
```

### Test Binary
```bash
bin/kbot version
```

## 📦 Containerization
> Ensure platform/architecture is set in `Makefile`.
```bash
make build     # Build binary
make image     # Build container image
make push      # Push image to repository
```


---

## ☸️ Release

### Create Helm Chart

```bash
helm create ./helm
helm lint ./helm/
helm template kbot ./helm/
helm package ./helm
```

### 🚀 Release (GitHub)

```bash
gh release create
gh release list
gh release upload kbot kbot-0.0.1.tgz
```

---

## 🚢 Deploy

### Install Helm Chart from Release

```bash
helm install kbot https://github.com/dmzopi/kbot/releases/download/v1.0.3-helm/kbot-0.0.1.tgz
```
