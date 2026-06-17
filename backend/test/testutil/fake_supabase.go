package testutil

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"testing"
	"time"

	"doh/backend/domain"
)

// FakeSupabase는 Supabase Auth + PostgREST 엔드포인트를 시뮬레이션한다.
type FakeSupabase struct {
	Server       *httptest.Server
	SignupError  string // "user_already_exists" 등 error_code; 빈 문자열이면 성공
	LoginError   bool
	SessionValid bool   // GET /auth/v1/user 응답 (true=200, false=401)
	UserRow      string // PostgREST /rest/v1/users 응답 JSON

	// Trips
	Trips       []domain.Trip
	CreateError int // 0이면 성공, 그 외 HTTP status 반환
	UpdateError int
	DeleteError int

	// Markers
	Markers    []domain.Marker
	MarkerDays []FakeMarkerDay
}

type FakeMarkerDay struct {
	ID              string
	MarkerID        string
	TripID          string
	DayIndex        int
	Order           int
	VisitTime       *string
	TransportToNext *string
	DistanceToNext  *float64
	DurationToNext  *int
}

func NewFakeSupabase(t *testing.T) *FakeSupabase {
	t.Helper()
	fs := &FakeSupabase{
		SessionValid: true,
		UserRow:      `{"nickname":"테스터","created_at":"2024-01-01T00:00:00Z"}`,
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/auth/v1/signup", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if fs.SignupError != "" {
			w.WriteHeader(http.StatusUnprocessableEntity)
			json.NewEncoder(w).Encode(map[string]string{"error_code": fs.SignupError})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{
			"access_token":  "fake-access-token",
			"refresh_token": "fake-refresh-token",
			"user":          map[string]string{"id": "fake-user-id"},
		})
	})

	mux.HandleFunc("/auth/v1/token", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if fs.LoginError {
			w.WriteHeader(http.StatusBadRequest)
			json.NewEncoder(w).Encode(map[string]string{"error": "invalid_grant"})
			return
		}
		json.NewEncoder(w).Encode(map[string]any{
			"access_token":  "fake-access-token",
			"refresh_token": "fake-refresh-token",
			"user":          map[string]string{"id": "fake-user-id"},
		})
	})

	mux.HandleFunc("/auth/v1/logout", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusNoContent)
	})

	mux.HandleFunc("/auth/v1/user", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		if !fs.SessionValid {
			w.WriteHeader(http.StatusUnauthorized)
			json.NewEncoder(w).Encode(map[string]string{"error": "invalid_token"})
			return
		}
		json.NewEncoder(w).Encode(map[string]string{"id": "fake-user-id"})
	})

	mux.HandleFunc("/rest/v1/users", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(fs.UserRow))
	})

	mux.HandleFunc("/rest/v1/trips", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		idFilter := parseIDEqFilter(r.URL.Query())

		switch r.Method {
		case http.MethodPost:
			if fs.CreateError != 0 {
				w.WriteHeader(fs.CreateError)
				return
			}
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			fs.Trips = append(fs.Trips, tripFromBody(body))
			w.WriteHeader(http.StatusCreated)

		case http.MethodGet:
			json.NewEncoder(w).Encode(fs.filterTrips(idFilter))

		case http.MethodPatch:
			if fs.UpdateError != 0 {
				w.WriteHeader(fs.UpdateError)
				return
			}
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			for i, t := range fs.Trips {
				if t.ID == idFilter {
					applyUpdate(&fs.Trips[i], body)
					json.NewEncoder(w).Encode([]domain.Trip{fs.Trips[i]})
					return
				}
			}
			json.NewEncoder(w).Encode([]domain.Trip{})

		case http.MethodDelete:
			if fs.DeleteError != 0 {
				w.WriteHeader(fs.DeleteError)
				return
			}
			for i, t := range fs.Trips {
				if t.ID == idFilter {
					fs.Trips = append(fs.Trips[:i], fs.Trips[i+1:]...)
					break
				}
			}
			w.WriteHeader(http.StatusNoContent)
		}
	})

	mux.HandleFunc("/rest/v1/markers", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		q := r.URL.Query()
		idFilter := strings.TrimPrefix(q.Get("id"), "eq.")
		tripFilter := strings.TrimPrefix(q.Get("trip_id"), "eq.")

		switch r.Method {
		case http.MethodPost:
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			fs.Markers = append(fs.Markers, markerFromBody(body))
			w.WriteHeader(http.StatusCreated)

		case http.MethodPatch:
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			for i, m := range fs.Markers {
				if m.ID == idFilter && m.TripID == tripFilter {
					applyMarkerUpdate(&fs.Markers[i], body)
					w.WriteHeader(http.StatusNoContent)
					return
				}
			}
			w.WriteHeader(http.StatusNoContent)

		case http.MethodDelete:
			for i, m := range fs.Markers {
				if m.ID == idFilter && m.TripID == tripFilter {
					fs.Markers = append(fs.Markers[:i], fs.Markers[i+1:]...)
					break
				}
			}
			w.WriteHeader(http.StatusNoContent)
		}
	})

	mux.HandleFunc("/rest/v1/markers_view", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		q := r.URL.Query()
		idSet := parseInFilter(q.Get("id")) // eq.x / in.(a,b) 모두 지원
		tripFilter := strings.TrimPrefix(q.Get("trip_id"), "eq.")
		nameFilter := strings.TrimPrefix(q.Get("name"), "ilike.*")
		nameFilter = strings.TrimSuffix(nameFilter, "*")
		catFilter := q.Get("category_id")

		var result []domain.Marker
		for _, m := range fs.Markers {
			if len(idSet) > 0 && !idSet[m.ID] {
				continue
			}
			if tripFilter != "" && m.TripID != tripFilter {
				continue
			}
			if nameFilter != "" && !strings.Contains(strings.ToLower(m.Name), strings.ToLower(nameFilter)) {
				continue
			}
			if catFilter == "is.null" {
				if m.CategoryID != nil {
					continue
				}
			} else if strings.HasPrefix(catFilter, "eq.") {
				want := strings.TrimPrefix(catFilter, "eq.")
				if m.CategoryID == nil || *m.CategoryID != want {
					continue
				}
			}
			result = append(result, m)
		}
		if result == nil {
			result = []domain.Marker{}
		}
		json.NewEncoder(w).Encode(result)
	})

	mux.HandleFunc("/rest/v1/marker_days", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		q := r.URL.Query()

		switch r.Method {
		case http.MethodGet:
			markerSet := parseInFilter(q.Get("marker_id"))
			tripFilter := strings.TrimPrefix(q.Get("trip_id"), "eq.")
			dayFilter, hasDay := parseEqInt(q.Get("day_index"))
			type row struct {
				ID              string   `json:"id"`
				MarkerID        string   `json:"marker_id"`
				TripID          string   `json:"trip_id"`
				DayIndex        int      `json:"day_index"`
				Order           int      `json:"order"`
				VisitTime       *string  `json:"visit_time"`
				TransportToNext *string  `json:"transport_to_next"`
				DistanceToNext  *float64 `json:"distance_to_next"`
				DurationToNext  *int     `json:"duration_to_next"`
			}
			result := []row{}
			for _, d := range fs.MarkerDays {
				if len(markerSet) > 0 && !markerSet[d.MarkerID] {
					continue
				}
				if tripFilter != "" && d.TripID != tripFilter {
					continue
				}
				if hasDay && d.DayIndex != dayFilter {
					continue
				}
				result = append(result, row{
					ID: d.ID, MarkerID: d.MarkerID, TripID: d.TripID, DayIndex: d.DayIndex, Order: d.Order,
					VisitTime: d.VisitTime, TransportToNext: d.TransportToNext,
					DistanceToNext: d.DistanceToNext, DurationToNext: d.DurationToNext,
				})
			}
			if ord := q.Get("order"); strings.Contains(ord, "visit_time") {
				sort.SliceStable(result, func(i, j int) bool {
					return lessVisitThenOrder(result[i].VisitTime, result[i].Order, result[j].VisitTime, result[j].Order)
				})
			} else if strings.Contains(ord, "order") {
				sort.SliceStable(result, func(i, j int) bool { return result[i].Order < result[j].Order })
			}
			json.NewEncoder(w).Encode(result)

		case http.MethodPost:
			// reorder는 Prefer: resolution=merge-duplicates 로 배열 upsert.
			if strings.Contains(r.Header.Get("Prefer"), "merge-duplicates") {
				var rows []map[string]any
				json.NewDecoder(r.Body).Decode(&rows)
				for _, b := range rows {
					id, _ := b["id"].(string)
					for i := range fs.MarkerDays {
						if fs.MarkerDays[i].ID != id {
							continue
						}
						if v, ok := b["order"].(float64); ok {
							fs.MarkerDays[i].Order = int(v)
						}
					}
				}
				w.WriteHeader(http.StatusCreated)
				return
			}
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			d := FakeMarkerDay{ID: fmt.Sprintf("md-%d", len(fs.MarkerDays)+1)}
			if v, ok := body["marker_id"].(string); ok {
				d.MarkerID = v
			}
			if v, ok := body["trip_id"].(string); ok {
				d.TripID = v
			}
			if v, ok := body["day_index"].(float64); ok {
				d.DayIndex = int(v)
			}
			if v, ok := body["order"].(float64); ok {
				d.Order = int(v)
			}
			fs.MarkerDays = append(fs.MarkerDays, d)
			w.WriteHeader(http.StatusCreated)

		case http.MethodPatch:
			tripFilter := strings.TrimPrefix(q.Get("trip_id"), "eq.")
			dayFilter, hasDay := parseEqInt(q.Get("day_index"))
			markerFilter := strings.TrimPrefix(q.Get("marker_id"), "eq.")
			idFilter := strings.TrimPrefix(q.Get("id"), "eq.")
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			for i := range fs.MarkerDays {
				d := &fs.MarkerDays[i]
				if idFilter != "" && d.ID != idFilter {
					continue
				}
				if tripFilter != "" && d.TripID != tripFilter {
					continue
				}
				if hasDay && d.DayIndex != dayFilter {
					continue
				}
				if markerFilter != "" && d.MarkerID != markerFilter {
					continue
				}
				applyMarkerDayPatch(d, body)
			}
			w.WriteHeader(http.StatusNoContent)

		case http.MethodDelete:
			idFilter := strings.TrimPrefix(q.Get("id"), "eq.")
			markerFilter := strings.TrimPrefix(q.Get("marker_id"), "eq.")
			var remaining []FakeMarkerDay
			for _, d := range fs.MarkerDays {
				if idFilter != "" && d.ID == idFilter {
					continue
				}
				if markerFilter != "" && d.MarkerID == markerFilter {
					continue
				}
				remaining = append(remaining, d)
			}
			fs.MarkerDays = remaining
			w.WriteHeader(http.StatusNoContent)
		}
	})

	fs.Server = httptest.NewServer(mux)
	t.Cleanup(fs.Server.Close)
	return fs
}

