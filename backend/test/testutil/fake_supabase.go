package testutil

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	"doh/backend/domain"
)

// FakeSupabase는 Supabase Auth + PostgREST 엔드포인트를 시뮬레이션한다.
type FakeSupabase struct {
	Server       *httptest.Server
	SignupError  string // "user_already_exists" 등 error_code; 빈 문자열이면 성공
	LoginError   bool
	SessionValid bool   // GET /auth/v1/user 응답 (true=200, false=401)
	UserRow      string // PostgREST /rest/v1/users 응답 JSON

	// Trips
	Trips       []domain.Trip
	CreateError int // 0이면 성공, 그 외 HTTP status 반환
	UpdateError int
	DeleteError int
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

	mux.HandleFunc("/rest/v1/trips", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		idFilter := parseIDEqFilter(r.URL.Query())

		switch r.Method {
		case http.MethodPost:
			if fs.CreateError != 0 {
				w.WriteHeader(fs.CreateError)
				return
			}
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			fs.Trips = append(fs.Trips, tripFromBody(body))
			w.WriteHeader(http.StatusCreated)

		case http.MethodGet:
			json.NewEncoder(w).Encode(fs.filterTrips(idFilter))

		case http.MethodPatch:
			if fs.UpdateError != 0 {
				w.WriteHeader(fs.UpdateError)
				return
			}
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			for i, t := range fs.Trips {
				if t.ID == idFilter {
					applyUpdate(&fs.Trips[i], body)
					json.NewEncoder(w).Encode([]domain.Trip{fs.Trips[i]})
					return
				}
			}
			json.NewEncoder(w).Encode([]domain.Trip{})

		case http.MethodDelete:
			if fs.DeleteError != 0 {
				w.WriteHeader(fs.DeleteError)
				return
			}
			for i, t := range fs.Trips {
				if t.ID == idFilter {
					fs.Trips = append(fs.Trips[:i], fs.Trips[i+1:]...)
					break
				}
			}
			w.WriteHeader(http.StatusNoContent)
		}
	})

	fs.Server = httptest.NewServer(mux)
	t.Cleanup(fs.Server.Close)
	return fs
}

func parseIDEqFilter(q url.Values) string {
	return strings.TrimPrefix(q.Get("id"), "eq.")
}

func (fs *FakeSupabase) filterTrips(id string) []domain.Trip {
	var result []domain.Trip
	for _, t := range fs.Trips {
		if t.DeletedAt != nil {
			continue
		}
		if id != "" && t.ID != id {
			continue
		}
		result = append(result, t)
	}
	if result == nil {
		return []domain.Trip{}
	}
	return result
}

func tripFromBody(body map[string]any) domain.Trip {
	t := domain.Trip{CreatedAt: time.Now().UTC()}
	if v, ok := body["id"].(string); ok {
		t.ID = v
	}
	if v, ok := body["owner_id"].(string); ok {
		t.OwnerID = v
	}
	if v, ok := body["title"].(string); ok {
		t.Title = v
	}
	if v, ok := body["description"].(string); ok {
		s := v
		t.Description = &s
	}
	if v, ok := body["destination"].(string); ok {
		s := v
		t.Destination = &s
	}
	if v, ok := body["start_date"].(string); ok {
		s := v
		t.StartDate = &s
	}
	if v, ok := body["end_date"].(string); ok {
		s := v
		t.EndDate = &s
	}
	return t
}

func applyUpdate(t *domain.Trip, body map[string]any) {
	if v, ok := body["title"].(string); ok {
		t.Title = v
	}
	if v, ok := body["description"].(string); ok {
		s := v
		t.Description = &s
	}
	if v, ok := body["destination"].(string); ok {
		s := v
		t.Destination = &s
	}
	if v, ok := body["start_date"].(string); ok {
		s := v
		t.StartDate = &s
	}
	if v, ok := body["end_date"].(string); ok {
		s := v
		t.EndDate = &s
	}
}
