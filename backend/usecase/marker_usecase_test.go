package usecase_test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"doh/backend/domain"
	"doh/backend/usecase"
)

// ── stubs ─────────────────────────────────────────────────────────────────────

type stubMarkerRepo struct {
	markers map[string]*domain.Marker
}

func newStubMarkerRepo() *stubMarkerRepo {
	return &stubMarkerRepo{markers: make(map[string]*domain.Marker)}
}

func (s *stubMarkerRepo) CreateMarker(_ context.Context, _, tripID, userID string, input domain.CreateMarkerInput) (*domain.Marker, error) {
	m := &domain.Marker{ID: "marker-1", TripID: tripID, CreatedBy: &userID, Name: input.Name, Source: input.Source, Latitude: input.Latitude, Longitude: input.Longitude}
	s.markers[m.ID] = m
	return m, nil
}

func (s *stubMarkerRepo) GetMarkersByDay(_ context.Context, _, _ string, _ int, _ domain.StopSort) ([]domain.DayMarker, error) {
	return nil, nil
}

func (s *stubMarkerRepo) GetMarker(_ context.Context, _, _, markerID string) (*domain.Marker, error) {
	m, ok := s.markers[markerID]
	if !ok {
		return nil, domain.ErrNotFound
	}
	return m, nil
}

func (s *stubMarkerRepo) UpdateMarker(_ context.Context, _, _, markerID, _ string, input domain.UpdateMarkerInput) (*domain.Marker, error) {
	m, ok := s.markers[markerID]
	if !ok {
		return nil, domain.ErrNotFound
	}
	if input.Name != nil {
		m.Name = *input.Name
	}
	return m, nil
}

func (s *stubMarkerRepo) DeleteMarker(_ context.Context, _, _, markerID string) error {
	if _, ok := s.markers[markerID]; !ok {
		return domain.ErrNotFound
	}
	delete(s.markers, markerID)
	return nil
}

type stubTripRepo struct {
	trips map[string]*domain.Trip
}

func newStubTripRepo() *stubTripRepo {
	return &stubTripRepo{trips: make(map[string]*domain.Trip)}
}

func (s *stubTripRepo) CreateTrip(_ context.Context, _, _ string, _ domain.CreateTripInput) (*domain.Trip, error) {
	return nil, nil
}
func (s *stubTripRepo) GetTrips(_ context.Context, _ string) ([]domain.Trip, error) {
	return nil, nil
}
func (s *stubTripRepo) GetTrip(_ context.Context, _, tripID string) (*domain.Trip, error) {
	t, ok := s.trips[tripID]
	if !ok {
		return nil, domain.ErrNotFound
	}
	return t, nil
}
func (s *stubTripRepo) UpdateTrip(_ context.Context, _, _ string, _ domain.UpdateTripInput) (*domain.Trip, error) {
	return nil, nil
}
func (s *stubTripRepo) DeleteTrip(_ context.Context, _, _ string) error { return nil }

func newMarkerUsecase() (domain.MarkerUsecase, *stubMarkerRepo, *stubTripRepo) {
	mr := newStubMarkerRepo()
	tr := newStubTripRepo()
	tr.trips["trip-1"] = &domain.Trip{ID: "trip-1"}
	return usecase.NewMarkerUsecase(mr, tr), mr, tr
}

func validInput() domain.CreateMarkerInput {
	return domain.CreateMarkerInput{Name: "테스트 장소", Latitude: 37.5, Longitude: 127.0, Source: "search"}
}

// ── CreateMarker 장소명 검증 ───────────────────────────────────────────────────

func TestCreateMarker_NameValidation(t *testing.T) {
	cases := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{"empty", "", true},
		{"whitespace_only", "   ", true},
		{"ok_1char", "가", false},
		{"ok_100char", strings.Repeat("가", 100), false},
		{"too_long_101char", strings.Repeat("가", 101), true},
		{"trimmed_ok", "  장소  ", false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, _, _ := newMarkerUsecase()
			in := validInput()
			in.Name = tc.input
			_, err := uc.CreateMarker(context.Background(), "tok", "trip-1", "user-1", in)
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("want ValidationError, got %v", err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("unexpected ValidationError: %v", ve)
			}
		})
	}
}

// ── CreateMarker source 검증 ──────────────────────────────────────────────────

func TestCreateMarker_SourceValidation(t *testing.T) {
	valid := []string{"search", "longpress", "share"}
	invalid := []string{"manual", "", "SEARCH", "tap"}

	for _, src := range valid {
		t.Run("valid_"+src, func(t *testing.T) {
			uc, _, _ := newMarkerUsecase()
			in := validInput()
			in.Source = src
			_, err := uc.CreateMarker(context.Background(), "tok", "trip-1", "user-1", in)
			var ve *domain.ValidationError
			if errors.As(err, &ve) {
				t.Errorf("source=%q: unexpected ValidationError: %v", src, ve)
			}
		})
	}
	for _, src := range invalid {
		t.Run("invalid_"+src, func(t *testing.T) {
			uc, _, _ := newMarkerUsecase()
			in := validInput()
			in.Source = src
			_, err := uc.CreateMarker(context.Background(), "tok", "trip-1", "user-1", in)
			var ve *domain.ValidationError
			if !errors.As(err, &ve) {
				t.Errorf("source=%q: want ValidationError, got %v", src, err)
			}
		})
	}
}

// ── CreateMarker 위경도 범위 검증 ─────────────────────────────────────────────

