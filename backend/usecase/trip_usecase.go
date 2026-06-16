package usecase

import (
	"context"
	"errors"
	"log/slog"
	"strings"
	"time"

	"doh/backend/domain"
)

const tripDateLayout = "2006-01-02" // YYYY-MM-DD. Go 레퍼런스 포맷.

type tripUsecase struct {
	tripRepo domain.TripRepository
}

func NewTripUsecase(tripRepo domain.TripRepository) domain.TripUsecase {
	return &tripUsecase{tripRepo: tripRepo}
}

func (u *tripUsecase) CreateTrip(ctx context.Context, userID, token string, input domain.CreateTripInput) (*domain.Trip, error) {
	slog.Info("[trip] usecase.CreateTrip: start", "userID", userID, "title", input.Title)

	trimmed := strings.TrimSpace(input.Title)
	r := []rune(trimmed)
	if len(r) < 1 || len(r) > 50 {
		slog.Warn("[trip] usecase.CreateTrip: title validation failed", "title", trimmed)
		return nil, &domain.ValidationError{Message: "제목은 1자 이상 50자 이하여야 합니다."}
	}
	input.Title = trimmed

	if err := validateDateRange(input.StartDate, input.EndDate); err != nil {
		slog.Warn("[trip] usecase.CreateTrip: date validation failed", "err", err)
		return nil, err
	}

	slog.Info("[trip] usecase.CreateTrip: calling repo")
	trip, err := u.tripRepo.CreateTrip(ctx, token, userID, input)
	if err != nil {
		slog.Error("[trip] usecase.CreateTrip: repo error", "err", err)
		return nil, err
	}
	setTotalDays(trip)
	return trip, nil
}

func (u *tripUsecase) GetTrips(ctx context.Context, token string) ([]domain.Trip, error) {
	trips, err := u.tripRepo.GetTrips(ctx, token)
	if err != nil {
		return nil, err
	}
	for i := range trips {
		setTotalDays(&trips[i])
	}
	return trips, nil
}

func (u *tripUsecase) GetTrip(ctx context.Context, token, tripID string) (*domain.Trip, error) {
	trip, err := u.tripRepo.GetTrip(ctx, token, tripID)
	if err != nil {
		return nil, err
	}
	setTotalDays(trip)
	return trip, nil
}

func (u *tripUsecase) UpdateTrip(ctx context.Context, userID, token, tripID string, input domain.UpdateTripInput) (*domain.Trip, error) {
	slog.Info("[trip] usecase.UpdateTrip: start", "userID", userID, "tripID", tripID)

	trip, err := u.tripRepo.GetTrip(ctx, token, tripID)
	if err != nil {
		slog.Warn("[trip] usecase.UpdateTrip: getTrip failed", "err", err)
		if errors.Is(err, domain.ErrNotFound) {
			return nil, domain.ErrNotFound
		}
		return nil, err
	}

	if trip.OwnerID != userID {
		slog.Warn("[trip] usecase.UpdateTrip: forbidden", "ownerID", trip.OwnerID, "userID", userID)
		return nil, domain.ErrForbidden
	}

	if input.Title != nil {
		trimmed := strings.TrimSpace(*input.Title)
		r := []rune(trimmed)
		if len(r) < 1 || len(r) > 50 {
			return nil, &domain.ValidationError{Message: "제목은 1자 이상 50자 이하여야 합니다."}
		}
		input.Title = &trimmed
	}

	if err := validateTripDates(input, trip); err != nil {
		slog.Warn("[trip] usecase.UpdateTrip: date validation failed", "err", err)
		return nil, err
	}

	slog.Info("[trip] usecase.UpdateTrip: calling repo", "tripID", tripID)
	updated, err := u.tripRepo.UpdateTrip(ctx, token, tripID, input)
	if err != nil {
		return nil, err
	}
	setTotalDays(updated)
	return updated, nil
}

func (u *tripUsecase) DeleteTrip(ctx context.Context, userID, token, tripID string) error {
	slog.Info("[trip] usecase.DeleteTrip: start", "userID", userID, "tripID", tripID)

	trip, err := u.tripRepo.GetTrip(ctx, token, tripID)
	if err != nil {
		slog.Warn("[trip] usecase.DeleteTrip: getTrip failed", "err", err)
		return err
	}

	if trip.OwnerID != userID {
		slog.Warn("[trip] usecase.DeleteTrip: forbidden", "ownerID", trip.OwnerID, "userID", userID)
		return domain.ErrForbidden
	}

	slog.Info("[trip] usecase.DeleteTrip: calling repo", "tripID", tripID)
	return u.tripRepo.DeleteTrip(ctx, token, tripID)
}

func validateTripDates(input domain.UpdateTripInput, trip *domain.Trip) error {
	if err := validateDateRange(input.StartDate, input.EndDate); err != nil {
		return err
	}
	effectiveStart := coalesceDate(input.StartDate, trip.StartDate)
	effectiveEnd := coalesceDate(input.EndDate, trip.EndDate)
	return validateDateRange(effectiveStart, effectiveEnd)
}

func validateDateRange(start, end *string) error {
	if start != nil {
		if _, err := time.Parse(tripDateLayout, *start); err != nil {
			return &domain.ValidationError{Message: "시작일 형식이 올바르지 않습니다. (예: 2026-07-01)"}
		}
	}
	if end != nil {
		if _, err := time.Parse(tripDateLayout, *end); err != nil {
			return &domain.ValidationError{Message: "종료일 형식이 올바르지 않습니다. (예: 2026-07-01)"}
		}
	}
	if start == nil || end == nil {
		return nil
	}
	s, _ := time.Parse(tripDateLayout, *start)
	e, _ := time.Parse(tripDateLayout, *end)
	if e.Before(s) {
		return &domain.ValidationError{Message: "종료일은 시작일보다 이후여야 합니다."}
	}
	return nil
}

// setTotalDays: 파생 일수 채움. both-nil→그대로(nil), one만→1, both→inclusive(+1).
func setTotalDays(t *domain.Trip) {
	if t == nil {
		return
	}
	hasStart, hasEnd := t.StartDate != nil, t.EndDate != nil
	if !hasStart && !hasEnd {
		return // null 유지
	}
	if hasStart != hasEnd {
		one := 1
		t.TotalDays = &one
		return
	}
	s, err1 := time.Parse(tripDateLayout, *t.StartDate)
	e, err2 := time.Parse(tripDateLayout, *t.EndDate)
	if err1 != nil || err2 != nil || e.Before(s) {
		return
	}
	days := int(e.Sub(s).Hours()/24) + 1
	t.TotalDays = &days
}

func coalesceDate(a, b *string) *string {
	if a != nil {
		return a
	}
	return b
}
