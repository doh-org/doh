package auth_test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"doh/backend/api/middleware"
	"doh/backend/internal/auth"
	"doh/backend/test/testutil"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func newRouter(t *testing.T, fs *testutil.FakeSupabase, keys *testutil.TestKeys) http.Handler {
	t.Helper()
	svc := auth.NewServiceWithClient(fs.Server.URL, "fake-anon-key", "fake-key", fs.Server.Client())
	h := auth.NewHandler(svc)

	r := gin.New()
	v1 := r.Group("/api/v1")
	authGroup := v1.Group("/auth")

	public := authGroup.Group("")
	public.Use(middleware.RateLimit())
	public.POST("/signup", h.Signup)
	public.POST("/login", h.Login)

	protected := authGroup.Group("")
	protected.Use(middleware.Auth(keys.PublicKeys, fs.Server.URL, "fake-anon-key", fs.Server.Client()))
	protected.POST("/logout", h.Logout)
	protected.GET("/me", h.Me)

	return r
}

func setup(t *testing.T) (http.Handler, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	ft := testutil.NewFakeTurnstile(t)

	old := *auth.ExportedTurnstileURL
	*auth.ExportedTurnstileURL = ft.URL
	t.Cleanup(func() { *auth.ExportedTurnstileURL = old })

	keys := testutil.NewTestKeys(t)
	return newRouter(t, fs, keys), fs, keys
}

// testIP는 테스트 이름 기반 고유 IP를 생성해 rate limiter 간섭을 방지한다.
func testIP(t *testing.T) string {
	h := fnv.New32a()
	h.Write([]byte(t.Name()))
	n := h.Sum32()
	return fmt.Sprintf("10.%d.%d.%d", (n>>16)&0xFF, (n>>8)&0xFF, n&0xFF)
}

func post(t *testing.T, router http.Handler, path string, body any) *httptest.ResponseRecorder {
	t.Helper()
	b, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, path, bytes.NewReader(b))
	req.Header.Set("Content-Type", "application/json")
	req.RemoteAddr = testIP(t) + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func get(t *testing.T, router http.Handler, path, token string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, path, nil)
	req.RemoteAddr = testIP(t) + ":12345"
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

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

func validToken(t *testing.T, fs *testutil.FakeSupabase, keys *testutil.TestKeys) string {
	t.Helper()
	return keys.Sign("fake-user-id", "test@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))
}

// --- Signup ---

// 유효한 이메일·비밀번호·닉네임·캡차 토큰 → 201 Created + access_token 반환 확인
func TestSignup_Success(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
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

// FakeSupabase에 user_already_exists 에러 주입 → 409 Conflict + "이미 존재하는 이메일입니다." 메시지 확인
func TestSignup_DuplicateEmail(t *testing.T) {
	router, fs, _ := setup(t)
	fs.SignupError = "user_already_exists"
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
		"email": "test@example.com", "password": "Test1234!", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusConflict {
		t.Errorf("status=%d want 409", w.Code)
	}
	assertErrorMsg(t, w, "이미 존재하는 이메일입니다.")
}

// 대문자 없는 비밀번호("test1234") → 400 + "비밀번호에 대문자가 포함되어야 합니다." 메시지 확인
func TestSignup_WeakPassword(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
		"email": "a@b.com", "password": "test1234", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "비밀번호에 대문자가 포함되어야 합니다.")
}

// 3자 비밀번호("Ab1") → 400 + "비밀번호는 8자 이상이어야 합니다." 메시지 확인
func TestSignup_PasswordTooShort(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
		"email": "a@b.com", "password": "Ab1", "nickname": "테스터", "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "비밀번호는 8자 이상이어야 합니다.")
}

// captcha_token 필드 누락 → 400 + "보안 인증 토큰이 필요합니다." 메시지 확인
func TestSignup_MissingCaptcha(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
		"email": "a@b.com", "password": "Test1234!", "nickname": "테스터",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "보안 인증 토큰이 필요합니다.")
}

// 51자 닉네임 → 400 + "닉네임은 50자 이하여야 합니다." 메시지 확인
func TestSignup_NicknameTooLong(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/signup", map[string]string{
		"email": "a@b.com", "password": "Test1234!", "nickname": strings.Repeat("가", 51), "captcha_token": "test",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
	assertErrorMsg(t, w, "닉네임은 50자 이하여야 합니다.")
}

