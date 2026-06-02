package controller

import (
	"errors"
	"log/slog"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"doh/backend/domain"
)

type CategoryController struct {
	categoryUsecase domain.CategoryUsecase
}

func NewCategoryController(cu domain.CategoryUsecase) *CategoryController {
	return &CategoryController{categoryUsecase: cu}
}

func (cc *CategoryController) GetCategories(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")

	categories, err := cc.categoryUsecase.GetCategories(c.Request.Context(), token, tripID)
	if err != nil {
		cc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, categories)
}

func (cc *CategoryController) handleError(c *gin.Context, err error) {
	var ve *domain.ValidationError
	switch {
	case errors.As(err, &ve):
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, domain.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "리소스를 찾을 수 없습니다."})
	case errors.Is(err, domain.ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "권한이 없습니다."})
	default:
		slog.Error("category error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