func TestCreateMarker_LatitudeValidation(t *testing.T) {
	cases := []struct {
		name    string
		lat     float64
		wantErr bool
	}{
		{"min_boundary", -90, false},
		{"max_boundary", 90, false},
		{"too_low", -91, true},
		{"too_high", 91, true},
		{"valid", 37.5, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, _, _ := newMarkerUsecase()
			in := validInput()
			in.Latitude = tc.lat
			_, err := uc.CreateMarker(context.Background(), "tok", "trip-1", "user-1", in)
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("lat=%v: want ValidationError, got %v", tc.lat, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("lat=%v: unexpected ValidationError: %v", tc.lat, ve)
			}
		})
	}
}

func TestCreateMarker_LongitudeValidation(t *testing.T) {
	cases := []struct {
		name    string
		lng     float64
		wantErr bool
	}{
		{"min_boundary", -180, false},
		{"max_boundary", 180, false},
		{"too_low", -181, true},
		{"too_high", 181, true},
		{"valid", 127.0, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, _, _ := newMarkerUsecase()
			in := validInput()
			in.Longitude = tc.lng
			_, err := uc.CreateMarker(context.Background(), "tok", "trip-1", "user-1", in)
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("lng=%v: want ValidationError, got %v", tc.lng, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("lng=%v: unexpected ValidationError: %v", tc.lng, ve)
			}
		})
	}
}

// ── CreateMarker 논리 검증 ────────────────────────────────────────────────────

func TestCreateMarker_TripNotFound(t *testing.T) {
	uc, _, _ := newMarkerUsecase()
	_, err := uc.CreateMarker(context.Background(), "tok", "no-such-trip", "user-1", validInput())
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}

// ── UpdateMarker 검증 ─────────────────────────────────────────────────────────

func TestUpdateMarker_NameValidation(t *testing.T) {
	cases := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{"whitespace_only", "   ", true},
		{"ok_1char", "가", false},
		{"too_long_101char", strings.Repeat("가", 101), true},
		{"ok_100char", strings.Repeat("가", 100), false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, mr, _ := newMarkerUsecase()
			mr.markers["marker-1"] = &domain.Marker{ID: "marker-1", TripID: "trip-1", Name: "원본"}
			n := tc.input
			_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "marker-1", "user-1", domain.UpdateMarkerInput{Name: &n})
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("want ValidationError, got %v", err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("unexpected ValidationError: %v", ve)
			}
		})
	}
}

func TestUpdateMarker_LatWithoutLng(t *testing.T) {
	uc, mr, _ := newMarkerUsecase()
	mr.markers["marker-1"] = &domain.Marker{ID: "marker-1", TripID: "trip-1"}
	lat := 37.5
	_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "marker-1", "user-1", domain.UpdateMarkerInput{Latitude: &lat})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("want ValidationError, got %v", err)
	}
}

func TestUpdateMarker_LngWithoutLat(t *testing.T) {
	uc, mr, _ := newMarkerUsecase()
	mr.markers["marker-1"] = &domain.Marker{ID: "marker-1", TripID: "trip-1"}
	lng := 127.0
	_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "marker-1", "user-1", domain.UpdateMarkerInput{Longitude: &lng})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("want ValidationError, got %v", err)
	}
}

func TestUpdateMarker_LatitudeOutOfRange(t *testing.T) {
	cases := []struct {
		name    string
		lat     float64
		wantErr bool
	}{
		{"too_high", 91, true},
		{"too_low", -91, true},
		{"boundary_max", 90, false},
		{"boundary_min", -90, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, mr, _ := newMarkerUsecase()
			mr.markers["marker-1"] = &domain.Marker{ID: "marker-1", TripID: "trip-1"}
			lat, lng := tc.lat, 127.0
			_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "marker-1", "user-1", domain.UpdateMarkerInput{Latitude: &lat, Longitude: &lng})
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("lat=%v: want ValidationError, got %v", tc.lat, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("lat=%v: unexpected ValidationError: %v", tc.lat, ve)
			}
		})
	}
}

func TestUpdateMarker_LongitudeOutOfRange(t *testing.T) {
	cases := []struct {
		name    string
		lng     float64
		wantErr bool
	}{
		{"too_high", 181, true},
		{"too_low", -181, true},
		{"boundary_max", 180, false},
		{"boundary_min", -180, false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, mr, _ := newMarkerUsecase()
			mr.markers["marker-1"] = &domain.Marker{ID: "marker-1", TripID: "trip-1"}
			lat, lng := 37.5, tc.lng
			_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "marker-1", "user-1", domain.UpdateMarkerInput{Latitude: &lat, Longitude: &lng})
			var ve *domain.ValidationError
			if tc.wantErr && !errors.As(err, &ve) {
				t.Errorf("lng=%v: want ValidationError, got %v", tc.lng, err)
			}
			if !tc.wantErr && errors.As(err, &ve) {
				t.Errorf("lng=%v: unexpected ValidationError: %v", tc.lng, ve)
			}
		})
	}
}

func TestUpdateMarker_NotFound(t *testing.T) {
	uc, _, _ := newMarkerUsecase()
	n := "수정"
	_, err := uc.UpdateMarker(context.Background(), "tok", "trip-1", "no-such", "user-1", domain.UpdateMarkerInput{Name: &n})
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}

// ── DeleteMarker 검증 ─────────────────────────────────────────────────────────

func TestDeleteMarker_NotFound(t *testing.T) {
	uc, _, _ := newMarkerUsecase()
	err := uc.DeleteMarker(context.Background(), "tok", "trip-1", "no-such")
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}
