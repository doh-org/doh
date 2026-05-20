package auth

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"
	"unicode"
)

// 센티널 에러
var (
	ErrCaptcha    = errors.New("captcha failed")
	ErrAuthFailed = errors.New("auth failed")
)

// ValidationError는 입력 검증 실패를 나타낸다.
type ValidationError struct{ Message string }

func (e *ValidationError) Error() string { return e.Message }

// --- 요청/응답 타입 (입력 전용 struct — id/role/created_at 필드 없음) ---

type SignupRequest struct {
	Email        string `json:"email"`
	Password     string `json:"password"`
	Nickname     string `json:"nickname"`
	CaptchaToken string `json:"captcha_token"`
}

type LoginRequest struct {
	Email        string `json:"email"`
	Password     string `json:"password"`
	CaptchaToken string `json:"captcha_token"`
}

type UserResponse struct {
	Email     string    `json:"email"`
	Nickname  string    `json:"nickname"`
	CreatedAt time.Time `json:"created_at"`
}

type AuthResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	User         UserResponse `json:"user"`
}

// supabaseSession은 Supabase Auth API 응답 내부 타입이다.
type supabaseSession struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         struct {
		ID string `json:"id"`
	} `json:"user"`
}

// --- Service ---

type Service struct {
	supabaseURL        string
	supabaseAnonKey    string
	turnstileSecretKey string
	httpClient         *http.Client
}

func NewService(supabaseURL, anonKey, turnstileKey string) *Service {
	return NewServiceWithClient(supabaseURL, anonKey, turnstileKey, &http.Client{Timeout: 10 * time.Second})
}

func NewServiceWithClient(supabaseURL, anonKey, turnstileKey string, client *http.Client) *Service {
	return &Service{
		supabaseURL:        supabaseURL,
		supabaseAnonKey:    anonKey,
		turnstileSecretKey: turnstileKey,
		httpClient:         client,
	}
}

func (s *Service) Signup(ctx context.Context, req SignupRequest) (*AuthResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Nickname = strings.TrimSpace(req.Nickname)

	if err := validateEmail(req.Email); err != nil {
		return nil, err
	}
	if err := validatePassword(req.Password); err != nil {
		return nil, err
	}
	if err := validateNickname(req.Nickname); err != nil {
		return nil, err
	}
	if strings.TrimSpace(req.CaptchaToken) == "" {
		return nil, &ValidationError{Message: "보안 인증 토큰이 필요합니다."}
	}

	if err := verifyCaptcha(s.turnstileSecretKey, req.CaptchaToken); err != nil {
		slog.Warn("signup captcha failed", "err", err)
		return nil, ErrCaptcha
	}

	// nickname을 raw_user_meta_data에 포함 → 트리거가 public.users에 자동 INSERT
	body := map[string]any{
		"email":    req.Email,
		"password": req.Password,
		"data":     map[string]string{"nickname": sanitizeNickname(req.Nickname)},
	}
	session, err := s.callAuth(ctx, http.MethodPost, "/auth/v1/signup", body, "")
	if err != nil {
		return nil, ErrAuthFailed
	}

	user, err := s.fetchUser(ctx, session.User.ID, req.Email, session.AccessToken)
	if err != nil {
		return nil, ErrAuthFailed
	}

	return &AuthResponse{
		AccessToken:  session.AccessToken,
		RefreshToken: session.RefreshToken,
		User:         *user,
	}, nil
}

func (s *Service) Login(ctx context.Context, req LoginRequest) (*AuthResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return nil, err
	}
	if strings.TrimSpace(req.CaptchaToken) == "" {
		return nil, &ValidationError{Message: "보안 인증 토큰이 필요합니다."}
	}

	if err := verifyCaptcha(s.turnstileSecretKey, req.CaptchaToken); err != nil {
		slog.Warn("login captcha failed", "err", err)
		return nil, ErrCaptcha
	}

	body := map[string]any{
		"email":    req.Email,
		"password": req.Password,
	}
	session, err := s.callAuth(ctx, http.MethodPost, "/auth/v1/token?grant_type=password", body, "")
	if err != nil {
		return nil, ErrAuthFailed
	}

	user, err := s.fetchUser(ctx, session.User.ID, req.Email, session.AccessToken)
	if err != nil {
		return nil, ErrAuthFailed
	}

	return &AuthResponse{
		AccessToken:  session.AccessToken,
		RefreshToken: session.RefreshToken,
		User:         *user,
	}, nil
}

