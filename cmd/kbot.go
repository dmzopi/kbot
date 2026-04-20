/*
Copyright © 2026 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"
	"log"
	"os"
	"time"

	"github.com/spf13/cobra"
	telebot "gopkg.in/telebot.v4"
)

// Declare Telegram bot API Token
var (
	TeleToken = os.Getenv("TELE_TOKEN")
)

// kbotCmd represents the kbot command
var kbotCmd = &cobra.Command{
	Use:     "kbot",
	Aliases: []string{"start"},
	Short:   "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("kbot %s started\n", appVersion)

		// Initialize bot
		kbot, err := telebot.NewBot(telebot.Settings{
			Token:  TeleToken,
			Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
		})
		if err != nil {
			log.Fatalf("Please check TELE_TOKEN env variable. %s", err)
		}

		// Command Handlers
		kbot.Handle("/hello", withLogging(func(c telebot.Context) error {
			return c.Send("Hello There! I'm Kbot, I'm written in Go")
		}))

		kbot.Handle("/version", withLogging(func(c telebot.Context) error {
			return c.Send(fmt.Sprintf("Version: %s", appVersion))
		}))

		kbot.Handle("/date", withLogging(func(c telebot.Context) error {
			return c.Send(time.Now().Format("2006-01-02 15:04:05"))
		}))

		kbot.Handle("/help", withLogging(func(c telebot.Context) error {
			return c.Send("Available commands:\n/help\n/hello\n/version\n/date")
		}))

		// Log everything beyond recognized commands
		kbot.Handle(telebot.OnText, func(c telebot.Context) error {
			if c.Message() != nil {
				log.Printf("Message received: %s", c.Message().Text)
			}
			return err
		})

		// Start bot
		kbot.Start()
	},
}

// Command Log Wrapper
func withLogging(next telebot.HandlerFunc) telebot.HandlerFunc {
	return func(c telebot.Context) error {
		if c.Message() != nil {
			log.Printf("Command received: %s", c.Message().Text)
		}
		return next(c)
	}
}

func init() {
	rootCmd.AddCommand(kbotCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// kbotCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// kbotCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
