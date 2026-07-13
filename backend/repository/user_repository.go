package repository

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	neturl "net/url"
	"strings"
	"time"

	"doh/backend/domain"
)

type supabaseError struct {
	ErrorCode string `json:"error_code"`
}

type supabaseSession struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         struct {
		ID    string `json:"id"`
		Email string `json:"email"` // refresh 시 프로필 재조회에 필요
	} `json:"user"`
}

type userRepository struct {
	supabaseURL        string
	supabaseAnonKey    string
	supabaseServiceKey string
	httpClient         *http.Client
}

func NewUserRepository(supabaseURL, anonKey, serviceRoleKey string, client *http.Client) domain.UserRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &userRepository{
		supabaseURL:        supabaseURL,
		supabaseAnonKey:    anonKey,
		supabaseServiceKey: serviceRoleKey,
		httpClient:         client,
	}
}

// StartEmailSignup은 확인 코드 발송을 트리거한다(1단계). POST /auth/v1/signup.
// 비번은 3단계에서 받으므로 여기선 임시 비밀번호로 계정을 선생성한다.
// 임시 비번은 CompleteSignup의 PUT /auth/v1/user로 곧바로 교체된다.
// Confirm email이 켜져 있어 응답 세션은 비어 있고(코드 검증 전) 계정은 미확정으로 생성된다.
func (r *userRepository) StartEmailSignup(ctx context.Context, email string) error {
	tempPassword, err := randomPassword()
	if err != nil {
		return err
	}
	body := map[string]any{
		"email":    email,
		"password": tempPassword,
	}
	if _, err := r.callAuth(ctx, http.MethodPost, "/auth/v1/signup", body, ""); err != nil {
		return err
	}
	return nil
}

// VerifySignupCode는 확인 코드를 검증한다(2단계). POST /auth/v1/verify (type=signup).
// 성공 시 계정이 확정되고 가입 세션 토큰(access_token)이 발급된다.
func (r *userRepository) VerifySignupCode(ctx context.Context, email, code string) (string, error) {
	body := map[string]any{
		"type":  "signup",
		"email": email,
		"token": code, // Supabase는 메일의 6자리 코드를 token 필드로 받는다
	}
	req, err := r.jsonReq(ctx, http.MethodPost, "/auth/v1/verify", body, "")
	if err != nil {
		return "", err
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return "", err
	}
	switch {
	// 4xx → 코드 불일치·만료 (Supabase: 403 otp_expired 등)
	case resp.StatusCode >= 400 && resp.StatusCode < 500:
		slog.Warn("verifySignup rejected", "status", resp.StatusCode)
		return "", domain.ErrInvalidCode
	case resp.StatusCode >= 500:
		return "", fmt.Errorf("verifySignup: status %d", resp.StatusCode)
	}

	var session supabaseSession
	if err := json.Unmarshal(respBody, &session); err != nil {
		return "", err
	}
	return session.AccessToken, nil
}

// SetSignupCredentials는 가입 세션으로 비번·닉네임을 설정한다(3단계). PUT /auth/v1/user.
// data.nickname은 raw_user_meta_data에 저장되며, public.users 갱신은 별도(UpdateProfileNickname).
// 확정된 계정의 userID·email을 응답에서 파싱해 돌려준다.
func (r *userRepository) SetSignupCredentials(ctx context.Context, accessToken, password, nickname string) (string, string, error) {
	body := map[string]any{
		"password": password,
		"data":     map[string]string{"nickname": nickname},
	}
	req, err := r.jsonReq(ctx, http.MethodPut, "/auth/v1/user", body, accessToken)
	if err != nil {
		return "", "", err
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return "", "", err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return "", "", err
	}
	switch {
	case resp.StatusCode == http.StatusUnauthorized:
		// 가입 세션 만료·무효 → 코드부터 다시 받게 안내
		return "", "", domain.ErrAuthFailed
	case resp.StatusCode >= 400 && resp.StatusCode < 500:
		// 비번 정책 거부 등
		slog.Warn("setSignupCredentials rejected", "status", resp.StatusCode)
		return "", "", &domain.ValidationError{Message: "비밀번호가 거부되었습니다. 다른 비밀번호를 사용해주세요."}
	case resp.StatusCode >= 500:
		return "", "", fmt.Errorf("setSignupCredentials: status %d", resp.StatusCode)
	}

	// PUT /auth/v1/user 응답은 유저 객체를 루트에 담는다(세션 아님).
	var u struct {
		ID    string `json:"id"`
		Email string `json:"email"`
	}
	if err := json.Unmarshal(respBody, &u); err != nil {
		return "", "", err
	}
	return u.ID, u.Email, nil
}

