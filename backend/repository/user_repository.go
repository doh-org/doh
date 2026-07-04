package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
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
		ID string `json:"id"`
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

func (r *userRepository) SignupWithEmail(ctx context.Context, email, password, nickname string) (string, string, string, error) {
	body := map[string]any{
		"email":    email,
		"password": password,
		"data":     map[string]string{"nickname": nickname},
	}
	session, err := r.callAuth(ctx, http.MethodPost, "/auth/v1/signup", body, "")
	if err != nil {
		return "", "", "", err
	}
	return session.AccessToken, session.RefreshToken, session.User.ID, nil
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

// ChangePassword는 사용자 JWT로 본인 비밀번호를 변경한다. PUT /auth/v1/user.
func (r *userRepository) ChangePassword(ctx context.Context, accessToken, newPassword string) error {
	b, err := json.Marshal(map[string]any{"password": newPassword})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPut, r.supabaseURL+"/auth/v1/user", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Authorization", "Bearer "+accessToken)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusOK {
		slog.Error("changePassword: unexpected status", "status", resp.StatusCode)
		return domain.ErrAuthFailed
	}
	return nil
}

// RequestRecovery는 비밀번호 재설정 메일 발송을 요청한다. POST /auth/v1/recover.
func (r *userRepository) RequestRecovery(ctx context.Context, email string) error {
	b, err := json.Marshal(map[string]any{"email": email})
	if err != nil {
		return err
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, r.supabaseURL+"/auth/v1/recover", bytes.NewReader(b))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("apikey", r.supabaseAnonKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode >= 400 {
		slog.Error("requestRecovery: unexpected status", "status", resp.StatusCode)
		return fmt.Errorf("requestRecovery: status %d", resp.StatusCode)
	}
	return nil
}

// DeleteOwnedTrips는 사용자 JWT로 본인 소유 trip을 하드삭제한다.
// RLS trips_delete_owner로 본인 trip만 삭제되며, 자식은 FK CASCADE로 정리된다.
func (r *userRepository) DeleteOwnedTrips(ctx context.Context, accessToken, userID string) error {
	url := fmt.Sprintf("%s/rest/v1/trips?owner_id=eq.%s", r.supabaseURL, userID)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Authorization", "Bearer "+accessToken)
	req.Header.Set("Prefer", "return=minimal")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		slog.Error("deleteOwnedTrips: unexpected status", "status", resp.StatusCode, "user_id", userID)
		return fmt.Errorf("deleteOwnedTrips: status %d", resp.StatusCode)
	}
	return nil
}

// DeleteAuthUser는 service_role admin API로 auth.users 행을 hard delete한다.
// service_role key는 RLS를 전면 우회하므로 이 메서드에서만 사용한다.
func (r *userRepository) DeleteAuthUser(ctx context.Context, userID string) error {
	url := fmt.Sprintf("%s/auth/v1/admin/users/%s", r.supabaseURL, userID)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, url, nil)
	if err != nil {
		return err
	}
	req.Header.Set("apikey", r.supabaseServiceKey)
	req.Header.Set("Authorization", "Bearer "+r.supabaseServiceKey)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusOK && resp.StatusCode != http.StatusNoContent {
		slog.Error("deleteAuthUser: unexpected status", "status", resp.StatusCode, "user_id", userID)
		return fmt.Errorf("deleteAuthUser: status %d", resp.StatusCode)
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
