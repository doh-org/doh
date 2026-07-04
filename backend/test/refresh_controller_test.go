package test

import (
	"encoding/json"
	"net/http"
	"testing"
)

// ── POST /api/v1/auth/refresh (토큰 재발급) ────────────────────────────────────

// 유효한 refresh → 200 + 회전된 새 access/refresh 반환
func TestRefresh_Success(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/refresh", "", map[string]any{
		"refresh_token": "fake-refresh-token",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] != "fake-access-token-2" {
		t.Errorf("access_token=%v want rotated token", resp["access_token"])
	}
	if resp["refresh_token"] != "fake-refresh-token-2" {
		t.Errorf("refresh_token=%v want rotated token", resp["refresh_token"])
	}
	if resp["user"] == nil {
		t.Error("expected user in response")
	}
}

// 만료·무효 refresh → 401 (재로그인 유도)
func TestRefresh_InvalidToken(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.RefreshError = true

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/refresh", "", map[string]any{
		"refresh_token": "expired-or-rotated",
	})
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401, body=%s", w.Code, w.Body)
	}
}

// refresh_token 누락 → 400
func TestRefresh_MissingToken(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/refresh", "", map[string]any{})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}
