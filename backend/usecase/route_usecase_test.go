package usecase_test

import (
	"context"
	"encoding/json"
	"errors"
	"testing"

	"doh/backend/domain"
	"doh/backend/usecase"
)

// ── stub ──────────────────────────────────────────────────────────────────────

type stubRouteRepo struct {
	stops         map[int][]domain.RouteStop
	updateCalled  int
	reorderCalled int
}

func newStubRouteRepo() *stubRouteRepo {
	return &stubRouteRepo{stops: map[int][]domain.RouteStop{}}
}

func (s *stubRouteRepo) GetDayStops(_ context.Context, _, _ string, day int, _ domain.StopSort) ([]domain.RouteStop, error) {
	return s.stops[day], nil
}

func (s *stubRouteRepo) UpdateStop(_ context.Context, _, _ string, day int, markerID string, patch domain.StopPatch) error {
	s.updateCalled++
	list := s.stops[day]
	for i := range list {
		if list[i].MarkerID != markerID {
			continue
		}
		if patch.SetVisitTime {
			list[i].VisitTime = patch.VisitTime
		}
		if patch.SetTransport {
			list[i].TransportToNext = patch.Transport
			list[i].DistanceToNext = nil
			list[i].DurationToNext = nil
		}
	}
	return nil
}

func (s *stubRouteRepo) ReorderDay(_ context.Context, _, _ string, day int, markerIDs []string) error {
	s.reorderCalled++
	byID := make(map[string]domain.RouteStop, len(s.stops[day]))
	for _, st := range s.stops[day] {
		byID[st.MarkerID] = st
	}
	newList := make([]domain.RouteStop, 0, len(markerIDs))
	for i, id := range markerIDs {
		st := byID[id]
		st.Order = i + 1
		newList = append(newList, st)
	}
	s.stops[day] = newList
	return nil
}

func newRouteUsecase() (domain.RouteUsecase, *stubRouteRepo, *stubTripRepo) {
	rr := newStubRouteRepo()
	tr := newStubTripRepo()
	tr.trips["trip-1"] = &domain.Trip{ID: "trip-1"}
	return usecase.NewRouteUsecase(rr, tr), rr, tr
}

func twoStops() []domain.RouteStop {
	return []domain.RouteStop{
		{MarkerID: "m1", Order: 1},
		{MarkerID: "m2", Order: 2},
	}
}

// ── UpdateStop ───────────────────────────────────────────────────────────────

func TestUpdateStop_VisitTimeFormat(t *testing.T) {
	cases := []struct {
		name    string
		raw     string
		wantErr bool
	}{
		{"hhmm", `"09:30"`, false},
		{"hhmmss", `"09:30:00"`, false},
		{"null_clear", `null`, false},
		{"bad_text", `"9시반"`, true},
		{"hour_overflow", `"25:00"`, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, rr, _ := newRouteUsecase()
			rr.stops[1] = twoStops()
			in := domain.UpdateStopInput{VisitTime: json.RawMessage(tc.raw)}
			_, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "m1", in)
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("raw=%s: want ValidationError, got %v", tc.raw, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("raw=%s: unexpected ValidationError: %v", tc.raw, ve)
			}
		})
	}
}

func TestUpdateStop_TransportValidation(t *testing.T) {
	cases := []struct {
		name    string
		raw     string
		wantErr bool
	}{
		{"car", `"car"`, false},
		{"foot", `"foot"`, false},
		{"null_clear", `null`, false},
		{"unknown", `"subway"`, true},
		{"empty", `""`, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, rr, _ := newRouteUsecase()
			rr.stops[1] = twoStops()
			in := domain.UpdateStopInput{TransportToNext: json.RawMessage(tc.raw)}
			// m1은 마지막 stop이 아니므로 이동수단 설정 가능.
			_, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "m1", in)
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("raw=%s: want ValidationError, got %v", tc.raw, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("raw=%s: unexpected ValidationError: %v", tc.raw, ve)
			}
		})
	}
}

