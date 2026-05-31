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
	supabaseURL     string
	supabaseAnonKey string
	httpClient      *http.Client
}

func NewUserRepository(supabaseURL, anonKey string, client *http.Client) domain.UserRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &userRepository{
		supabaseURL:     supabaseURL,
		supabaseAnonKey: anonKey,
		httpClient:      client,
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
	user.Email = email
	return &user, nil
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