// UpsertProfile은 public.users 프로필을 생성/갱신한다(service key로 RLS 우회).
// POST /rest/v1/users (Prefer: resolution=merge-duplicates).
func (r *userRepository) UpsertProfile(ctx context.Context, userID, nickname string) error {
	b, err := json.Marshal(map[string]any{"id": userID, "nickname": nickname})
	if err != nil {
		return err
	}
	url := r.supabaseURL + "/rest/v1/users"
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)
	req.Header.Set("Prefer", "resolution=merge-duplicates,return=minimal")

	status, err := r.doDrain(req)
	if err != nil {
		return err
	}
	if status >= 400 {
		return fmt.Errorf("upsertProfile: status %d", status)
	}
	return nil
}

// FindAuthUserIDByEmail은 이메일로 auth 계정 ID를 조회한다. 없으면 "".
// GET /auth/v1/admin/users?filter={email} — filter는 부분일치라 정확히 같은 것만 채택.
func (r *userRepository) FindAuthUserIDByEmail(ctx context.Context, email string) (string, error) {
	reqURL := fmt.Sprintf("%s/auth/v1/admin/users?filter=%s", r.supabaseURL, neturl.QueryEscape(email))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("findAuthUserIDByEmail: status %d", resp.StatusCode)
	}

	var out struct {
		Users []struct {
			ID    string `json:"id"`
			Email string `json:"email"`
		} `json:"users"`
	}
	if err := json.Unmarshal(respBody, &out); err != nil {
		return "", err
	}
	for _, u := range out.Users {
		if strings.EqualFold(u.Email, email) {
			return u.ID, nil
		}
	}
	return "", nil
}

// ProfileExists는 public.users에 해당 ID의 행이 있는지 확인한다(service key).
// GET /rest/v1/users?id=eq.{userID}&select=id.
func (r *userRepository) ProfileExists(ctx context.Context, userID string) (bool, error) {
	reqURL := fmt.Sprintf("%s/rest/v1/users?id=eq.%s&select=id", r.supabaseURL, neturl.QueryEscape(userID))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return false, err
	}
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return false, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return false, err
	}
	if resp.StatusCode != http.StatusOK {
		return false, fmt.Errorf("profileExists: status %d", resp.StatusCode)
	}

	var rows []json.RawMessage
	if err := json.Unmarshal(respBody, &rows); err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

// DeleteAuthUser는 auth 계정을 삭제한다(service key).
// DELETE /auth/v1/admin/users/{userID}.
func (r *userRepository) DeleteAuthUser(ctx context.Context, userID string) error {
	reqURL := fmt.Sprintf("%s/auth/v1/admin/users/%s", r.supabaseURL, neturl.PathEscape(userID))
	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, reqURL, nil)
	if err != nil {
		return err
	}
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)

	status, err := r.doDrain(req)
	if err != nil {
		return err
	}
	if status >= 400 {
		return fmt.Errorf("deleteAuthUser: status %d", status)
	}
	return nil
}

// randomPassword는 계정 선생성용 임시 비밀번호를 만든다(사용자에게 노출되지 않음).
// 24바이트 난수 base64 + 복잡도 보강("Aa1!") → 어떤 비번 정책도 통과. 3단계에서 교체된다.
func randomPassword() (string, error) {
	buf := make([]byte, 24)
	if _, err := rand.Read(buf); err != nil {
		return "", err
	}
	return base64.RawURLEncoding.EncodeToString(buf) + "Aa1!", nil
}

