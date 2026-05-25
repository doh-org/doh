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

type TripController struct {
	tripUsecase domain.TripUsecase
}

func NewTripController(tu domain.TripUsecase) *TripController {
	return &TripController{tripUsecase: tu}
}

func (tc *TripController) GetTrips(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")

	trips, err := tc.tripUsecase.GetTrips(c.Request.Context(), token)
	if err != nil {
		tc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, trips)
}

func (tc *TripController) GetTrip(c *gin.Context) {
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")

	trip, err := tc.tripUsecase.GetTrip(c.Request.Context(), token, tripID)
	if err != nil {
		tc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, trip)
}

func (tc *TripController) UpdateTrip(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4096)

	var input domain.UpdateTripInput
	if err := c.ShouldBindJSON(&input); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}

	userID := c.GetString(middleware.UserIDKey)
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")

	trip, err := tc.tripUsecase.UpdateTrip(c.Request.Context(), userID, token, tripID, input)
	if err != nil {
		tc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, trip)
}

func (tc *TripController) DeleteTrip(c *gin.Context) {
	userID := c.GetString(middleware.UserIDKey)
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	tripID := c.Param("tripId")

	if err := tc.tripUsecase.DeleteTrip(c.Request.Context(), userID, token, tripID); err != nil {
		tc.handleError(c, err)
		return
	}
	c.Status(http.StatusNoContent)
}

func (tc *TripController) handleError(c *gin.Context, err error) {
	var ve *domain.ValidationError
	switch {
	case errors.As(err, &ve):
		c.JSON(http.StatusBadRequest, gin.H{"error": ve.Message})
	case errors.Is(err, domain.ErrNotFound):
		c.JSON(http.StatusNotFound, gin.H{"error": "여행을 찾을 수 없습니다."})
	case errors.Is(err, domain.ErrForbidden):
		c.JSON(http.StatusForbidden, gin.H{"error": "권한이 없습니다."})
	default:
		slog.Error("unexpected trip error", "err", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "서버 오류가 발생했습니다."})
	}
}
