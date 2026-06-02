package testutil

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
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
	Routes     []fakeRoute
	Waypoints  []fakeWaypoint
	MarkerDays []FakeMarkerDay
}

type fakeRoute struct {
	ID     string
	TripID string
}

type fakeWaypoint struct {
	RouteID  string
	MarkerID string
	Order    int
}

type FakeMarkerDay struct {
	MarkerID string
	DayIndex int
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
		idFilter := strings.TrimPrefix(q.Get("id"), "eq.")
		tripFilter := strings.TrimPrefix(q.Get("trip_id"), "eq.")
		nameFilter := strings.TrimPrefix(q.Get("name"), "ilike.*")
		nameFilter = strings.TrimSuffix(nameFilter, "*")
		catFilter := q.Get("category_id")

		var result []domain.Marker
		for _, m := range fs.Markers {
			if idFilter != "" && m.ID != idFilter {
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
			markerFilter := q.Get("marker_id")
			idSet := map[string]bool{}
			if strings.HasPrefix(markerFilter, "eq.") {
				idSet[strings.TrimPrefix(markerFilter, "eq.")] = true
			} else if strings.HasPrefix(markerFilter, "in.(") {
				inner := strings.TrimSuffix(strings.TrimPrefix(markerFilter, "in.("), ")")
				for _, id := range strings.Split(inner, ",") {
					idSet[id] = true
				}
			}
			type row struct {
				MarkerID string `json:"marker_id"`
				DayIndex int    `json:"day_index"`
			}
			var result []row
			for _, d := range fs.MarkerDays {
				if len(idSet) == 0 || idSet[d.MarkerID] {
					result = append(result, row{MarkerID: d.MarkerID, DayIndex: d.DayIndex})
				}
			}
			if result == nil {
				result = []row{}
			}
			json.NewEncoder(w).Encode(result)

		case http.MethodPost:
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			d := FakeMarkerDay{}
			if v, ok := body["marker_id"].(string); ok {
				d.MarkerID = v
			}
			if v, ok := body["day_index"].(float64); ok {
				d.DayIndex = int(v)
			}
			fs.MarkerDays = append(fs.MarkerDays, d)
			w.WriteHeader(http.StatusCreated)

		case http.MethodDelete:
			markerID := strings.TrimPrefix(q.Get("marker_id"), "eq.")
			var remaining []FakeMarkerDay
			for _, d := range fs.MarkerDays {
				if d.MarkerID != markerID {
					remaining = append(remaining, d)
				}
			}
			fs.MarkerDays = remaining
			w.WriteHeader(http.StatusNoContent)
		}
	})

	mux.HandleFunc("/rest/v1/routes", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		tripFilter := strings.TrimPrefix(r.URL.Query().Get("trip_id"), "eq.")
		var result []map[string]string
		for _, rt := range fs.Routes {
			if rt.TripID == tripFilter {
				result = append(result, map[string]string{"id": rt.ID})
				break
			}
		}
		if result == nil {
			result = []map[string]string{}
		}
		json.NewEncoder(w).Encode(result)
	})

	mux.HandleFunc("/rest/v1/route_waypoints", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		q := r.URL.Query()

		switch r.Method {
		case http.MethodGet:
			routeFilter := strings.TrimPrefix(q.Get("route_id"), "eq.")
			maxOrder := -1
			for _, wp := range fs.Waypoints {
				if wp.RouteID == routeFilter && wp.Order > maxOrder {
					maxOrder = wp.Order
				}
			}
			if maxOrder == -1 {
				json.NewEncoder(w).Encode([]map[string]int{})
			} else {
				json.NewEncoder(w).Encode([]map[string]int{{"order": maxOrder}})
			}

		case http.MethodPost:
			var body map[string]any
			json.NewDecoder(r.Body).Decode(&body)
			wp := fakeWaypoint{}
			if v, ok := body["route_id"].(string); ok {
				wp.RouteID = v
			}
			if v, ok := body["marker_id"].(string); ok {
				wp.MarkerID = v
			}
			if v, ok := body["order"].(float64); ok {
				wp.Order = int(v)
			}
			fs.Waypoints = append(fs.Waypoints, wp)
			w.WriteHeader(http.StatusCreated)
		}
	})

	fs.Server = httptest.NewServer(mux)
	t.Cleanup(fs.Server.Close)
	return fs
}

// AddRoute는 테스트에서 trip에 기본 route를 미리 등록한다.
func (fs *FakeSupabase) AddRoute(routeID, tripID string) {
	fs.Routes = append(fs.Routes, fakeRoute{ID: routeID, TripID: tripID})
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
