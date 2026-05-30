package auth

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) Signup(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 1024)

	var req SignupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	resp, err := h.svc.Signup(c.Request.Context(), req)
	if err != nil {
		h.handleError(c, err)
		return
	}
	c.JSON(http.StatusCreated, resp)
}

func (h *Handler) Login(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 1024)

	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	resp, err := h.svc.Login(c.Request.Context(), req)
	if err != nil {
		h.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *Handler) Logout(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	if err := h.svc.Logout(c.Request.Context(), token); err != nil {
		slog.Error("logout error", "err", err)
	}
	c.Status(http.StatusNoContent)
}

func (h *Handler) Me(c *gin.Context) {
	userID := c.GetString("user_id")
	email := c.GetString("user_email")
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")

	user, err := h.svc.Me(c.Request.Context(), userID, email, token)
	if err != nil {
		slog.Error("me error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
		return
	}
	c.JSON(http.StatusOK, user)
}

func (h *Handler) handleError(c *gin.Context, err error) {
	var ve *ValidationError
	switch {
	case errors.As(err, &ve):
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, ErrCaptcha):
		c.JSON(http.StatusUnprocessableEntity, gin.H{"error": "보안 인증에 실패했습니다."})
	case errors.Is(err, ErrEmailExists):
		c.JSON(http.StatusConflict, gin.H{"error": "이미 존재하는 이메일입니다."})
	case errors.Is(err, ErrAuthFailed):
		c.JSON(http.StatusUnauthorized, gin.H{"error": "이메일 또는 비밀번호를 확인해주세요."})
	default:
		slog.Error("unexpected auth error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
