/*
Copyright © 2026 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"context"
	"fmt"

	//"log"
	"os"
	"time"

	"github.com/spf13/cobra"
	telebot "gopkg.in/telebot.v4"

	"github.com/hirosassa/zerodriver"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/codes"
	"go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
	"go.opentelemetry.io/otel/metric"
	sdkmetric "go.opentelemetry.io/otel/sdk/metric"
	"go.opentelemetry.io/otel/sdk/resource"
	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"

	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
	"go.opentelemetry.io/otel/propagation"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	"go.opentelemetry.io/otel/trace"
)

// Declare Telegram bot API Token
var (
	// Telegram bot token
	TeleToken = os.Getenv("TELE_TOKEN")
	// MetricsHost exporter host:port
	MetricsHost = os.Getenv("METRICS_HOST")
	// Meter
	meter      = otel.Meter("kbot")
	cmdCounter metric.Int64Counter
	// Logger
	logger *zerodriver.Logger
	tracer = otel.Tracer("kbot")
)

// Initialize OpenTelemetry
func initMetrics(ctx context.Context) {
	exporter, _ := otlpmetricgrpc.New(
		ctx,
		otlpmetricgrpc.WithEndpoint(MetricsHost),
		otlpmetricgrpc.WithInsecure(),
	)

	res := resource.NewWithAttributes(
		semconv.SchemaURL,
		semconv.ServiceNameKey.String(fmt.Sprintf("kbot_%s", appVersion)),
	)

	mp := sdkmetric.NewMeterProvider(
		sdkmetric.WithResource(res),
		sdkmetric.WithReader(
			sdkmetric.NewPeriodicReader(exporter, sdkmetric.WithInterval(10*time.Second)),
		),
	)

	otel.SetMeterProvider(mp)

	// create instrument
	meter = otel.Meter("kbot")

	cmdCounter, _ = meter.Int64Counter(
		"kbot_commands_total",
	)
}

// Metric helper
func recordCommand(ctx context.Context, command string) {
	cmdCounter.Add(ctx, 1,
		metric.WithAttributes(
			attribute.String("command", command),
		),
	)
}

// Wrap handler
func withMetrics(command string, next telebot.HandlerFunc) telebot.HandlerFunc {
	return func(c telebot.Context) error {

		ctx := context.Background()

		recordCommand(ctx, command)

		return next(c)
	}
}

// Init Traces

func initTracer(ctx context.Context) func(context.Context) error {

	exporter, err := otlptracegrpc.New(
		ctx,
		otlptracegrpc.WithEndpoint(MetricsHost),
		otlptracegrpc.WithInsecure(),
	)
	if err != nil {
		panic(err)
	}

	tp := sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exporter),
		sdktrace.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String("kbot"),
		)),
	)

	otel.SetTracerProvider(tp)

	// propagation across services (important later)
	otel.SetTextMapPropagator(
		propagation.NewCompositeTextMapPropagator(
			propagation.TraceContext{},
			propagation.Baggage{},
		),
	)

	return tp.Shutdown
}

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
		fmt.Printf("Starting kbot %s ... \n", appVersion)
		// Init logger, metrics, traces
		logger = zerodriver.NewProductionLogger()
		ctx := context.Background()
		initMetrics(ctx)
		shutdownTracer := initTracer(context.Background())
		defer shutdownTracer(context.Background())
		// Initialize bot
		kbot, err := telebot.NewBot(telebot.Settings{
			Token:  TeleToken,
			Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
		})
		if err != nil {
			// log.Fatalf("Please check TELE_TOKEN env variable. %s", err)
			logger.Fatal().Str("Error", err.Error()).Msg("Please check TELE_TOKEN env variable")
			return
		} else {
			logger.Info().Str("Version", appVersion).Msg("kbot started")
		}

		// Command Handlers
		kbot.Handle("/hello",
			withTracing("hello",
				withMetrics("hello",
					withLogging(func(c telebot.Context) error {
						return c.Send("Hello!")
					}),
				),
			),
		)

		kbot.Handle("/version", withMetrics("version", withLogging(func(c telebot.Context) error {
			return c.Send(fmt.Sprintf("Version: %s", appVersion))
		})))

		kbot.Handle("/date", withMetrics("date", withLogging(func(c telebot.Context) error {
			return c.Send(time.Now().Format("2006-01-02 15:04:05"))
		})))

		kbot.Handle("/help", withMetrics("help", withLogging(func(c telebot.Context) error {
			return c.Send("Available commands:\n/help\n/hello\n/version\n/date")
		})))

		// Log everything beyond recognized commands
		kbot.Handle(telebot.OnText, func(c telebot.Context) error {
			if c.Message() != nil {
				text := c.Message().Text

				// naive detection
				if len(text) > 0 && text[0] == '/' {
					recordCommand(context.Background(), "other_command")
				}
			}
			return nil
		})

		// Start bot
		kbot.Start()
	},
}

// Log Wrapper
func withLogging(next telebot.HandlerFunc) telebot.HandlerFunc {
	return func(c telebot.Context) error {

		ctxVal := c.Get("ctx")

		ctx, ok := ctxVal.(context.Context)
		if !ok {
			ctx = context.Background()
		}

		span := trace.SpanFromContext(ctx)
		traceID := span.SpanContext().TraceID().String()

		if c.Message() != nil && logger != nil {
			logger.Info().
				Str("trace_id", traceID).
				Str("command", c.Message().Text).
				Int64("chat_id", c.Chat().ID).
				Msg("command received")
		}

		return next(c)
	}
}

// Trace Wrapper
func withTracing(command string, next telebot.HandlerFunc) telebot.HandlerFunc {
	return func(c telebot.Context) error {

		ctx, span := tracer.Start(
			context.Background(),
			"telegram.command."+command,
		)
		defer span.End()

		span.SetAttributes(
			attribute.String("command", command),
			attribute.Int64("chat_id", c.Chat().ID),
		)

		// store ctx explicitly
		c.Set("ctx", ctx)

		err := next(c)

		if err != nil {
			span.RecordError(err)
			span.SetStatus(codes.Error, err.Error())
		} else {
			span.SetStatus(codes.Ok, "ok")
		}

		return err
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
