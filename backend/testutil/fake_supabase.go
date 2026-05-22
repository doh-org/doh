package testutil

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// FakeSupabase는 Supabase Auth + PostgREST 엔드포인트를 시뮬레이션한다.
type FakeSupabase struct {
	Server       *httptest.Server
	SignupError  string // "user_already_exists" 등 error_code; 빈 문자열이면 성공
	LoginError   bool
	SessionValid bool   // GET /auth/v1/user 응답 (true=200, false=401)
	UserRow      string // PostgREST /rest/v1/users 응답 JSON
}

func NewFakeSupabase(t *testing.T) *FakeSupabase {
	t.Helper()
	fs := &FakeSupabase{
		SessionValid: true,
		UserRow:      `{"nickname":"테스터","created_at":"2024-01-01T00:00:00Z"}`,
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/auth/v1/signup", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if fs.SignupError != "" {
			w.WriteHeader(http.StatusUnprocessableEntity)
			json.NewEncoder(w).Encode(map[string]string{"error_code": fs.SignupError})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{
			"access_token":  "fake-access-token",
			"refresh_token": "fake-refresh-token",
			"user":          map[string]string{"id": "fake-user-id"},
		})
	})

	mux.HandleFunc("/auth/v1/token", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if fs.LoginError {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "invalid_grant"})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{
			"access_token":  "fake-access-token",
			"refresh_token": "fake-refresh-token",
			"user":          map[string]string{"id": "fake-user-id"},
		})
	})

	mux.HandleFunc("/auth/v1/logout", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})

	mux.HandleFunc("/auth/v1/user", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if !fs.SessionValid {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "invalid_token"})
			return
		}
		json.NewEncoder(w).Encode(map[string]string{"id": "fake-user-id"})
	})

	mux.HandleFunc("/rest/v1/users", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(fs.UserRow))
	})

	fs.Server = httptest.NewServer(mux)
	t.Cleanup(fs.Server.Close)
	return fs
}
