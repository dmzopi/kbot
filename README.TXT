1. Module initialization (name is arbitrary)
go mod init github.com/dmzopi/kbot

2. Install and import CLI code generator cobra: https://github.com/spf13/cobra
go install github.com/spf13/cobra-cli@latest
If not already done, export binary path:
export PATH=$PATH:$(go env GOPATH)/bin

3. Generate inital project code
cobra-cli init

4. Try to generate example code
cobra-cli add version
Initialize variable "var appVersion" and substitute Println statement instead of string

5. Test build and run code
go run main.go help
go run main.go version

6. Generate main function
cobra-cli add kbot

7. Generate exe file
Using -ldflags "-X=" : function to change values of imported pakages during build just from cli 
go build -ldflags "-X="github.com/dmzopi/kbot/cmd.appVersion=v.1.0.0

8. Test
./kbot version