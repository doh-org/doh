package usecase

import (
	"context"
	"encoding/json"
	"time"

	"doh/backend/domain"
)

type routeUsecase struct {
	routeRepo domain.RouteRepository
	tripRepo  domain.TripRepository
}

func NewRouteUsecase(routeRepo domain.RouteRepository, tripRepo domain.TripRepository) domain.RouteUsecase {
	return &routeUsecase{routeRepo: routeRepo, tripRepo: tripRepo}
}

// visit_time 허용 포맷(시각만). Postgres time은 둘 다 수용.
var visitTimeLayouts = []string{"15:04:05", "15:04"}

func (u *routeUsecase) GetDayStops(ctx context.Context, token, tripID string, day int, sort string) ([]domain.RouteStop, error) {
	if day < 1 {
		return nil, &domain.ValidationError{Message: "day는 1 이상이어야 합니다."}
	}
	s, err := parseStopSort(sort)
	if err != nil {
		return nil, err
	}
	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		return nil, err
	}
	return u.routeRepo.GetDayStops(ctx, token, tripID, day, s)
}

// parseStopSort는 sort 쿼리를 정규화한다. 빈 값=기본(visit_time), 허용값 외 400.
func parseStopSort(sort string) (domain.StopSort, error) {
	switch sort {
	case "", string(domain.SortByVisitTime):
		return domain.SortByVisitTime, nil
	case string(domain.SortByOrder):
		return domain.SortByOrder, nil
	default:
		return "", &domain.ValidationError{Message: "sort는 visit_time 또는 order여야 합니다."}
	}
}

func (u *routeUsecase) UpdateStop(ctx context.Context, token, tripID string, day int, markerID string, input domain.UpdateStopInput) (*domain.RouteStop, error) {
	if day < 1 {
		return nil, &domain.ValidationError{Message: "day는 1 이상이어야 합니다."}
	}

	patch, err := buildStopPatch(input)
	if err != nil {
		return nil, err
	}

	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		return nil, err
	}

	stops, err := u.routeRepo.GetDayStops(ctx, token, tripID, day, domain.SortByVisitTime)
	if err != nil {
		return nil, err
	}
	target, maxOrder, found := locateStop(stops, markerID)
	if !found {
		return nil, domain.ErrNotFound // 그 Day에 미배정 → 먼저 visit_days로 배정
	}

	// 마지막 stop엔 다음 구간이 없으므로 이동수단 설정 불가(해제는 허용).
	if patch.SetTransport && patch.Transport != nil && target.Order == maxOrder {
		return nil, &domain.ValidationError{Message: "마지막 장소에는 이동수단을 설정할 수 없습니다."}
	}

	if patch.SetVisitTime || patch.SetTransport {
		if err := u.routeRepo.UpdateStop(ctx, token, tripID, day, markerID, patch); err != nil {
			return nil, err
		}
	}

	updated, err := u.routeRepo.GetDayStops(ctx, token, tripID, day, domain.SortByVisitTime)
	if err != nil {
		return nil, err
	}
	if s, _, ok := locateStop(updated, markerID); ok {
		return &s, nil
	}
	return nil, domain.ErrNotFound
}

func (u *routeUsecase) ReorderDay(ctx context.Context, token, tripID string, day int, markerIDs []string) (int, error) {
	if day < 1 {
		return 0, &domain.ValidationError{Message: "day는 1 이상이어야 합니다."}
	}
	if len(markerIDs) == 0 {
		return 0, &domain.ValidationError{Message: "marker_ids는 비어 있을 수 없습니다."}
	}

	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		return 0, err
	}

	stops, err := u.routeRepo.GetDayStops(ctx, token, tripID, day, domain.SortByVisitTime)
	if err != nil {
		return 0, err
	}
	if err := validateReorderSet(stops, markerIDs); err != nil {
		return 0, err
	}
	if len(stops) <= 1 {
		return len(stops), nil // no-op
	}
	if err := u.routeRepo.ReorderDay(ctx, token, tripID, day, markerIDs); err != nil {
		return 0, err
	}
	return len(markerIDs), nil
}

// buildStopPatch는 RawMessage 입력을 검증·정규화한다(미제공/null/값 3상태).
func buildStopPatch(input domain.UpdateStopInput) (domain.StopPatch, error) {
	var patch domain.StopPatch

	if len(input.VisitTime) > 0 {
		patch.SetVisitTime = true
		if string(input.VisitTime) != "null" {
			var s string
			if err := json.Unmarshal(input.VisitTime, &s); err != nil {
				return patch, &domain.ValidationError{Message: "visit_time 형식이 올바르지 않습니다."}
			}
			if !validVisitTime(s) {
				return patch, &domain.ValidationError{Message: "visit_time은 HH:MM 형식이어야 합니다."}
			}
			patch.VisitTime = &s
		}
	}

	if len(input.TransportToNext) > 0 {
		patch.SetTransport = true
		if string(input.TransportToNext) != "null" {
			var s string
			if err := json.Unmarshal(input.TransportToNext, &s); err != nil {
				return patch, &domain.ValidationError{Message: "transport_to_next 형식이 올바르지 않습니다."}
			}
			if !domain.ValidTransportModes[s] {
				return patch, &domain.ValidationError{Message: "이동수단은 car·foot·publictransit·bicycle 중 하나여야 합니다."}
			}
			patch.Transport = &s
		}
	}

	return patch, nil
}

func validVisitTime(s string) bool {
	for _, layout := range visitTimeLayouts {
		if _, err := time.Parse(layout, s); err == nil {
			return true
		}
	}
	return false
}

// locateStop은 markerID stop과 최대 order를 찾는다.
func locateStop(stops []domain.RouteStop, markerID string) (domain.RouteStop, int, bool) {
	var target domain.RouteStop
	found := false
	maxOrder := 0
	for _, s := range stops {
		if s.Order > maxOrder {
			maxOrder = s.Order
		}
		if s.MarkerID == markerID {
			target = s
			found = true
		}
	}
	return target, maxOrder, found
}

// validateReorderSet은 markerIDs가 Day stop 집합과 정확히 일치하는지 검증한다.
func validateReorderSet(stops []domain.RouteStop, markerIDs []string) error {
	if len(markerIDs) != len(stops) {
		return &domain.ValidationError{Message: "marker_ids는 해당 Day의 마커 전체와 일치해야 합니다."}
	}
	current := make(map[string]bool, len(stops))
	for _, s := range stops {
		current[s.MarkerID] = true
	}
	seen := make(map[string]bool, len(markerIDs))
	for _, id := range markerIDs {
		if seen[id] {
			return &domain.ValidationError{Message: "marker_ids에 중복이 있습니다."}
		}
		seen[id] = true
		if !current[id] {
			return &domain.ValidationError{Message: "해당 Day에 속하지 않은 마커가 있습니다."}
		}
	}
	return nil
}