// applyMarkerDayPatch는 marker_days PATCH body를 반영한다(null=해제).
func applyMarkerDayPatch(d *FakeMarkerDay, body map[string]any) {
	if v, exists := body["visit_time"]; exists {
		if v == nil {
			d.VisitTime = nil
		} else if s, ok := v.(string); ok {
			d.VisitTime = &s
		}
	}
	if v, exists := body["transport_to_next"]; exists {
		if v == nil {
			d.TransportToNext = nil
		} else if s, ok := v.(string); ok {
			d.TransportToNext = &s
		}
	}
	if v, exists := body["distance_to_next"]; exists {
		if v == nil {
			d.DistanceToNext = nil
		} else if f, ok := v.(float64); ok {
			d.DistanceToNext = &f
		}
	}
	if v, exists := body["duration_to_next"]; exists {
		if v == nil {
			d.DurationToNext = nil
		} else if f, ok := v.(float64); ok {
			n := int(f)
			d.DurationToNext = &n
		}
	}
}

// lessVisitThenOrder: visit_time asc(nil 하단), 동률이면 order asc.
func lessVisitThenOrder(vi *string, oi int, vj *string, oj int) bool {
	if (vi == nil) != (vj == nil) {
		return vi != nil // non-nil 먼저(nil 하단)
	}
	if vi != nil && *vi != *vj {
		return *vi < *vj
	}
	return oi < oj
}

