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

func (tc *TripController) CreateTrip(c *gin.Context) {
	slog.Info("[trip] CreateTrip: handler reached")
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4096)

	var input domain.CreateTripInput
	if err := c.ShouldBindJSON(&input); err != nil {
		slog.Warn("[trip] CreateTrip: JSON bind failed", "err", err)
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			c.JSON(http.StatusRequestEntityTooLarge, gin.H{"error": "요청이 너무 큽니다."})
			return
		}
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 요청 형식입니다."})
		return
	}
	slog.Info("[trip] CreateTrip: bind ok", "title", input.Title)

	userID := c.GetString(middleware.UserIDKey)
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	slog.Info("[trip] CreateTrip: auth", "userID", userID, "hasToken", token != "")

	trip, err := tc.tripUsecase.CreateTrip(c.Request.Context(), userID, token, input)
	if err != nil {
		slog.Error("[trip] CreateTrip: usecase error", "err", err)
		tc.handleError(c, err)
		return
	}
	slog.Info("[trip] CreateTrip: success", "tripID", trip.ID)
	c.JSON(http.StatusCreated, trip)
}

func (tc *TripController) GetTrips(c *gin.Context) {
	slog.Info("[trip] GetTrips: handler reached")
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")

	trips, err := tc.tripUsecase.GetTrips(c.Request.Context(), token)
	if err != nil {
		tc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, trips)
}

func (tc *TripController) GetTrip(c *gin.Context) {
	tripID := c.Param("tripId")
	slog.Info("[trip] GetTrip: handler reached", "tripID", tripID)
	token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")

	trip, err := tc.tripUsecase.GetTrip(c.Request.Context(), token, tripID)
	if err != nil {
		tc.handleError(c, err)
		return
	}
	c.JSON(http.StatusOK, trip)
}

func (tc *TripController) UpdateTrip(c *gin.Context) {
	slog.Info("[trip] UpdateTrip: handler reached")
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, 4096)

	var input domain.UpdateTripInput
	if err := c.ShouldBindJSON(&input); err != nil {
		slog.Warn("[trip] UpdateTrip: JSON bind failed", "err", err)
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
	slog.Info("[trip] UpdateTrip: bind ok", "userID", userID, "tripID", tripID)

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
	slog.Info("[trip] DeleteTrip: handler reached", "userID", userID, "tripID", tripID)

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
