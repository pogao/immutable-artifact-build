package main

import (
	"log/slog"
	"os"

	"github.com/pogao/immutable-artifact-build/pkg/web"
)

func main() {
	handler := slog.NewJSONHandler(os.Stdout, nil)
	logger := slog.New(handler)
	slog.SetDefault(logger)

	err := web.Start()
	if err != nil {
		slog.Error("failed to start web server", err.Error())
		os.Exit(1)
	}
}
