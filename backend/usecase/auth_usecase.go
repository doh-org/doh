package usecase

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"unicode"

	"doh/backend/domain"
)

type authUsecase struct {
	userRepo domain.UserRepository
}

func NewAuthUsecase(userRepo domain.UserRepository) domain.AuthUsecase {
	return &authUsecase{userRepo: userRepo}
}

// Signup은 이메일을 검증하고 확인 코드를 발송한다(1단계).
// 비번·닉네임은 여기서 받지 않는다 — 코드 검증 후 CompleteSignup에서 설정한다.
func (u *authUsecase) Signup(ctx context.Context, req domain.SignupRequest) error {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return err
	}
	err := u.userRepo.StartEmailSignup(ctx, req.Email)
	if err == nil {
		return nil
	}
	if !errors.Is(err, domain.ErrEmailExists) {
		return domain.ErrEmailSendFailed
	}
	cleaned, cleanErr := u.cleanupIncompleteSignup(ctx, req.Email)
	if cleanErr != nil || !cleaned {
		return domain.ErrEmailExists
	}
	if err := u.userRepo.StartEmailSignup(ctx, req.Email); err != nil {
		return domain.ErrEmailSendFailed
	}
	return nil
}

// cleanupIncompleteSignup은 프로필 없는 확정 계정(미완료 가입)을 삭제한다.
// 삭제했으면 true — 호출자가 signup을 재시도한다.
func (u *authUsecase) cleanupIncompleteSignup(ctx context.Context, email string) (bool, error) {
	userID, err := u.userRepo.FindAuthUserIDByEmail(ctx, email)
	if err != nil || userID == "" {
		return false, err
	}
	exists, err := u.userRepo.ProfileExists(ctx, userID)
	if err != nil || exists {
		return false, err
	}
	if err := u.userRepo.DeleteAuthUser(ctx, userID); err != nil {
		return false, err
	}
	return true, nil
}

// VerifySignup은 확인 코드를 검증하고 가입 세션 토큰을 발급한다(2단계).
// 코드는 검증 성공 시 소모된다(1회용). 이후 비번·닉네임 설정은 세션 토큰으로만 진행.
func (u *authUsecase) VerifySignup(ctx context.Context, req domain.VerifySignupRequest) (*domain.SignupSessionResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Code = strings.TrimSpace(req.Code)

	if err := validateEmail(req.Email); err != nil {
		return nil, err
	}
	if err := validateRecoveryCode(req.Code); err != nil {
		return nil, err
	}

	accessToken, err := u.userRepo.VerifySignupCode(ctx, req.Email, req.Code)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidCode) {
			return nil, domain.ErrInvalidCode
		}
		return nil, err
	}
	return &domain.SignupSessionResponse{AccessToken: accessToken}, nil
}

// CompleteSignup은 가입 세션으로 비번·닉네임을 설정하고 자동 로그인 세션을 발급한다(3단계).
// public.users 닉네임까지 갱신한 뒤, 설정된 비번으로 재로그인해 깨끗한 세션을 돌려준다.
func (u *authUsecase) CompleteSignup(ctx context.Context, req domain.CompleteSignupRequest) (*domain.AuthResponse, error) {
	req.Nickname = strings.TrimSpace(req.Nickname)

	if strings.TrimSpace(req.AccessToken) == "" {
		return nil, &domain.ValidationError{Message: "인증코드 확인을 먼저 진행해주세요."}
	}
	if err := validatePassword(req.Password); err != nil {
		return nil, err
	}
	if err := validateNickname(req.Nickname); err != nil {
		return nil, err
	}

	// 비번·닉네임(메타데이터) 설정. 세션 만료면 코드부터 다시 받게 안내(401→400).
	userID, email, err := u.userRepo.SetSignupCredentials(ctx, req.AccessToken, req.Password, sanitizeNickname(req.Nickname))
	if err != nil {
		if errors.Is(err, domain.ErrAuthFailed) {
			return nil, &domain.ValidationError{Message: "인증이 만료되었습니다. 코드를 다시 받아주세요."}
		}
		return nil, err
	}

	if err := u.userRepo.UpsertProfile(ctx, userID, sanitizeNickname(req.Nickname)); err != nil {
		return nil, domain.ErrAuthFailed
	}

	// 설정한 비번으로 재로그인 → 자동 로그인용 정식 세션 발급.
	accessToken, refreshToken, uid, err := u.userRepo.LoginWithEmail(ctx, email, req.Password)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}
	user, err := u.userRepo.GetProfile(ctx, uid, email, accessToken)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}

	return &domain.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

// ResendSignup은 확인 코드를 재발송한다. 계정 존재는 Signup 단계에서 이미 드러나므로
// 열거 방지 목적은 없지만, 발송 실패는 흡수한다(곧 재시도 가능).
func (u *authUsecase) ResendSignup(ctx context.Context, email string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := validateEmail(email); err != nil {
		return err
	}
	if err := u.userRepo.ResendSignup(ctx, email); err != nil {
		slog.Error("resend signup failed", "err", err) // 흡수: 곧 재시도 가능
	}
	return nil
}

