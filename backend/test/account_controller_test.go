package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"doh/backend/domain"
	"doh/backend/internal/captcha"
	"doh/backend/test/testutil"
)

func setupAccount(t *testing.T) (http.Handler, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	ft := testutil.NewFakeTurnstile(t)

	old := captcha.Endpoint
	captcha.Endpoint = ft.URL
	t.Cleanup(func() { captcha.Endpoint = old })

	keys := testutil.NewTestKeys(t)
	router := testutil.NewTestAuthRouter(t, fs.Server.URL, keys, fs.Server.Client())
	return router, fs, keys
}

func accountToken(t *testing.T, keys *testutil.TestKeys, fs *testutil.FakeSupabase) string {
	t.Helper()
	return keys.Sign("fake-user-id", "test@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))
}

// accountIP는 테스트 이름 기반 고유 IP로 rate limiter 간섭을 방지한다.
func accountIP(t *testing.T) string {
	h := fnv.New32a()
	h.Write([]byte(t.Name()))
	n := h.Sum32()
	return fmt.Sprintf("10.%d.%d.%d", (n>>16)&0xFF, (n>>8)&0xFF, n&0xFF)
}

func doAccount(t *testing.T, router http.Handler, method, path, token string, body any) *httptest.ResponseRecorder {
	t.Helper()
	var buf bytes.Buffer
	if body != nil {
		json.NewEncoder(&buf).Encode(body)
	}
	req := httptest.NewRequest(method, path, &buf)
	req.RemoteAddr = accountIP(t) + ":12345"
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

// ── DELETE /api/v1/auth/me (회원 탈퇴) ─────────────────────────────────────────

func TestDeleteAccount_Success(t *testing.T) {
	router, fs, keys := setupAccount(t)
	fs.Trips = []domain.Trip{
		{ID: "t1", OwnerID: "fake-user-id", Title: "내 여행"},
		{ID: "t2", OwnerID: "other-user", Title: "남의 여행"},
	}
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodDelete, "/api/v1/auth/me", tok, nil)
	if w.Code != http.StatusNoContent {
		t.Fatalf("status=%d want 204, body=%s", w.Code, w.Body)
	}
	// 본인 trip만 삭제, 타인 trip 보존
	if len(fs.Trips) != 1 || fs.Trips[0].ID != "t2" {
		t.Errorf("trips=%v want only t2", fs.Trips)
	}
	// 탈퇴 RPC가 본인 id로 호출됨
	if len(fs.DeletedUserIDs) != 1 || fs.DeletedUserIDs[0] != "fake-user-id" {
		t.Errorf("DeletedUserIDs=%v want [fake-user-id]", fs.DeletedUserIDs)
	}
}

// RPC(단일 트랜잭션) 실패 → 500, trip·계정 모두 그대로(부분실패 없음)
func TestDeleteAccount_RPCFails_NothingDeleted(t *testing.T) {
	router, fs, keys := setupAccount(t)
	fs.Trips = []domain.Trip{{ID: "t1", OwnerID: "fake-user-id", Title: "내 여행"}}
	fs.DeleteAccountError = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodDelete, "/api/v1/auth/me", tok, nil)
	if w.Code != http.StatusInternalServerError {
		t.Fatalf("status=%d want 500", w.Code)
	}
	if len(fs.Trips) != 1 {
		t.Errorf("trips=%v want untouched", fs.Trips)
	}
	if len(fs.DeletedUserIDs) != 0 {
		t.Errorf("DeletedUserIDs=%v want empty", fs.DeletedUserIDs)
	}
}

func TestDeleteAccount_Unauthorized(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodDelete, "/api/v1/auth/me", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", w.Code)
	}
}

// ── PUT /api/v1/auth/password (비밀번호 변경) ──────────────────────────────────

func TestChangePassword_Success(t *testing.T) {
	router, fs, keys := setupAccount(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"current_password": "OldPass123",
		"new_password":     "NewPass123",
	})
	if w.Code != http.StatusNoContent {
		t.Fatalf("status=%d want 204, body=%s", w.Code, w.Body)
	}
}

// 현재 비밀번호 불일치(재인증 실패) → 400
func TestChangePassword_WrongCurrentPassword(t *testing.T) {
	router, fs, keys := setupAccount(t)
	fs.LoginError = true // 재인증 로그인 실패 재현
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"current_password": "WrongPass123",
		"new_password":     "NewPass123",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 현재 비밀번호 누락 → 400
func TestChangePassword_MissingCurrentPassword(t *testing.T) {
	router, fs, keys := setupAccount(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"new_password": "NewPass123",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// Supabase가 새 비밀번호를 거부(422: 이전과 동일 등)하면 401이 아닌 400으로 안내한다.
func TestChangePassword_SupabaseRejects_Returns400(t *testing.T) {
	router, fs, keys := setupAccount(t)
	fs.ChangePwError = http.StatusUnprocessableEntity
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"current_password": "OldPass123",
		"new_password":     "SamePass123",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// Supabase 5xx는 그대로 서버 오류(500)로 매핑된다.
func TestChangePassword_SupabaseServerError_Returns500(t *testing.T) {
	router, fs, keys := setupAccount(t)
	fs.ChangePwError = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"current_password": "OldPass123",
		"new_password":     "NewPass123",
	})
	if w.Code != http.StatusInternalServerError {
		t.Fatalf("status=%d want 500, body=%s", w.Code, w.Body)
	}
}

func TestChangePassword_WeakPassword(t *testing.T) {
	router, fs, keys := setupAccount(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodPut, "/api/v1/auth/password", tok, map[string]any{
		"current_password": "OldPass123",
		"new_password":     "short",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// ── POST /api/v1/auth/recover (재설정 메일) ────────────────────────────────────

func TestRecover_Success(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/recover", "", map[string]any{
		"email":         "user@example.com",
		"captcha_token": "tok",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
}

// Supabase 발송 실패도 흡수해 200 (사용자 열거 방지).
func TestRecover_AbsorbsBackendError(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.RecoverError = http.StatusInternalServerError

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/recover", "", map[string]any{
		"email":         "user@example.com",
		"captcha_token": "tok",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
}

func TestRecover_InvalidEmail(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/recover", "", map[string]any{
		"email":         "not-an-email",
		"captcha_token": "tok",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

func TestRecover_MissingCaptcha(t *testing.T) {
	router, _, _ := setupAccount(t)

	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/recover", "", map[string]any{
		"email": "user@example.com",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}