// ResendSignup은 확인메일(코드)을 재발송한다. POST /auth/v1/resend (type=signup).
// 실패 로깅은 호출자(usecase)가 담당한다.
func (r *userRepository) ResendSignup(ctx context.Context, email string) error {
	body := map[string]any{"type": "signup", "email": email}
	req, err := r.jsonReq(ctx, http.MethodPost, "/auth/v1/resend", body, "")
	if err != nil {
		return err
	}
	status, err := r.doDrain(req)
	if err != nil {
		return err
	}
	if status >= 400 {
		return fmt.Errorf("resendSignup: status %d", status)
	}
	return nil
}

func (r *userRepository) LoginWithEmail(ctx context.Context, email, password string) (string, string, string, error) {
	body := map[string]any{
		"email":    email,
		"password": password,
	}
	session, err := r.callAuth(ctx, http.MethodPost, "/auth/v1/token?grant_type=password", body, "")
	if err != nil {
		return "", "", "", err
	}
	return session.AccessToken, session.RefreshToken, session.User.ID, nil
}

// RefreshSession은 refresh 토큰으로 새 세션을 발급받는다.
// Supabase refresh는 일회용(rotation) — 응답의 새 refresh를 반환하고 저장은 프론트 책임.
func (r *userRepository) RefreshSession(ctx context.Context, refreshToken string) (string, string, string, string, error) {
	body := map[string]any{"refresh_token": refreshToken}
	session, err := r.callAuth(ctx, http.MethodPost, "/auth/v1/token?grant_type=refresh_token", body, "")
	if err != nil {
		return "", "", "", "", err
	}
	return session.AccessToken, session.RefreshToken, session.User.ID, session.User.Email, nil
}

func (r *userRepository) Logout(ctx context.Context, accessToken string) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.supabaseURL+"/auth/v1/logout", nil)
	if err != nil {
		return err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("apikey", r.supabaseAnonKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)
	return nil
}

