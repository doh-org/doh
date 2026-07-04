package test

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// internal/auth(구 경로) 삭제로 이식한 signup/login/logout/me e2e 테스트.
// 라우터·헬퍼는 account_controller_test.go의 setupAccount/doAccount를 공유한다.

func assertErrorMsg(t *testing.T, w *httptest.ResponseRecorder, want string) {
	t.Helper()
	var resp map[string]string
	if err := json.NewDecoder(w.Body).Decode(&resp); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if resp["error"] != want {
		t.Errorf("error=%q want=%q", resp["error"], want)
	}
}

// ── Signup ────────────────────────────────────────────────────────────────

// 유효한 이메일·비밀번호·닉네임·캡차 → 201 + access_token
func TestSignup_Success(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com", "password": "Test1234!", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusCreated {
		t.Fatalf("status=%d want 201, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] == nil {
		t.Error("expected access_token in response")
	}
}

// user_already_exists 주입 → 409 Conflict
func TestSignup_DuplicateEmail(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.SignupError = "user_already_exists"
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com", "password": "Test1234!", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusConflict {
		t.Errorf("status=%d want 409", w.Code)
	}
	assertErrorMsg(t, w, "이미 존재하는 이메일입니다.")
}

// 대문자 없는 비밀번호 → 400
func TestSignup_WeakPassword(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "a@b.com", "password": "test1234", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "비밀번호에 대문자가 포함되어야 합니다.")
}

// 8자 미만 비밀번호 → 400
func TestSignup_PasswordTooShort(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "a@b.com", "password": "Ab1", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "비밀번호는 8자 이상이어야 합니다.")
}

// captcha_token 누락 → 400
func TestSignup_MissingCaptcha(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "a@b.com", "password": "Test1234!", "nickname": "테스터",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "보안 인증 토큰이 필요합니다.")
}

// 51자 닉네임 → 400
func TestSignup_NicknameTooLong(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "a@b.com", "password": "Test1234!", "nickname": strings.Repeat("가", 51), "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "닉네임은 50자 이하여야 합니다.")
}

// ── Login ─────────────────────────────────────────────────────────────────

func TestLogin_Success(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"email": "test@example.com", "password": "Test1234!", "captcha_token": "test",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] == nil {
		t.Error("expected access_token")
	}
}

// 틀린 비밀번호 → 401
func TestLogin_WrongPassword(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.LoginError = true
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"email": "test@example.com", "password": "Wrong1234!", "captcha_token": "test",
	})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "이메일 또는 비밀번호를 확인해주세요.")
}

// 미존재 이메일 → 401, WrongPassword와 동일 메시지(계정 존재 여부 노출 금지)
func TestLogin_UnknownEmail(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.LoginError = true
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"email": "nobody@example.com", "password": "Test1234!", "captcha_token": "test",
	})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "이메일 또는 비밀번호를 확인해주세요.")
}

func TestLogin_MissingCaptcha(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"email": "test@example.com", "password": "Test1234!",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

// ── Me ────────────────────────────────────────────────────────────────────

func TestMe_Authorized(t *testing.T) {
	router, fs, keys := setupAccount(t)
	w := doAccount(t, router, http.MethodGet, "/api/v1/auth/me", accountToken(t, keys, fs), nil)
	if w.Code != http.StatusOK {
		t.Errorf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["email"] == nil {
		t.Error("expected email in response")
	}
	if resp["user_id"] == nil {
		t.Error("expected user_id in response")
	}
}

func TestMe_NoToken(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodGet, "/api/v1/auth/me", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "인증이 필요합니다.")
}

func TestMe_InvalidToken(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodGet, "/api/v1/auth/me", "invalid.token.here", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── Logout ────────────────────────────────────────────────────────────────

func TestLogout_Success(t *testing.T) {
	router, fs, keys := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/logout", accountToken(t, keys, fs), nil)
	if w.Code != http.StatusNoContent {
		t.Errorf("status=%d want 204", w.Code)
	}
}

// 세션 무효화 후 동일 토큰으로 /me → 401
func TestLogout_TokenRevoked(t *testing.T) {
	router, fs, keys := setupAccount(t)
	token := accountToken(t, keys, fs)

	doAccount(t, router, http.MethodPost, "/api/v1/auth/logout", token, nil)

	fs.SessionValid = false // Supabase 세션 만료 상태 재현
	w := doAccount(t, router, http.MethodGet, "/api/v1/auth/me", token, nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "로그인이 필요합니다.")
}

func TestLogout_NoToken(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/logout", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── Request size ──────────────────────────────────────────────────────────

// 본문 상한(4KB) 초과 → 413
func TestRequestBodyTooLarge(t *testing.T) {
	router, _, _ := setupAccount(t)
	payload := fmt.Sprintf(`{"email":"a@b.com","password":"Test1234!","nickname":"%s","captcha_token":"test"}`,
		strings.Repeat("x", 5000))
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/signup", strings.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	req.RemoteAddr = accountIP(t) + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("status=%d want 413", w.Code)
	}
	assertErrorMsg(t, w, "요청이 너무 큽니다.")
}