func (s *Service) Logout(ctx context.Context, accessToken string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		s.supabaseURL+"/auth/v1/logout", nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("apikey", s.supabaseAnonKey)

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)
	return nil
}

func (s *Service) Me(ctx context.Context, userID, email, accessToken string) (*UserResponse, error) {
	return s.fetchUser(ctx, userID, email, accessToken)
}

// fetchUser는 PostgREST로 public.users에서 프로필을 조회한다. RLS 자동 적용.
// email은 JWT 클레임에서 전달받아 응답에 포함한다.
func (s *Service) fetchUser(ctx context.Context, userID, email, accessToken string) (*UserResponse, error) {
	url := fmt.Sprintf("%s/rest/v1/users?id=eq.%s&select=nickname,created_at",
		s.supabaseURL, userID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("apikey", s.supabaseAnonKey)
	req.Header.Set("Accept", "application/vnd.pgrst.object+json")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetchUser: status %d", resp.StatusCode)
	}

	var user UserResponse
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, err
	}
	user.Email = email
	return &user, nil
}

// callAuth는 Supabase Auth REST API를 호출하고 세션을 반환한다.
func (s *Service) callAuth(ctx context.Context, method, path string, body map[string]any, accessToken string) (*supabaseSession, error) {
	b, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, method,
		s.supabaseURL+path, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", s.supabaseAnonKey)
	if accessToken != "" {
		req.Header.Set("Authorization", "Bearer "+accessToken)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode >= 400 {
		slog.Error("supabase auth error", "status", resp.StatusCode, "body", string(respBody))
		return nil, fmt.Errorf("supabase auth error: status %d", resp.StatusCode)
	}

	var session supabaseSession
	if err := json.Unmarshal(respBody, &session); err != nil {
		return nil, err
	}
	return &session, nil
}

// --- 입력 검증 헬퍼 ---

func validateEmail(email string) error {
	if !strings.Contains(email, "@") || len(email) < 3 {
		return &ValidationError{Message: "올바른 이메일 형식이 아닙니다."}
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 8 {
		return &ValidationError{Message: "비밀번호는 8자 이상이어야 합니다."}
	}
	var hasUpper, hasLower, hasDigit bool
	for _, r := range password {
		switch {
		case unicode.IsUpper(r):
			hasUpper = true
		case unicode.IsLower(r):
			hasLower = true
		case unicode.IsDigit(r):
			hasDigit = true
		}
	}
	if !hasUpper {
		return &ValidationError{Message: "비밀번호에 대문자가 포함되어야 합니다."}
	}
	if !hasLower {
		return &ValidationError{Message: "비밀번호에 소문자가 포함되어야 합니다."}
	}
	if !hasDigit {
		return &ValidationError{Message: "비밀번호에 숫자가 포함되어야 합니다."}
	}
	return nil
}

func validateNickname(nickname string) error {
	if len([]rune(nickname)) < 1 {
		return &ValidationError{Message: "닉네임을 입력해주세요."}
	}
	if len([]rune(nickname)) > 50 {
		return &ValidationError{Message: "닉네임은 50자 이하여야 합니다."}
	}
	return nil
}

// sanitizeNickname은 XSS 유발 문자를 제거한다.
func sanitizeNickname(s string) string {
	s = strings.ReplaceAll(s, "<", "")
	s = strings.ReplaceAll(s, ">", "")
	s = strings.ReplaceAll(s, "&", "")
	s = strings.ReplaceAll(s, `"`, "")
	return strings.TrimSpace(s)
}
