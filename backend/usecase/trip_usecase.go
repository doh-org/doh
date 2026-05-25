package usecase

import (
	"context"
	"errors"
	"strings"
	"time"

	"doh/backend/domain"
)

type tripUsecase struct {
	tripRepo domain.TripRepository
}

func NewTripUsecase(tripRepo domain.TripRepository) domain.TripUsecase {
	return &tripUsecase{tripRepo: tripRepo}
}

func (u *tripUsecase) GetTrips(ctx context.Context, token string) ([]domain.Trip, error) {
	return u.tripRepo.GetTrips(ctx, token)
}

func (u *tripUsecase) GetTrip(ctx context.Context, token, tripID string) (*domain.Trip, error) {
	return u.tripRepo.GetTrip(ctx, token, tripID)
}

func (u *tripUsecase) UpdateTrip(ctx context.Context, userID, token, tripID string, input domain.UpdateTripInput) (*domain.Trip, error) {
	trip, err := u.tripRepo.GetTrip(ctx, token, tripID)
	if err != nil {
		if errors.Is(err, domain.ErrNotFound) {
			return nil, domain.ErrNotFound
		}
		return nil, err
	}

	if trip.OwnerID != userID {
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
		return nil, err
	}

	return u.tripRepo.UpdateTrip(ctx, token, tripID, input)
}

func (u *tripUsecase) DeleteTrip(ctx context.Context, userID, token, tripID string) error {
	trip, err := u.tripRepo.GetTrip(ctx, token, tripID)
	if err != nil {
		return err
	}

	if trip.OwnerID != userID {
		return domain.ErrForbidden
	}

	return u.tripRepo.DeleteTrip(ctx, token, tripID)
}

func validateTripDates(input domain.UpdateTripInput, trip *domain.Trip) error {
	const layout = "2006-01-02"

	if input.StartDate != nil {
		if _, err := time.Parse(layout, *input.StartDate); err != nil {
			return &domain.ValidationError{Message: "시작일 형식이 올바르지 않습니다. (예: 2026-07-01)"}
		}
	}
	if input.EndDate != nil {
		if _, err := time.Parse(layout, *input.EndDate); err != nil {
			return &domain.ValidationError{Message: "종료일 형식이 올바르지 않습니다. (예: 2026-07-01)"}
		}
	}

	effectiveStart := coalesceDate(input.StartDate, trip.StartDate)
	effectiveEnd := coalesceDate(input.EndDate, trip.EndDate)
	if effectiveStart == nil || effectiveEnd == nil {
		return nil
	}

	s, _ := time.Parse(layout, *effectiveStart)
	e, _ := time.Parse(layout, *effectiveEnd)
	if e.Before(s) {
		return &domain.ValidationError{Message: "종료일은 시작일보다 이후여야 합니다."}
	}
	return nil
}

func coalesceDate(a, b *string) *string {
	if a != nil {
		return a
	}
	return b
}
