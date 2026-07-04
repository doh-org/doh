package usecase

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"unicode"

	"doh/backend/domain"
	"doh/backend/internal/captcha"
)

type authUsecase struct {
	userRepo     domain.UserRepository
	turnstileKey string
}

func NewAuthUsecase(userRepo domain.UserRepository, turnstileKey string) domain.AuthUsecase {
	return &authUsecase{userRepo: userRepo, turnstileKey: turnstileKey}
}

func (u *authUsecase) Signup(ctx context.Context, req domain.SignupRequest) (*domain.AuthResponse, error) {
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
		return nil, &domain.ValidationError{Message: "보안 인증 토큰이 필요합니다."}
	}

	if err := captcha.Verify(u.turnstileKey, req.CaptchaToken); err != nil {
		slog.Warn("signup captcha failed", "err", err)
		return nil, domain.ErrCaptcha
	}

	// nickname을 raw_user_meta_data에 포함 → 트리거가 public.users에 자동 INSERT
	accessToken, refreshToken, userID, err := u.userRepo.SignupWithEmail(ctx, req.Email, req.Password, sanitizeNickname(req.Nickname))
	if err != nil {
		if errors.Is(err, domain.ErrEmailExists) {
			return nil, domain.ErrEmailExists
		}
		return nil, domain.ErrAuthFailed
	}

	user, err := u.userRepo.GetProfile(ctx, userID, req.Email, accessToken)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}

	return &domain.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (u *authUsecase) Login(ctx context.Context, req domain.LoginRequest) (*domain.AuthResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return nil, err
	}
	if strings.TrimSpace(req.CaptchaToken) == "" {
		return nil, &domain.ValidationError{Message: "보안 인증 토큰이 필요합니다."}
	}

	if err := captcha.Verify(u.turnstileKey, req.CaptchaToken); err != nil {
		slog.Warn("login captcha failed", "err", err)
		return nil, domain.ErrCaptcha
	}

	accessToken, refreshToken, userID, err := u.userRepo.LoginWithEmail(ctx, req.Email, req.Password)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}

	user, err := u.userRepo.GetProfile(ctx, userID, req.Email, accessToken)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}

	return &domain.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (u *authUsecase) Logout(ctx context.Context, accessToken string) error {
	return u.userRepo.Logout(ctx, accessToken)
}

func (u *authUsecase) Me(ctx context.Context, userID, email, accessToken string) (*domain.UserResponse, error) {
	return u.userRepo.GetProfile(ctx, userID, email, accessToken)
}

func (u *authUsecase) ChangePassword(ctx context.Context, accessToken string, req domain.ChangePasswordRequest) error {
	if err := validatePassword(req.NewPassword); err != nil {
		return err
	}
	return u.userRepo.ChangePassword(ctx, accessToken, req.NewPassword)
}

// Recover는 재설정 메일을 요청한다. 사용자 열거 방지를 위해 repo 결과와 무관하게
// captcha/검증 실패만 에러로 반환하고 발송 실패는 흡수한다.
func (u *authUsecase) Recover(ctx context.Context, req domain.RecoverRequest) error {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return err
	}
	if strings.TrimSpace(req.CaptchaToken) == "" {
		return &domain.ValidationError{Message: "보안 인증 토큰이 필요합니다."}
	}
	if err := captcha.Verify(u.turnstileKey, req.CaptchaToken); err != nil {
		slog.Warn("recover captcha failed", "err", err)
		return domain.ErrCaptcha
	}

	if err := u.userRepo.RequestRecovery(ctx, req.Email); err != nil {
		slog.Error("recover request failed", "err", err) // 흡수: 열거 방지
	}
	return nil
}

// DeleteAccount는 본인 owner trip을 먼저 삭제(사용자 JWT+RLS)한 뒤
// service_role로 auth.users를 삭제한다. 1단계 실패 시 2단계는 수행하지 않는다.
func (u *authUsecase) DeleteAccount(ctx context.Context, accessToken, userID string) error {
	if err := u.userRepo.DeleteOwnedTrips(ctx, accessToken, userID); err != nil {
		return err
	}
	return u.userRepo.DeleteAuthUser(ctx, userID)
}

// --- 입력 검증 헬퍼 ---

func validateEmail(email string) error {
	atIdx := strings.Index(email, "@")
	if atIdx < 1 || strings.Count(email, "@") != 1 {
		return &domain.ValidationError{Message: "올바른 이메일 형식이 아닙니다."}
	}
	emailDomain := email[atIdx+1:]
	dotIdx := strings.LastIndex(emailDomain, ".")
	if dotIdx < 1 || len(emailDomain[dotIdx+1:]) < 2 {
		return &domain.ValidationError{Message: "올바른 이메일 형식이 아닙니다."}
	}
	return nil
}

func validatePassword(password string) error {
	if len(password) < 8 {
		return &domain.ValidationError{Message: "비밀번호는 8자 이상이어야 합니다."}
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
		return &domain.ValidationError{Message: "비밀번호에 대문자가 포함되어야 합니다."}
	}
	if !hasLower {
		return &domain.ValidationError{Message: "비밀번호에 소문자가 포함되어야 합니다."}
	}
	if !hasDigit {
		return &domain.ValidationError{Message: "비밀번호에 숫자가 포함되어야 합니다."}
	}
	return nil
}

func validateNickname(nickname string) error {
	if len([]rune(nickname)) < 1 {
		return &domain.ValidationError{Message: "닉네임을 입력해주세요."}
	}
	if len([]rune(nickname)) > 50 {
		return &domain.ValidationError{Message: "닉네임은 50자 이하여야 합니다."}
	}
	return nil
}

func sanitizeNickname(s string) string {
	s = strings.ReplaceAll(s, "<", "")
	s = strings.ReplaceAll(s, ">", "")
	s = strings.ReplaceAll(s, "&", "")
	s = strings.ReplaceAll(s, `"`, "")
	return strings.TrimSpace(s)
}
