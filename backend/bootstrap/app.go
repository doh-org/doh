package bootstrap

import (
	"context"
	"crypto/ecdsa"
	"log/slog"
	"os"

	"doh/backend/api/middleware"
)

type Application struct {
	Env        *Env
	PublicKeys map[string]*ecdsa.PublicKey
}

func App() Application {
	env, err := NewEnv()
	if err != nil {
		slog.Error("config load failed", "err", err)
		os.Exit(1)
	}

	jwksURL := env.SupabaseURL + "/auth/v1/.well-known/jwks.json"
	keys, err := middleware.FetchPublicKeys(context.Background(), jwksURL)
	if err != nil {
		slog.Error("jwks fetch failed", "err", err)
		os.Exit(1)
	}
	slog.Info("jwks loaded", "key_count", len(keys))

	return Application{Env: env, PublicKeys: keys}
}
