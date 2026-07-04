package domain

import (
	"context"
	"errors"
	"time"
)

var (
	ErrCaptcha     = errors.New("captcha failed")
	ErrAuthFailed  = errors.New("auth failed")
	ErrEmailExists = errors.New("email already exists")
)

type ValidationError struct{ Message string }

func (e *ValidationError) Error() string { return e.Message }

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

type ChangePasswordRequest struct {
	NewPassword string `json:"new_password"`
}

type RecoverRequest struct {
	Email        string `json:"email"`
	CaptchaToken string `json:"captcha_token"`
}

type UserResponse struct {
	UserID    string    `json:"user_id"`
	Email     string    `json:"email"`
	Nickname  string    `json:"nickname"`
	CreatedAt time.Time `json:"created_at"`
}

type AuthResponse struct {
	AccessToken  string       `json:"access_token"`
	RefreshToken string       `json:"refresh_token"`
	User         UserResponse `json:"user"`
}

type UserRepository interface {
	SignupWithEmail(ctx context.Context, email, password, nickname string) (accessToken, refreshToken, userID string, err error)
	LoginWithEmail(ctx context.Context, email, password string) (accessToken, refreshToken, userID string, err error)
	Logout(ctx context.Context, accessToken string) error
	GetProfile(ctx context.Context, userID, email, accessToken string) (*UserResponse, error)
	ChangePassword(ctx context.Context, accessToken, newPassword string) error
	RequestRecovery(ctx context.Context, email string) error
	DeleteOwnedTrips(ctx context.Context, accessToken, userID string) error
	DeleteAuthUser(ctx context.Context, userID string) error
}

type AuthUsecase interface {
	Signup(ctx context.Context, req SignupRequest) (*AuthResponse, error)
	Login(ctx context.Context, req LoginRequest) (*AuthResponse, error)
	Logout(ctx context.Context, accessToken string) error
	Me(ctx context.Context, userID, email, accessToken string) (*UserResponse, error)
	ChangePassword(ctx context.Context, accessToken string, req ChangePasswordRequest) error
	Recover(ctx context.Context, req RecoverRequest) error
	DeleteAccount(ctx context.Context, accessToken, userID string) error
}
