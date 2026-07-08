package domain

import (
	"context"
	"errors"
	"time"
)

var (
	ErrAuthFailed  = errors.New("auth failed")
	ErrEmailExists = errors.New("email already exists")
	ErrInvalidCode = errors.New("invalid recovery code") // 인증코드 불일치·만료
)

type ValidationError struct{ Message string }

func (e *ValidationError) Error() string { return e.Message }

type SignupRequest struct {
	Email        string `json:"email"`
	Password     string `json:"password"`
	Nickname string `json:"nickname"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type ChangePasswordRequest struct {
	CurrentPassword string `json:"current_password"`
	NewPassword     string `json:"new_password"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type RecoverRequest struct {
	Email string `json:"email"`
}

// VerifyRecoveryCodeRequest는 메일로 받은 6자리 코드를 즉시 검증한다.
type VerifyRecoveryCodeRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// RecoverySessionResponse는 코드 검증 성공 시 발급되는 recovery 세션 토큰.
// /auth/recovery-password 전용 — 다른 API 인증에 쓰지 않는다.
type RecoverySessionResponse struct {
	AccessToken string `json:"access_token"`
}

// RecoveryPasswordRequest는 recovery 세션으로 새 비밀번호를 설정한다.
type RecoveryPasswordRequest struct {
	AccessToken string `json:"access_token"`
	NewPassword string `json:"new_password"`
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
	RefreshSession(ctx context.Context, refreshToken string) (accessToken, newRefreshToken, userID, email string, err error)
	Logout(ctx context.Context, accessToken string) error
	GetProfile(ctx context.Context, userID, email, accessToken string) (*UserResponse, error)
	ChangePassword(ctx context.Context, accessToken, newPassword string) error
	RequestRecovery(ctx context.Context, email string) error
	VerifyRecovery(ctx context.Context, email, code string) (accessToken string, err error)
	DeleteAccount(ctx context.Context, userID string) error
}

type AuthUsecase interface {
	Signup(ctx context.Context, req SignupRequest) (*AuthResponse, error)
	Login(ctx context.Context, req LoginRequest) (*AuthResponse, error)
	Refresh(ctx context.Context, refreshToken string) (*AuthResponse, error)
	Logout(ctx context.Context, accessToken string) error
	Me(ctx context.Context, userID, email, accessToken string) (*UserResponse, error)
	ChangePassword(ctx context.Context, accessToken, email string, req ChangePasswordRequest) error
	Recover(ctx context.Context, req RecoverRequest) error
	VerifyRecoveryCode(ctx context.Context, req VerifyRecoveryCodeRequest) (*RecoverySessionResponse, error)
	ResetRecoveryPassword(ctx context.Context, req RecoveryPasswordRequest) error
	DeleteAccount(ctx context.Context, userID string) error
}
