package testutil

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

// NewFakeTurnstile는 항상 success:true를 반환하는 Turnstile 서버를 반환한다.
// 테스트 시작 시 *auth.ExportedTurnstileURL = srv.URL 로 교체하고 t.Cleanup으로 원복한다.
func NewFakeTurnstile(t *testing.T) *httptest.Server {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]any{"success": true})
	}))
	t.Cleanup(srv.Close)
	return srv
}
