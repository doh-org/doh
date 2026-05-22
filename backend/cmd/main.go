package main

import (
	"context"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"

	"doh/backend/internal/auth"
	"doh/backend/internal/config"
	"doh/backend/internal/middleware"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("config load failed", "err", err)
		os.Exit(1)
	}

	jwksURL := cfg.SupabaseURL + "/auth/v1/.well-known/jwks.json"
	keys, err := middleware.FetchPublicKeys(context.Background(), jwksURL)
	if err != nil {
		slog.Error("jwks fetch failed", "err", err)
		os.Exit(1)
	}
	slog.Info("jwks loaded", "key_count", len(keys))

	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	svc := auth.NewService(cfg.SupabaseURL, cfg.SupabaseAnonKey, cfg.TurnstileSecretKey)
	h := auth.NewHandler(svc)

	router := gin.New()
	router.Use(gin.Recovery())

	v1 := router.Group("/api/v1")
	{
		authGroup := v1.Group("/auth")

		public := authGroup.Group("")
		public.Use(middleware.RateLimit())
		public.POST("/signup", h.Signup)
		public.POST("/login", h.Login)

		protected := authGroup.Group("")
		protected.Use(middleware.Auth(keys, cfg.SupabaseURL, cfg.SupabaseAnonKey, nil))
		protected.POST("/logout", h.Logout)
		protected.GET("/me", h.Me)
	}

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           router,
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       10 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	slog.Info("server starting", "port", cfg.Port, "env", cfg.Env)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		slog.Error("server error", "err", err)
		os.Exit(1)
	}
}
