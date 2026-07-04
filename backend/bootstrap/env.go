package bootstrap

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
)

type Env struct {
	Env                    string
	Port                   string
	SupabaseURL            string
	SupabaseAnonKey        string
	SupabaseServiceRoleKey string
	TurnstileSecretKey     string
}

func NewEnv() (*Env, error) {
	_ = godotenv.Load()

	env := &Env{
		Env:                    getEnv("ENV", "development"),
		Port:                   getEnv("PORT", "8080"),
		SupabaseURL:            os.Getenv("SUPABASE_URL"),
		SupabaseAnonKey:        os.Getenv("SUPABASE_ANON_KEY"),
		SupabaseServiceRoleKey: os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
		TurnstileSecretKey:     os.Getenv("TURNSTILE_SECRET_KEY"),
	}

	if env.SupabaseURL == "" {
		return nil, fmt.Errorf("SUPABASE_URL is required")
	}
	if env.SupabaseServiceRoleKey == "" {
		return nil, fmt.Errorf("SUPABASE_SERVICE_ROLE_KEY is required")
	}
	if env.TurnstileSecretKey == "" {
		return nil, fmt.Errorf("TURNSTILE_SECRET_KEY is required")
	}

	return env, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