// parseInFilter는 PostgREST "eq.x" / "in.(a,b)" 필터를 집합으로 변환한다.
func parseInFilter(v string) map[string]bool {
	set := map[string]bool{}
	switch {
	case strings.HasPrefix(v, "eq."):
		set[strings.TrimPrefix(v, "eq.")] = true
	case strings.HasPrefix(v, "in.("):
		inner := strings.TrimSuffix(strings.TrimPrefix(v, "in.("), ")")
		for _, id := range strings.Split(inner, ",") {
			set[id] = true
		}
	}
	return set
}

// parseEqInt는 "eq.3" 필터를 정수로 변환한다. 필터 없으면 ok=false.
func parseEqInt(v string) (int, bool) {
	if !strings.HasPrefix(v, "eq.") {
		return 0, false
	}
	n, err := strconv.Atoi(strings.TrimPrefix(v, "eq."))
	if err != nil {
		return 0, false
	}
	return n, true
}

func parseIDEqFilter(q url.Values) string {
	return strings.TrimPrefix(q.Get("id"), "eq.")
}

func (fs *FakeSupabase) filterTrips(id string) []domain.Trip {
	var result []domain.Trip
	for _, t := range fs.Trips {
		if t.DeletedAt != nil {
			continue
		}
		if id != "" && t.ID != id {
			continue
		}
		result = append(result, t)
	}
	if result == nil {
		return []domain.Trip{}
	}
	return result
}

