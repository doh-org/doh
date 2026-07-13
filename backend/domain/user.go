package domain

import (
	"context"
	"errors"
	"time"
)

var (
	ErrAuthFailed      = errors.New("auth failed")
	ErrEmailExists     = errors.New("email already exists")
	ErrInvalidCode     = errors.New("invalid recovery code") // 인증코드 불일치·만료
	ErrEmailSendFailed = errors.New("confirmation email send failed")
)

type ValidationError struct{ Message string }

func (e *ValidationError) Error() string { return e.Message }

// SignupRequest는 회원가입 1단계 — 이메일로 인증 코드 발송만 요청한다.
// 비밀번호·닉네임은 코드 검증 후 3단계(CompleteSignup)에서 받는다.
type SignupRequest struct {
	Email string `json:"email"`
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

// VerifySignupRequest는 회원가입 2단계 — 메일의 6자리 코드를 검증한다.
// 성공하면 짧은 가입 세션 토큰이 발급되고, 3단계에서 이 토큰으로 비번·닉네임을 설정한다.
type VerifySignupRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

// SignupSessionResponse는 코드 검증 성공 시 발급되는 가입 세션 토큰.
// /auth/complete-signup 전용 — 앱은 메모리에만 보관한다.
type SignupSessionResponse struct {
	AccessToken string `json:"access_token"`
}

// CompleteSignupRequest는 회원가입 3단계 — 가입 세션으로 비번·닉네임을 설정한다.
type CompleteSignupRequest struct {
	AccessToken string `json:"access_token"`
	Password    string `json:"password"`
	Nickname    string `json:"nickname"`
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
	// StartEmailSignup은 이메일로 확인 코드 발송을 트리거한다(1단계).
	// 임시 비밀번호로 계정을 선생성하며, 실제 비번은 CompleteSignup에서 교체된다.
	StartEmailSignup(ctx context.Context, email string) error
	// VerifySignupCode는 확인 코드를 검증하고 계정을 확정한 뒤 가입 세션 토큰을 발급한다(2단계).
	VerifySignupCode(ctx context.Context, email, code string) (accessToken string, err error)
	// SetSignupCredentials는 가입 세션으로 비번·닉네임(메타데이터)을 설정한다(3단계).
	// 확정된 계정의 userID·email을 돌려준다(후속 프로필 갱신·로그인용).
	SetSignupCredentials(ctx context.Context, accessToken, password, nickname string) (userID, email string, err error)
	// UpsertProfile은 public.users 프로필을 생성/갱신한다(service key).
	UpsertProfile(ctx context.Context, userID, nickname string) error
	// FindAuthUserIDByEmail은 admin API로 이메일의 auth 계정 ID를 찾는다. 없으면 "".
	FindAuthUserIDByEmail(ctx context.Context, email string) (string, error)
	// ProfileExists는 public.users에 프로필 행이 있는지 확인한다(service key).
	ProfileExists(ctx context.Context, userID string) (bool, error)
	// DeleteAuthUser는 admin API로 auth 계정을 삭제한다(service key).
	DeleteAuthUser(ctx context.Context, userID string) error
	// ResendSignup은 확인 코드를 재발송한다.
	ResendSignup(ctx context.Context, email string) error
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
	// Signup은 이메일로 확인 코드를 발송한다(1단계). 세션은 아직 없다.
	Signup(ctx context.Context, req SignupRequest) error
	// VerifySignup은 확인 코드를 검증하고 가입 세션 토큰을 발급한다(2단계).
	VerifySignup(ctx context.Context, req VerifySignupRequest) (*SignupSessionResponse, error)
	// CompleteSignup은 가입 세션으로 비번·닉네임을 설정하고 자동 로그인 세션을 발급한다(3단계).
	CompleteSignup(ctx context.Context, req CompleteSignupRequest) (*AuthResponse, error)
	// ResendSignup은 확인 코드를 재발송한다.
	ResendSignup(ctx context.Context, email string) error
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