func TestUpdateStop_TransportOnLastStop(t *testing.T) {
	uc, rr, _ := newRouteUsecase()
	rr.stops[1] = twoStops() // m2가 마지막(order 2)

	// 마지막 stop에 이동수단 설정 → 거부
	_, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "m2", domain.UpdateStopInput{TransportToNext: json.RawMessage(`"car"`)})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Fatalf("last stop transport set: want ValidationError, got %v", err)
	}

	// 마지막 stop에 이동수단 해제(null) → 허용
	_, err = uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "m2", domain.UpdateStopInput{TransportToNext: json.RawMessage(`null`)})
	if errors.As(err, &ve) {
		t.Errorf("last stop transport clear: unexpected ValidationError: %v", ve)
	}
}

func TestUpdateStop_MarkerNotInDay(t *testing.T) {
	uc, rr, _ := newRouteUsecase()
	rr.stops[1] = twoStops()
	_, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "mX", domain.UpdateStopInput{VisitTime: json.RawMessage(`"10:00"`)})
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}

func TestUpdateStop_DayValidation(t *testing.T) {
	uc, _, _ := newRouteUsecase()
	_, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 0, "m1", domain.UpdateStopInput{})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("day=0: want ValidationError, got %v", err)
	}
}

func TestUpdateStop_TripNotFound(t *testing.T) {
	uc, _, _ := newRouteUsecase()
	_, err := uc.UpdateStop(context.Background(), "tok", "no-such", 1, "m1", domain.UpdateStopInput{})
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}

func TestUpdateStop_Success(t *testing.T) {
	uc, rr, _ := newRouteUsecase()
	rr.stops[1] = twoStops()
	stop, err := uc.UpdateStop(context.Background(), "tok", "trip-1", 1, "m1", domain.UpdateStopInput{VisitTime: json.RawMessage(`"09:30"`)})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if rr.updateCalled != 1 {
		t.Errorf("updateCalled = %d, want 1", rr.updateCalled)
	}
	if stop == nil || stop.VisitTime == nil || *stop.VisitTime != "09:30" {
		t.Errorf("returned stop visit_time mismatch: %+v", stop)
	}
}

// ── ReorderDay ───────────────────────────────────────────────────────────────

func TestReorderDay_Validation(t *testing.T) {
	cases := []struct {
		name string
		ids  []string
	}{
		{"empty", []string{}},
		{"length_mismatch", []string{"m1"}},
		{"duplicate", []string{"m1", "m1"}},
		{"foreign_marker", []string{"m1", "mX"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, rr, _ := newRouteUsecase()
			rr.stops[1] = twoStops()
			_, err := uc.ReorderDay(context.Background(), "tok", "trip-1", 1, tc.ids)
			var ve *domain.ValidationError
			if !errors.As(err, &ve) {
				t.Errorf("ids=%v: want ValidationError, got %v", tc.ids, err)
			}
		})
	}
}

func TestReorderDay_NoOpSingleStop(t *testing.T) {
	uc, rr, _ := newRouteUsecase()
	rr.stops[1] = []domain.RouteStop{{MarkerID: "m1", Order: 1}}
	n, err := uc.ReorderDay(context.Background(), "tok", "trip-1", 1, []string{"m1"})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if n != 1 {
		t.Errorf("reordered = %d, want 1", n)
	}
	if rr.reorderCalled != 0 {
		t.Errorf("reorderCalled = %d, want 0 (no-op)", rr.reorderCalled)
	}
}

func TestReorderDay_Success(t *testing.T) {
	uc, rr, _ := newRouteUsecase()
	rr.stops[1] = []domain.RouteStop{
		{MarkerID: "m1", Order: 1}, {MarkerID: "m2", Order: 2}, {MarkerID: "m3", Order: 3},
	}
	n, err := uc.ReorderDay(context.Background(), "tok", "trip-1", 1, []string{"m3", "m1", "m2"})
	if err != nil {
		t.Fatalf("unexpected err: %v", err)
	}
	if n != 3 {
		t.Errorf("reordered = %d, want 3", n)
	}
	if rr.reorderCalled != 1 {
		t.Errorf("reorderCalled = %d, want 1", rr.reorderCalled)
	}
	if rr.stops[1][0].MarkerID != "m3" || rr.stops[1][0].Order != 1 {
		t.Errorf("first stop after reorder = %+v, want m3/order1", rr.stops[1][0])
	}
}

func TestReorderDay_DayValidation(t *testing.T) {
	uc, _, _ := newRouteUsecase()
	_, err := uc.ReorderDay(context.Background(), "tok", "trip-1", 0, []string{"m1"})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("day=0: want ValidationError, got %v", err)
	}
}