func tripFromBody(body map[string]any) domain.Trip {
	t := domain.Trip{CreatedAt: time.Now().UTC()}
	if v, ok := body["id"].(string); ok {
		t.ID = v
	}
	if v, ok := body["owner_id"].(string); ok {
		t.OwnerID = v
	}
	if v, ok := body["title"].(string); ok {
		t.Title = v
	}
	if v, ok := body["description"].(string); ok {
		s := v
		t.Description = &s
	}
	if v, ok := body["destination"].(string); ok {
		s := v
		t.Destination = &s
	}
	if v, ok := body["start_date"].(string); ok {
		s := v
		t.StartDate = &s
	}
	if v, ok := body["end_date"].(string); ok {
		s := v
		t.EndDate = &s
	}
	return t
}

func markerFromBody(body map[string]any) domain.Marker {
	m := domain.Marker{Detail: map[string]any{}, VisitDays: []int{}}
	if v, ok := body["id"].(string); ok {
		m.ID = v
	}
	if v, ok := body["trip_id"].(string); ok {
		m.TripID = v
	}
	if v, ok := body["created_by"].(string); ok {
		m.CreatedBy = &v
	}
	if v, ok := body["name"].(string); ok {
		m.Name = v
	}
	if v, ok := body["source"].(string); ok {
		m.Source = v
	}
	if v, ok := body["address"].(string); ok {
		s := v
		m.Address = &s
	}
	if v, ok := body["category_id"].(string); ok {
		s := v
		m.CategoryID = &s
	}
	if loc, ok := body["location"].(string); ok {
		var lng, lat float64
		fmt.Sscanf(loc, "POINT(%f %f)", &lng, &lat)
		m.Longitude = lng
		m.Latitude = lat
	}
	if v, ok := body["detail"].(map[string]any); ok {
		m.Detail = v
	}
	return m
}

func applyMarkerUpdate(m *domain.Marker, body map[string]any) {
	if v, ok := body["name"].(string); ok {
		m.Name = v
	}
	if v, ok := body["address"].(string); ok {
		s := v
		m.Address = &s
	}
	if loc, ok := body["location"].(string); ok {
		var lng, lat float64
		fmt.Sscanf(loc, "POINT(%f %f)", &lng, &lat)
		m.Longitude = lng
		m.Latitude = lat
	}
	if _, exists := body["category_id"]; exists {
		if body["category_id"] == nil {
			m.CategoryID = nil
		} else if v, ok := body["category_id"].(string); ok {
			m.CategoryID = &v
		}
	}
}

func applyUpdate(t *domain.Trip, body map[string]any) {
	if v, ok := body["title"].(string); ok {
		t.Title = v
	}
	if v, ok := body["description"].(string); ok {
		s := v
		t.Description = &s
	}
	if v, ok := body["destination"].(string); ok {
		s := v
		t.Destination = &s
	}
	if v, ok := body["start_date"].(string); ok {
		s := v
		t.StartDate = &s
	}
	if v, ok := body["end_date"].(string); ok {
		s := v
		t.EndDate = &s
	}
}