func (u *authUsecase) Login(ctx context.Context, req domain.LoginRequest) (*domain.AuthResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return nil, err
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

// Refresh는 refresh 토큰으로 새 세션을 발급한다. 무효/만료 → 401.
func (u *authUsecase) Refresh(ctx context.Context, refreshToken string) (*domain.AuthResponse, error) {
	if strings.TrimSpace(refreshToken) == "" {
		return nil, &domain.ValidationError{Message: "refresh 토큰이 필요합니다."}
	}

	accessToken, newRefresh, userID, email, err := u.userRepo.RefreshSession(ctx, refreshToken)
	if err != nil {
		return nil, domain.ErrAuthFailed // 만료·무효·회전됨 → 재로그인 유도
	}

	user, err := u.userRepo.GetProfile(ctx, userID, email, accessToken)
	if err != nil {
		return nil, domain.ErrAuthFailed
	}

	return &domain.AuthResponse{
		AccessToken:  accessToken,
		RefreshToken: newRefresh,
		User:         *user,
	}, nil
}

func (u *authUsecase) Logout(ctx context.Context, accessToken string) error {
	return u.userRepo.Logout(ctx, accessToken)
}

func (u *authUsecase) Me(ctx context.Context, userID, email, accessToken string) (*domain.UserResponse, error) {
	return u.userRepo.GetProfile(ctx, userID, email, accessToken)
}

// ChangePassword는 현재 비밀번호 재확인 후 변경한다.
// Supabase PUT /auth/v1/user는 자체 재확인이 없어, 로그인 API로 재인증한다.
func (u *authUsecase) ChangePassword(ctx context.Context, accessToken, email string, req domain.ChangePasswordRequest) error {
	if strings.TrimSpace(req.CurrentPassword) == "" {
		return &domain.ValidationError{Message: "현재 비밀번호를 입력해주세요."}
	}
	if err := validatePassword(req.NewPassword); err != nil {
		return err
	}

	// 재인증: 실패 = 현재 비밀번호 불일치. 발급된 임시 세션 토큰은 사용하지 않고 버린다.
	if _, _, _, err := u.userRepo.LoginWithEmail(ctx, email, req.CurrentPassword); err != nil {
		return &domain.ValidationError{Message: "현재 비밀번호가 일치하지 않습니다."}
	}

	return u.userRepo.ChangePassword(ctx, accessToken, req.NewPassword)
}

// Recover는 재설정 메일을 요청한다. 사용자 열거 방지를 위해 repo 결과와 무관하게
// 입력 검증 실패만 에러로 반환하고 발송 실패는 흡수한다.
func (u *authUsecase) Recover(ctx context.Context, req domain.RecoverRequest) error {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))

	if err := validateEmail(req.Email); err != nil {
		return err
	}
	if err := u.userRepo.RequestRecovery(ctx, req.Email); err != nil {
		slog.Error("recover request failed", "err", err) // 흡수: 열거 방지
	}
	return nil
}

// VerifyRecoveryCode는 메일의 6자리 코드를 즉시 검증하고 recovery 세션을 발급한다.
// 코드는 검증 성공 시 소모된다(1회용) — 이후 비밀번호 설정은 세션 토큰으로만 진행.
func (u *authUsecase) VerifyRecoveryCode(ctx context.Context, req domain.VerifyRecoveryCodeRequest) (*domain.RecoverySessionResponse, error) {
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Code = strings.TrimSpace(req.Code)

	if err := validateEmail(req.Email); err != nil {
		return nil, err
	}
	if err := validateRecoveryCode(req.Code); err != nil {
		return nil, err
	}

	accessToken, err := u.userRepo.VerifyRecovery(ctx, req.Email, req.Code)
	if err != nil {
		if errors.Is(err, domain.ErrInvalidCode) {
			return nil, domain.ErrInvalidCode
		}
		return nil, err
	}
	return &domain.RecoverySessionResponse{AccessToken: accessToken}, nil
}

// ResetRecoveryPassword는 recovery 세션으로 비밀번호를 변경하고 세션을 폐기한다.
func (u *authUsecase) ResetRecoveryPassword(ctx context.Context, req domain.RecoveryPasswordRequest) error {
	if strings.TrimSpace(req.AccessToken) == "" {
		return &domain.ValidationError{Message: "인증코드 확인을 먼저 진행해주세요."}
	}
	if err := validatePassword(req.NewPassword); err != nil {
		return err
	}

	if err := u.userRepo.ChangePassword(ctx, req.AccessToken, req.NewPassword); err != nil {
		// 세션 만료·무효(401)는 코드부터 다시 받게 안내 → 401 아닌 400
		if errors.Is(err, domain.ErrAuthFailed) {
			return &domain.ValidationError{Message: "인증이 만료되었습니다. 코드를 다시 받아주세요."}
		}
		return err
	}
	// recovery 세션은 재설정 후 쓸모 없음 → 폐기 (실패해도 무시: 곧 만료됨)
	if err := u.userRepo.Logout(ctx, req.AccessToken); err != nil {
		slog.Warn("recovery session logout failed", "err", err)
	}
	return nil
}

// DeleteAccount는 DB 함수(delete_user_account) 단일 트랜잭션으로
// 소유 trip과 auth.users를 함께 삭제한다 → 부분실패 불가.
func (u *authUsecase) DeleteAccount(ctx context.Context, userID string) error {
	return u.userRepo.DeleteAccount(ctx, userID)
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

// 인증코드 형식: 숫자 6자리.
func validateRecoveryCode(code string) error {
	if len(code) != 6 {
		return &domain.ValidationError{Message: "인증코드는 6자리입니다."}
	}
	for _, r := range code {
		if !unicode.IsDigit(r) {
			return &domain.ValidationError{Message: "인증코드는 숫자만 입력해주세요."}
		}
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
