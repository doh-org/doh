package usecase

import (
	"context"
	"log/slog"
	"strings"

	"doh/backend/domain"
)

type markerUsecase struct {
	markerRepo domain.MarkerRepository
	tripRepo   domain.TripRepository
}

func NewMarkerUsecase(markerRepo domain.MarkerRepository, tripRepo domain.TripRepository) domain.MarkerUsecase {
	return &markerUsecase{markerRepo: markerRepo, tripRepo: tripRepo}
}

func (u *markerUsecase) CreateMarker(ctx context.Context, token, tripID, userID string, input domain.CreateMarkerInput) (*domain.Marker, error) {
	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		return nil, err
	}

	name := strings.TrimSpace(input.Name)
	if len(name) == 0 {
		return nil, &domain.ValidationError{Message: "장소명은 필수입니다."}
	}
	if len([]rune(name)) > 100 {
		return nil, &domain.ValidationError{Message: "장소명은 100자 이하여야 합니다."}
	}
	input.Name = name

	if !domain.ValidSources[input.Source] {
		return nil, &domain.ValidationError{Message: "올바른 source 값이 아닙니다."}
	}
	if input.Latitude < -90 || input.Latitude > 90 {
		return nil, &domain.ValidationError{Message: "위도는 -90~90 범위여야 합니다."}
	}
	if input.Longitude < -180 || input.Longitude > 180 {
		return nil, &domain.ValidationError{Message: "경도는 -180~180 범위여야 합니다."}
	}
	for _, d := range input.VisitDays {
		if d < 1 {
			return nil, &domain.ValidationError{Message: "day_index는 1 이상이어야 합니다."}
		}
	}

	return u.markerRepo.CreateMarker(ctx, token, tripID, userID, input)
}

// GetMarkersByDay는 day 마커 목록을 반환함. day=0=미정, day>=1=그 day. day<0은 400.
func (u *markerUsecase) GetMarkersByDay(ctx context.Context, token, tripID string, day int, sort string) ([]domain.DayMarker, error) {
	slog.Info("[marker] usecase.GetMarkersByDay: start", "tripID", tripID, "day", day, "sort", sort)
	if day < 0 {
		slog.Warn("[marker] GetMarkersByDay: day 음수", "day", day)
		return nil, &domain.ValidationError{Message: "day는 0 이상이어야 합니다."}
	}
	s, err := parseStopSort(sort)
	if err != nil {
		slog.Warn("[marker] GetMarkersByDay: sort 검증 실패", "sort", sort)
		return nil, err
	}
	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		slog.Warn("[marker] GetMarkersByDay: GetTrip 실패", "tripID", tripID, "err", err)
		return nil, err
	}
	return u.markerRepo.GetMarkersByDay(ctx, token, tripID, day, s)
}

func (u *markerUsecase) GetMarker(ctx context.Context, token, tripID, markerID string) (*domain.Marker, error) {
	return u.markerRepo.GetMarker(ctx, token, tripID, markerID)
}

func (u *markerUsecase) UpdateMarker(ctx context.Context, token, tripID, markerID, userID string, input domain.UpdateMarkerInput) (*domain.Marker, error) {
	if _, err := u.markerRepo.GetMarker(ctx, token, tripID, markerID); err != nil {
		return nil, err
	}

	if input.Name != nil {
		name := strings.TrimSpace(*input.Name)
		if len(name) == 0 {
			return nil, &domain.ValidationError{Message: "장소명은 1자 이상이어야 합니다."}
		}
		if len([]rune(name)) > 100 {
			return nil, &domain.ValidationError{Message: "장소명은 100자 이하여야 합니다."}
		}
		input.Name = &name
	}

	hasLat := input.Latitude != nil
	hasLon := input.Longitude != nil
	if hasLat != hasLon {
		return nil, &domain.ValidationError{Message: "위도와 경도는 함께 전달해야 합니다."}
	}
	if hasLat {
		if *input.Latitude < -90 || *input.Latitude > 90 {
			return nil, &domain.ValidationError{Message: "위도는 -90~90 범위여야 합니다."}
		}
		if *input.Longitude < -180 || *input.Longitude > 180 {
			return nil, &domain.ValidationError{Message: "경도는 -180~180 범위여야 합니다."}
		}
	}
	if input.VisitDays != nil {
		for _, d := range *input.VisitDays {
			if d < 1 {
				return nil, &domain.ValidationError{Message: "day_index는 1 이상이어야 합니다."}
			}
		}
	}

	return u.markerRepo.UpdateMarker(ctx, token, tripID, markerID, userID, input)
}

func (u *markerUsecase) DeleteMarker(ctx context.Context, token, tripID, markerID string) error {
	if _, err := u.markerRepo.GetMarker(ctx, token, tripID, markerID); err != nil {
		return err
	}
	return u.markerRepo.DeleteMarker(ctx, token, tripID, markerID)
}
