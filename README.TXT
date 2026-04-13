1. Module initialization (name is arbitrary)
go mod init github.com/dmzopi/kbot

2. Install and import CLI code generator cobra: https://github.com/spf13/cobra
go install github.com/spf13/cobra-cli@latest
If not already done, export binary path:
export PATH=$PATH:$(go env GOPATH)/bin

3. Generate inital project code
cobra-cli init

4. Try to generate example code
obra-cli add version