func (r *userRepository) GetProfile(ctx context.Context, userID, email, accessToken string) (*domain.UserResponse, error) {
	url := fmt.Sprintf("%s/rest/v1/users?id=eq.%s&select=nickname,created_at", r.supabaseURL, userID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Accept", "application/vnd.pgrst.object+json")

	resp, err := r.httpClient.Do(req)
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

	var user domain.UserResponse
	if err := json.Unmarshal(body, &user); err != nil {
		return nil, err
	}
	user.UserID = userID
	user.Email = email
	return &user, nil
}

// doDrain은 요청을 보내고 응답 본문은 버린 뒤 상태코드만 반환한다.
// keep-alive 재사용을 위해 body는 반드시 읽고 닫는다. 응답 크기는 4KB로 제한.
func (r *userRepository) doDrain(req *http.Request) (int, error) {
	resp, err := r.httpClient.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	return resp.StatusCode, nil
}

// jsonReq는 JSON 본문 요청을 만들고 apikey/Authorization 헤더를 붙인다.
// bearer가 빈 문자열이면 Authorization은 생략한다.
func (r *userRepository) jsonReq(ctx context.Context, method, path string, body map[string]any, bearer string) (*http.Request, error) {
	b, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequestWithContext(ctx, method, r.supabaseURL+path, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseAnonKey)
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	return req, nil
}

// ChangePassword는 사용자 JWT로 본인 비밀번호를 변경한다. PUT /auth/v1/user.
func (r *userRepository) ChangePassword(ctx context.Context, accessToken, newPassword string) error {
	req, err := r.jsonReq(ctx, http.MethodPut, "/auth/v1/user", map[string]any{"password": newPassword}, accessToken)
	if err != nil {
		return err
	}
	status, err := r.doDrain(req)
	if err != nil {
		return err
	}

	switch {
	case status == http.StatusOK || status == http.StatusNoContent:
		return nil
	case status == http.StatusUnauthorized:
		// 토큰 무효/만료 → 인증 실패로 전달
		return domain.ErrAuthFailed
	case status >= 400 && status < 500:
		// Supabase가 새 비밀번호 거부(422: 이전과 동일 등) → 400으로 안내
		slog.Warn("changePassword rejected", "status", status)
		return &domain.ValidationError{Message: "새 비밀번호가 거부되었습니다. 다른 비밀번호를 사용해주세요."}
	default:
		return fmt.Errorf("changePassword: status %d", status)
	}
}

// RequestRecovery는 비밀번호 재설정 메일 발송을 요청한다. POST /auth/v1/recover.
// 실패 로깅은 호출자(usecase)가 담당한다(이중 로깅 방지).
func (r *userRepository) RequestRecovery(ctx context.Context, email string) error {
	req, err := r.jsonReq(ctx, http.MethodPost, "/auth/v1/recover", map[string]any{"email": email}, "")
	if err != nil {
		return err
	}
	status, err := r.doDrain(req)
	if err != nil {
		return err
	}
	if status >= 400 {
		return fmt.Errorf("requestRecovery: status %d", status)
	}
	return nil
}

// VerifyRecovery는 메일로 받은 6자리 코드를 검증하고 recovery 세션 토큰을 받는다.
// POST /auth/v1/verify (type=recovery). 이 토큰으로 ChangePassword를 이어서 호출한다.
func (r *userRepository) VerifyRecovery(ctx context.Context, email, code string) (string, error) {
	body := map[string]any{
		"type":  "recovery",
		"email": email,
		"token": code, // Supabase는 메일의 6자리 코드를 token 필드로 받는다
	}
	req, err := r.jsonReq(ctx, http.MethodPost, "/auth/v1/verify", body, "")
	if err != nil {
		return "", err
	}

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return "", err
	}
	switch {
	// 4xx → 코드 불일치·만료 (Supabase: 403 otp_expired 등)
	case resp.StatusCode >= 400 && resp.StatusCode < 500:
		slog.Warn("verifyRecovery rejected", "status", resp.StatusCode)
		return "", domain.ErrInvalidCode
	case resp.StatusCode >= 500:
		return "", fmt.Errorf("verifyRecovery: status %d", resp.StatusCode)
	}

	var session supabaseSession
	if err := json.Unmarshal(respBody, &session); err != nil {
		return "", err
	}
	return session.AccessToken, nil
}

// DeleteAccount는 DB 함수 delete_user_account를 RPC로 호출한다.
// 함수가 소유 trip + auth.users를 한 트랜잭션으로 지우므로 부분실패가 없다.
// service_role 전용 함수라 여기서만 service key를 사용한다.
func (r *userRepository) DeleteAccount(ctx context.Context, userID string) error {
	b, err := json.Marshal(map[string]any{"p_user_id": userID})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		r.supabaseURL+"/rest/v1/rpc/delete_user_account", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)

	status, err := r.doDrain(req)
	if err != nil {
		return err
	}
	if status != http.StatusNoContent && status != http.StatusOK {
		slog.Error("deleteAccount: unexpected status", "status", status, "user_id", userID)
		return fmt.Errorf("deleteAccount: status %d", status)
	}
	return nil
}

func (r *userRepository) callAuth(ctx context.Context, method, path string, body map[string]any, accessToken string) (*supabaseSession, error) {
	b, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	req, err := http.NewRequestWithContext(ctx, method, r.supabaseURL+path, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseAnonKey)
	if accessToken != "" {
		req.Header.Set("Authorization", "Bearer "+accessToken)
	}

	resp, err := r.httpClient.Do(req)
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
		var supaErr supabaseError
		if json.Unmarshal(respBody, &supaErr) == nil && supaErr.ErrorCode == "user_already_exists" {
			return nil, domain.ErrEmailExists
		}
		return nil, fmt.Errorf("supabase auth error: status %d", resp.StatusCode)
	}

	var session supabaseSession
	if err := json.Unmarshal(respBody, &session); err != nil {
		return nil, err
	}
	return &session, nil
}
