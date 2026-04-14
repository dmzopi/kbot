# kbot

A Telegram bot for Golang learning purposes 

## Features

- Basic message handler

## Prerequisites

- Go 1.26.1 or later
- Telegram Bot Token (set as TELE_TOKEN environment variable)
- Required Go packages:
  - github.com/spf13/cobra
  - gopkg.in/telebot.v4

## Installation

1. Clone the repository:
```bash
git clone https://github.com/dmzopi/kbot.git
cd kbot
```

2. Set up your Telegram Bot Token:
```bash
read -s TELE_TOKEN
export TELE_TOKEN="your_telegram_bot_token"
```

## Usage

Start the bot:
```bash
./kbot start
```
### Bot URL
[t.me/dmzopi_bot](https://t.me/dmzopi_bot)

### Available Commands

- `/help` - Show available commands

## Development

The project uses Cobra for CLI command management

### Project Structure

- `cmd/` - Contains the main command implementations
  - `kbot.go` - Main bot implementation and traffic light control
  - `root.go` - Root command configuration
  - `version.go` - Version command implementation