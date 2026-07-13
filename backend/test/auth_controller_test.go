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

// 유효한 이메일 → 200 (확인 코드 발송, 세션은 아직 없음)
func TestSignup_Success(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	// 코드 검증 전이라 세션(access_token)은 응답에 없다
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] != nil {
		t.Error("access_token should not be present before code verification")
	}
}

// user_already_exists + 프로필 있음(가입 완료된 계정) → 409 Conflict
func TestSignup_DuplicateEmail(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.SignupError = "user_already_exists"
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusConflict {
		t.Errorf("status=%d want 409", w.Code)
	}
	assertErrorMsg(t, w, "이미 존재하는 이메일입니다.")
	if len(fs.DeletedAuthIDs) != 0 {
		t.Errorf("DeletedAuthIDs=%v want empty", fs.DeletedAuthIDs)
	}
}

// user_already_exists + 프로필 없음(미완료 가입) → 계정 삭제 후 재가입 성공(200)
func TestSignup_IncompleteAccountRecreated(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.SignupError = "user_already_exists"
	fs.ProfileRowExists = false
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	if len(fs.DeletedAuthIDs) != 1 || fs.DeletedAuthIDs[0] != "existing-user-id" {
		t.Errorf("DeletedAuthIDs=%v want [existing-user-id]", fs.DeletedAuthIDs)
	}
	if fs.SignupCalls != 2 {
		t.Errorf("SignupCalls=%d want 2", fs.SignupCalls)
	}
}

// 메일 발송 실패(발송 한도·SMTP 오류 등) → 503 + 재시도 안내
func TestSignup_EmailSendFailure(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.SignupError = "unexpected_failure"
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d want 503, body=%s", w.Code, w.Body)
	}
	assertErrorMsg(t, w, "인증 메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.")
}

// 이메일 형식 오류 → 400 (1단계는 이메일만 검증)
func TestSignup_InvalidEmail(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/signup", "", map[string]string{
		"email": "not-an-email",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

// ── Verify Signup (확인 코드 검증 → 가입 세션 토큰) ────────────────────────────────

// 유효한 코드 → 200 + access_token (계정 확정·세션 발급)
func TestVerifySignup_Success(t *testing.T) {
	router, fs, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/verify-signup", "", map[string]string{
		"email": "test@example.com", "code": "123456",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] == nil {
		t.Error("expected access_token after verification")
	}
	if fs.VerifyCalls != 1 {
		t.Errorf("VerifyCalls=%d want 1", fs.VerifyCalls)
	}
}

// 코드 불일치·만료(Supabase 4xx) → 400
func TestVerifySignup_InvalidCode(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.VerifyError = http.StatusForbidden
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/verify-signup", "", map[string]string{
		"email": "test@example.com", "code": "000000",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 코드 형식 오류 → 400, Supabase 호출 없음(코드 소모 방지)
func TestVerifySignup_BadCodeFormat(t *testing.T) {
	router, fs, _ := setupAccount(t)
	for _, code := range []string{"", "12345", "1234567", "12345a"} {
		w := doAccount(t, router, http.MethodPost, "/api/v1/auth/verify-signup", "", map[string]string{
			"email": "test@example.com", "code": code,
		})
		if w.Code != http.StatusBadRequest {
			t.Fatalf("code=%q: status=%d want 400, body=%s", code, w.Code, w.Body)
		}
	}
	if fs.VerifyCalls != 0 {
		t.Errorf("VerifyCalls=%d want 0", fs.VerifyCalls)
	}
}

func TestVerifySignup_InvalidEmail(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/verify-signup", "", map[string]string{
		"email": "not-an-email", "code": "123456",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// ── Complete Signup (비번·닉네임 설정 → 자동 로그인) ───────────────────────────────

// 가입 세션 + 유효한 비번·닉네임 → 200 + access_token (설정 후 재로그인)
func TestCompleteSignup_Success(t *testing.T) {
	router, fs, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/complete-signup", "", map[string]string{
		"access_token": "fake-signup-token", "password": "Test1234", "nickname": "테스터",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["access_token"] == nil {
		t.Error("expected access_token after completion")
	}
	// 프로필은 완료 시점에 upsert된다
	if len(fs.UpsertedProfiles) != 1 || fs.UpsertedProfiles[0] != "테스터" {
		t.Errorf("UpsertedProfiles=%v want [테스터]", fs.UpsertedProfiles)
	}
}

// 토큰 누락(코드 확인 안 함) → 400
func TestCompleteSignup_MissingToken(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/complete-signup", "", map[string]string{
		"password": "Test1234", "nickname": "테스터",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 약한 비밀번호 → 400 (Supabase 호출 전 로컬 검증)
func TestCompleteSignup_WeakPassword(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/complete-signup", "", map[string]string{
		"access_token": "fake-signup-token", "password": "weak", "nickname": "테스터",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 닉네임 누락 → 400
func TestCompleteSignup_MissingNickname(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/complete-signup", "", map[string]string{
		"access_token": "fake-signup-token", "password": "Test1234", "nickname": "  ",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 가입 세션 만료·무효(Supabase 401) → 401이 아닌 400으로 재안내
func TestCompleteSignup_SessionExpired(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.SessionValid = false // PUT /auth/v1/user 가 401을 주도록
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/complete-signup", "", map[string]string{
		"access_token": "expired-token", "password": "Test1234", "nickname": "테스터",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// ── Resend Signup (확인 코드 재발송) ─────────────────────────────────────────────

func TestResendSignup_Success(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/resend-signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
}

// Supabase 재발송 실패도 흡수해 200 (곧 재시도 가능)
func TestResendSignup_AbsorbsBackendError(t *testing.T) {
	router, fs, _ := setupAccount(t)
	fs.ResendError = http.StatusInternalServerError
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/resend-signup", "", map[string]string{
		"email": "test@example.com",
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
}

// 발송 전용 rate limit: 같은 IP 연속 3회 후 4번째는 429
func TestResendSignup_RateLimited(t *testing.T) {
	router, _, _ := setupAccount(t)
	body := map[string]string{"email": "test@example.com"}
	for i := 1; i <= 3; i++ {
		w := doAccount(t, router, http.MethodPost, "/api/v1/auth/resend-signup", "", body)
		if w.Code != http.StatusOK {
			t.Fatalf("request %d: status=%d want 200, body=%s", i, w.Code, w.Body)
		}
	}
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/resend-signup", "", body)
	if w.Code != http.StatusTooManyRequests {
		t.Fatalf("request 4: status=%d want 429, body=%s", w.Code, w.Body)
	}
}

func TestResendSignup_InvalidEmail(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/resend-signup", "", map[string]string{
		"email": "not-an-email",
	})
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// ── Login ─────────────────────────────────────────────────────────────────

func TestLogin_Success(t *testing.T) {
	router, _, _ := setupAccount(t)
	w := doAccount(t, router, http.MethodPost, "/api/v1/auth/login", "", map[string]string{
		"email": "test@example.com", "password": "Test1234!",
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
		"email": "test@example.com", "password": "Wrong1234!",
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
		"email": "nobody@example.com", "password": "Test1234!",
	})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "이메일 또는 비밀번호를 확인해주세요.")
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
	payload := fmt.Sprintf(`{"email":"a@b.com","password":"Test1234!","nickname":"%s"}`,
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
