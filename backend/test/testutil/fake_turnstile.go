package testutil

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func NewFakeTurnstile(t *testing.T) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"success": true})
	}))
	t.Cleanup(srv.Close)
	return srv
}
