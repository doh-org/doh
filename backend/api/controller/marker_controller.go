package controller

import (
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"doh/backend/api/middleware"
	"doh/backend/domain"
)

type MarkerController struct {
	markerUsecase domain.MarkerUsecase
}

func NewMarkerController(mu domain.MarkerUsecase) *MarkerController {
	return &MarkerController{markerUsecase: mu}
}

// GetMarkers는 day 마커 목록 또는 단건을 분기 반환함.
// :markerId가 정수면 day 목록(?sort=, day=0=미정), 그 외(UUID)면 단건 마커.
func (mc *MarkerController) GetMarkers(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	param := c.Param("markerId")
	sort := c.Query("sort")

	day, atoiErr := strconv.Atoi(param)
	slog.Info("[marker] GetMarkers: 분기",
		"tripID", tripID, "param", param, "sort", sort,
		"isDay", atoiErr == nil, "day", day)

	if atoiErr == nil {
		markers, err := mc.markerUsecase.GetMarkersByDay(c.Request.Context(), token, tripID, day, sort)
		if err != nil {
			mc.handleError(c, err)
			return
		}
		c.JSON(http.StatusOK, markers)
		return
	}

	marker, err := mc.markerUsecase.GetMarker(c.Request.Context(), token, tripID, param)
	if err != nil {
		mc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, marker)
}

func (mc *MarkerController) CreateMarker(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4*1024)

	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	userID := c.GetString(middleware.UserIDKey)

	var input domain.CreateMarkerInput
	if err := c.ShouldBindJSON(&input); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	marker, err := mc.markerUsecase.CreateMarker(c.Request.Context(), token, tripID, userID, input)
	if err != nil {
		mc.handleError(c, err)
		return
	}
	c.JSON(http.StatusCreated, marker)
}

func (mc *MarkerController) UpdateMarker(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4*1024)

	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	markerID := c.Param("markerId")
	userID := c.GetString(middleware.UserIDKey)

	var input domain.UpdateMarkerInput
	if err := c.ShouldBindJSON(&input); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	marker, err := mc.markerUsecase.UpdateMarker(c.Request.Context(), token, tripID, markerID, userID, input)
	if err != nil {
		mc.handleError(c, err)
		return
	}
	if marker == nil {
		c.Status(http.StatusNoContent)
		return
	}
	c.JSON(http.StatusOK, marker)
}

func (mc *MarkerController) DeleteMarker(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	markerID := c.Param("markerId")

	if err := mc.markerUsecase.DeleteMarker(c.Request.Context(), token, tripID, markerID); err != nil {
		mc.handleError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (mc *MarkerController) handleError(c *gin.Context, err error) {
	var ve *domain.ValidationError
	switch {
	case errors.As(err, &ve):
		slog.Warn("[marker] 400 검증 실패", "msg", ve.Message)
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, domain.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "리소스를 찾을 수 없습니다."})
	case errors.Is(err, domain.ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "권한이 없습니다."})
	default:
		slog.Error("marker error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
