package controller

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"doh/backend/api/middleware"
	"doh/backend/domain"
)

type AuthController struct {
	authUsecase domain.AuthUsecase
}

func NewAuthController(au domain.AuthUsecase) *AuthController {
	return &AuthController{authUsecase: au}
}

// 요청 본문 상한. Turnstile 토큰(최대 2048자)이 포함돼도 여유 있는 크기.
const maxAuthBodyBytes = 4096

// bindJSON은 본문 크기를 제한하고 JSON을 req에 바인딩한다.
// 실패 시 413/400 응답을 직접 쓰고 false를 반환한다(호출부는 가드절로 종료).
func bindJSON(c *gin.Context, req any) bool {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxAuthBodyBytes)

	if err := c.ShouldBindJSON(req); err != nil {
		var maxErr *http.MaxBytesError
		// 크기 초과 → 413, 그 외 파싱 실패 → 400
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return false
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return false
	}
	return true
}

func (ac *AuthController) Signup(c *gin.Context) {
	var req domain.SignupRequest
	if !bindJSON(c, &req) {
		return
	}

	resp, err := ac.authUsecase.Signup(c.Request.Context(), req)
	if err != nil {
		ac.handleError(c, err)
		return
	}
	c.JSON(http.StatusCreated, resp)
}

func (ac *AuthController) Login(c *gin.Context) {
	var req domain.LoginRequest
	if !bindJSON(c, &req) {
		return
	}

	resp, err := ac.authUsecase.Login(c.Request.Context(), req)
	if err != nil {
		ac.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (ac *AuthController) Logout(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	if err := ac.authUsecase.Logout(c.Request.Context(), token); err != nil {
		slog.Error("logout error", "err", err)
	}
	c.Status(http.StatusNoContent)
}

func (ac *AuthController) Me(c *gin.Context) {
	userID := c.GetString(middleware.UserIDKey)
	email := c.GetString(middleware.UserEmailKey)
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")

	user, err := ac.authUsecase.Me(c.Request.Context(), userID, email, token)
	if err != nil {
		slog.Error("me error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (ac *AuthController) ChangePassword(c *gin.Context) {
	var req domain.ChangePasswordRequest
	if !bindJSON(c, &req) {
		return
	}

	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	email := c.GetString(middleware.UserEmailKey) // 재인증(현재 비번 확인)에 사용
	if err := ac.authUsecase.ChangePassword(c.Request.Context(), token, email, req); err != nil {
		ac.handleError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (ac *AuthController) Recover(c *gin.Context) {
	var req domain.RecoverRequest
	if !bindJSON(c, &req) {
		return
	}

	if err := ac.authUsecase.Recover(c.Request.Context(), req); err != nil {
		ac.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"message": "재설정 메일을 보냈습니다."})
}

func (ac *AuthController) DeleteMe(c *gin.Context) {
	userID := c.GetString(middleware.UserIDKey)

	// 실패 상세(user_id 포함)는 repository에서 이미 로깅됨 → 여기선 매핑만
	if err := ac.authUsecase.DeleteAccount(c.Request.Context(), userID); err != nil {
		ac.handleError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (ac *AuthController) handleError(c *gin.Context, err error) {
	var ve *domain.ValidationError
	switch {
	case errors.As(err, &ve):
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, domain.ErrCaptcha):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "보안 인증에 실패했습니다."})
	case errors.Is(err, domain.ErrEmailExists):
		c.JSON(http.StatusConflict, gin.H{"error": "이미 존재하는 이메일입니다."})
	case errors.Is(err, domain.ErrAuthFailed):
		c.JSON(http.StatusUnauthorized, gin.H{"error": "이메일 또는 비밀번호를 확인해주세요."})
	default:
		slog.Error("unexpected auth error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