// --- Login ---

// 유효한 이메일·비밀번호·캡차 토큰 → 200 OK + access_token 반환 확인
func TestLogin_Success(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/login", map[string]string{
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

// FakeSupabase LoginError 주입(틀린 비밀번호) → 401 + "이메일 또는 비밀번호를 확인해주세요." 메시지 확인
func TestLogin_WrongPassword(t *testing.T) {
	router, fs, _ := setup(t)
	fs.LoginError = true
	w := post(t, router, "/api/v1/auth/login", map[string]string{
		"email": "test@example.com", "password": "Wrong1234!", "captcha_token": "test",
	})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "이메일 또는 비밀번호를 확인해주세요.")
}

// 존재하지 않는 이메일로 로그인 → 401 + WrongPassword와 동일 메시지(보안상 구분 금지) 확인
func TestLogin_UnknownEmail(t *testing.T) {
	router, fs, _ := setup(t)
	fs.LoginError = true
	w := post(t, router, "/api/v1/auth/login", map[string]string{
		"email": "nobody@example.com", "password": "Test1234!", "captcha_token": "test",
	})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "이메일 또는 비밀번호를 확인해주세요.")
}

// captcha_token 누락 → 400 확인
func TestLogin_MissingCaptcha(t *testing.T) {
	router, _, _ := setup(t)
	w := post(t, router, "/api/v1/auth/login", map[string]string{
		"email": "test@example.com", "password": "Test1234!",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

// --- Me ---

// 유효 JWT로 GET /me → 200 + email, user_id 포함 확인
func TestMe_Authorized(t *testing.T) {
	router, fs, keys := setup(t)
	w := get(t, router, "/api/v1/auth/me", validToken(t, fs, keys))
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

// Authorization 헤더 없이 GET /me → 401 + "인증이 필요합니다." 메시지 확인
func TestMe_NoToken(t *testing.T) {
	router, _, _ := setup(t)
	w := get(t, router, "/api/v1/auth/me", "")
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "인증이 필요합니다.")
}

// 형식이 잘못된 JWT("invalid.token.here")로 GET /me → 401 확인
func TestMe_InvalidToken(t *testing.T) {
	router, _, _ := setup(t)
	w := get(t, router, "/api/v1/auth/me", "invalid.token.here")
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// --- Logout ---

// 유효 JWT로 POST /logout → 204 No Content 확인
func TestLogout_Success(t *testing.T) {
	router, fs, keys := setup(t)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.Header.Set("Authorization", "Bearer "+validToken(t, fs, keys))
	req.RemoteAddr = testIP(t) + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusNoContent {
		t.Errorf("status=%d want 204", w.Code)
	}
}

// 로그아웃 후 SessionValid=false로 세션 무효화 → 동일 토큰으로 /me 접근 시 401 + "로그인이 필요합니다." 확인
func TestLogout_TokenRevoked(t *testing.T) {
	router, fs, keys := setup(t)
	token := validToken(t, fs, keys)

	// 로그아웃
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	req.RemoteAddr = testIP(t) + ":12345"
	router.ServeHTTP(httptest.NewRecorder(), req)

	// 세션 무효화 후 동일 토큰으로 /me 접근
	fs.SessionValid = false
	w := get(t, router, "/api/v1/auth/me", token)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
	assertErrorMsg(t, w, "로그인이 필요합니다.")
}

// Authorization 헤더 없이 POST /logout → 401 확인
func TestLogout_NoToken(t *testing.T) {
	router, _, _ := setup(t)
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/logout", nil)
	req.RemoteAddr = testIP(t) + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// --- Request size ---

// 2000자 이상의 닉네임으로 /signup 요청 → 413 Request Entity Too Large + "요청이 너무 큽니다." 확인
func TestRequestBodyTooLarge(t *testing.T) {
	router, _, _ := setup(t)
	payload := fmt.Sprintf(`{"email":"a@b.com","password":"Test1234!","nickname":"%s","captcha_token":"test"}`,
		strings.Repeat("x", 2000))
	req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/signup", strings.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	req.RemoteAddr = testIP(t) + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	if w.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("status=%d want 413", w.Code)
	}
	assertErrorMsg(t, w, "요청이 너무 큽니다.")
}
