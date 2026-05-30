package test

import (
	"context"
	"errors"
	"strings"
	"testing"

	"doh/backend/domain"
	"doh/backend/usecase"
)

// stubTripRepo는 TripRepository 인터페이스를 in-memory로 구현한 테스트용 스텁이다.
type stubTripRepo struct {
	trips map[string]*domain.Trip
}

func newStubTripRepo() *stubTripRepo {
	return &stubTripRepo{trips: make(map[string]*domain.Trip)}
}

func (s *stubTripRepo) CreateTrip(_ context.Context, _, ownerID string, input domain.CreateTripInput) (*domain.Trip, error) {
	t := &domain.Trip{ID: "stub-id", OwnerID: ownerID, Title: input.Title}
	s.trips[t.ID] = t
	return t, nil
}

func (s *stubTripRepo) GetTrips(_ context.Context, _ string) ([]domain.Trip, error) {
	out := make([]domain.Trip, 0, len(s.trips))
	for _, t := range s.trips {
		out = append(out, *t)
	}
	return out, nil
}

func (s *stubTripRepo) GetTrip(_ context.Context, _, tripID string) (*domain.Trip, error) {
	t, ok := s.trips[tripID]
	if !ok {
		return nil, domain.ErrNotFound
	}
	return t, nil
}

func (s *stubTripRepo) UpdateTrip(_ context.Context, _, tripID string, input domain.UpdateTripInput) (*domain.Trip, error) {
	t, ok := s.trips[tripID]
	if !ok {
		return nil, domain.ErrNotFound
	}
	if input.Title != nil {
		t.Title = *input.Title
	}
	return t, nil
}

func (s *stubTripRepo) DeleteTrip(_ context.Context, _, tripID string) error {
	if _, ok := s.trips[tripID]; !ok {
		return domain.ErrNotFound
	}
	delete(s.trips, tripID)
	return nil
}

func newUsecase() (domain.TripUsecase, *stubTripRepo) {
	repo := newStubTripRepo()
	return usecase.NewTripUsecase(repo), repo
}

// ── CreateTrip 제목 검증 ──────────────────────────────────────────────────────

func TestCreateTrip_TitleValidation(t *testing.T) {
	cases := []struct {
		name    string
		title   string
		wantErr bool
	}{
		{"empty", "", true},
		{"whitespace_only", "   ", true},
		{"ok_1char", "여", false},
		{"ok_50char", strings.Repeat("a", 50), false},
		{"too_long_51char", strings.Repeat("a", 51), true},
		{"trimmed_ok", "  여행  ", false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, _ := newUsecase()
			_, err := uc.CreateTrip(context.Background(), "uid", "tok", domain.CreateTripInput{Title: tc.title})
			if tc.wantErr && err == nil {
				t.Error("want error, got nil")
			}
			if !tc.wantErr && err != nil {
				t.Errorf("want nil, got %v", err)
			}
		})
	}
}

// ── CreateTrip 날짜 검증 ──────────────────────────────────────────────────────

func TestCreateTrip_DateValidation(t *testing.T) {
	p := func(s string) *string { return &s }
	cases := []struct {
		name    string
		start   *string
		end     *string
		wantErr bool
	}{
		{"both_nil", nil, nil, false},
		{"only_start", p("2026-07-01"), nil, false},
		{"only_end", nil, p("2026-07-10"), false},
		{"valid_range", p("2026-07-01"), p("2026-07-10"), false},
		{"same_day", p("2026-07-01"), p("2026-07-01"), false},
		{"end_before_start", p("2026-07-10"), p("2026-07-01"), true},
		{"bad_start_format", p("2026/07/01"), nil, true},
		{"bad_end_format", nil, p("07-01-2026"), true},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			uc, _ := newUsecase()
			_, err := uc.CreateTrip(context.Background(), "uid", "tok", domain.CreateTripInput{
				Title:     "여행",
				StartDate: tc.start,
				EndDate:   tc.end,
			})
			if tc.wantErr && err == nil {
				t.Error("want error, got nil")
			}
			if !tc.wantErr && err != nil {
				t.Errorf("want nil, got %v", err)
			}
		})
	}
}

// ── UpdateTrip 소유자 검증 ────────────────────────────────────────────────────

func TestUsecase_UpdateTrip_Forbidden(t *testing.T) {
	uc, repo := newUsecase()
	repo.trips["trip-1"] = &domain.Trip{ID: "trip-1", OwnerID: "owner-uid", Title: "원본"}

	title := "수정"
	_, err := uc.UpdateTrip(context.Background(), "other-uid", "tok", "trip-1", domain.UpdateTripInput{Title: &title})
	if !errors.Is(err, domain.ErrForbidden) {
		t.Errorf("want ErrForbidden, got %v", err)
	}
}

func TestUsecase_UpdateTrip_NotFound(t *testing.T) {
	uc, _ := newUsecase()
	title := "수정"
	_, err := uc.UpdateTrip(context.Background(), "uid", "tok", "no-such", domain.UpdateTripInput{Title: &title})
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}

func TestUsecase_UpdateTrip_TitleValidation(t *testing.T) {
	uc, repo := newUsecase()
	repo.trips["trip-1"] = &domain.Trip{ID: "trip-1", OwnerID: "uid", Title: "원본"}

	long := strings.Repeat("가", 51)
	_, err := uc.UpdateTrip(context.Background(), "uid", "tok", "trip-1", domain.UpdateTripInput{Title: &long})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("want ValidationError, got %v", err)
	}
}

func TestUsecase_UpdateTrip_DateCrossValidation(t *testing.T) {
	p := func(s string) *string { return &s }
	uc, repo := newUsecase()
	start := "2026-07-01"
	repo.trips["trip-1"] = &domain.Trip{ID: "trip-1", OwnerID: "uid", Title: "여행", StartDate: &start}

	// 기존 start=2026-07-01, 새 end=2026-06-30 → 교차 검증 실패
	_, err := uc.UpdateTrip(context.Background(), "uid", "tok", "trip-1", domain.UpdateTripInput{EndDate: p("2026-06-30")})
	var ve *domain.ValidationError
	if !errors.As(err, &ve) {
		t.Errorf("want ValidationError, got %v", err)
	}
}

// ── DeleteTrip 소유자 검증 ────────────────────────────────────────────────────

func TestUsecase_DeleteTrip_Forbidden(t *testing.T) {
	uc, repo := newUsecase()
	repo.trips["trip-1"] = &domain.Trip{ID: "trip-1", OwnerID: "owner-uid", Title: "여행"}

	err := uc.DeleteTrip(context.Background(), "other-uid", "tok", "trip-1")
	if !errors.Is(err, domain.ErrForbidden) {
		t.Errorf("want ErrForbidden, got %v", err)
	}
}

func TestUsecase_DeleteTrip_NotFound(t *testing.T) {
	uc, _ := newUsecase()
	err := uc.DeleteTrip(context.Background(), "uid", "tok", "no-such")
	if !errors.Is(err, domain.ErrNotFound) {
		t.Errorf("want ErrNotFound, got %v", err)
	}
}
