package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"

	"doh/backend/api/middleware"
	"doh/backend/api/route"
	"doh/backend/bootstrap"
)

func main() {
	app := bootstrap.App()
	env := app.Env

	jwksURL := env.SupabaseURL + "/auth/v1/.well-known/jwks.json"
	keys, err := middleware.FetchPublicKeys(context.Background(), jwksURL)
	if err != nil {
		slog.Error("jwks fetch failed", "err", err)
		os.Exit(1)
	}
	slog.Info("jwks loaded", "key_count", len(keys))

	if env.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(gin.Recovery())

	route.Setup(env, keys, r)

	srv := &http.Server{
		Addr:              ":" + env.Port,
		Handler:           r,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	slog.Info("server starting", "port", env.Port, "env", env.Env)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		slog.Error("server error", "err", err)
		os.Exit(1)
	}
}
