package controller

import (
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"doh/backend/domain"
)

type RouteController struct {
	routeUsecase domain.RouteUsecase
}

func NewRouteController(ru domain.RouteUsecase) *RouteController {
	return &RouteController{routeUsecase: ru}
}

// PATCH /trips/:tripId/days/:dayIndex/markers/:markerId — stop 수정(방문시간·이동수단)
func (rc *RouteController) UpdateStop(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4*1024)

	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	markerID := c.Param("markerId")
	day, ok := parseDayIndex(c)
	if !ok {
		return
	}

	var input domain.UpdateStopInput
	if err := c.ShouldBindJSON(&input); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	stop, err := rc.routeUsecase.UpdateStop(c.Request.Context(), token, tripID, day, markerID, input)
	if err != nil {
		rc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, stop)
}

// PATCH /trips/:tripId/days/:dayIndex/reorder — Day 마커 순서 변경
func (rc *RouteController) ReorderDay(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 16*1024)

	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")
	day, ok := parseDayIndex(c)
	if !ok {
		return
	}

	var input domain.ReorderInput
	if err := c.ShouldBindJSON(&input); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	n, err := rc.routeUsecase.ReorderDay(c.Request.Context(), token, tripID, day, input.MarkerIDs)
	if err != nil {
		rc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, gin.H{"reordered": n})
}

// parseDayIndex는 경로의 :dayIndex를 정수로 변환한다. 실패 시 400 응답 후 false.
func parseDayIndex(c *gin.Context) (int, bool) {
	day, err := strconv.Atoi(c.Param("dayIndex"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 day 값입니다."})
		return 0, false
	}
	return day, true
}

func (rc *RouteController) handleError(c *gin.Context, err error) {
	var ve *domain.ValidationError
	switch {
	case errors.As(err, &ve):
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, domain.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "리소스를 찾을 수 없습니다."})
	case errors.Is(err, domain.ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "권한이 없습니다."})
	default:
		slog.Error("route error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
