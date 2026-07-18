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
	NaverSearchClientID    string // 검색 오픈API (developers.naver.com)
	NaverSearchSecret      string
	NcpMapClientID         string // NCP API Gateway (역지오코딩)
	NcpMapSecret           string
	KakaoRestAPIKey        string // 카카오 로컬 API
}

func NewEnv() (*Env, error) {
	_ = godotenv.Load()

	env := &Env{
		Env:                    getEnv("ENV", "development"),
		Port:                   getEnv("PORT", "8080"),
		SupabaseURL:            os.Getenv("SUPABASE_URL"),
		SupabaseAnonKey:        os.Getenv("SUPABASE_ANON_KEY"),
		SupabaseServiceRoleKey: os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
		NaverSearchClientID:    os.Getenv("NAVER_SEARCH_CLIENT_ID"),
		NaverSearchSecret:      os.Getenv("NAVER_SEARCH_CLIENT_SECRET"),
		NcpMapClientID:         os.Getenv("NAVER_MAP_CLIENT_ID"),
		NcpMapSecret:           os.Getenv("NAVER_MAP_CLIENT_SECRET"),
		KakaoRestAPIKey:        os.Getenv("KAKAO_REST_API_KEY"),
	}

	if env.SupabaseURL == "" {
		return nil, fmt.Errorf("SUPABASE_URL is required")
	}
	if env.SupabaseServiceRoleKey == "" {
		return nil, fmt.Errorf("SUPABASE_SERVICE_ROLE_KEY is required")
	}
	if env.NaverSearchClientID == "" || env.NaverSearchSecret == "" {
		return nil, fmt.Errorf("NAVER_SEARCH_CLIENT_ID/SECRET is required")
	}
	if env.NcpMapClientID == "" || env.NcpMapSecret == "" {
		return nil, fmt.Errorf("NAVER_MAP_CLIENT_ID/SECRET is required")
	}
	if env.KakaoRestAPIKey == "" {
		return nil, fmt.Errorf("KAKAO_REST_API_KEY is required")
	}

	return env, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
