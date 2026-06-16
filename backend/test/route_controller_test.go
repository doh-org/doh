package test

import (
	"encoding/json"
	"net/http"
	"strconv"
	"testing"

	"doh/backend/domain"
	"doh/backend/test/testutil"
)

const routeTripID = "trip-route"
const routeDay1ID = "route-d1"

func setupRoute(t *testing.T) (http.Handler, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	fs.Trips = append(fs.Trips, domain.Trip{ID: routeTripID})
	fs.AddRoute(routeDay1ID, routeTripID) // day_index 1
	keys := testutil.NewTestKeys(t)
	router := testutil.NewTestRouteRouter(t, fs.Server.URL, keys, fs.Server.Client())
	return router, fs, keys
}

func strPtr(s string) *string { return &s }

// seedStop은 day1 route에 마커 + stop을 시드.
func seedStop(fs *testutil.FakeSupabase, mdID, markerID string, order int, visit *string) {
	fs.Markers = append(fs.Markers, domain.Marker{
		ID: markerID, TripID: routeTripID, Name: markerID, Latitude: 37.5, Longitude: 127.0,
	})
	fs.MarkerDays = append(fs.MarkerDays, testutil.FakeMarkerDay{
		ID: mdID, MarkerID: markerID, RouteID: routeDay1ID, Order: order, VisitTime: visit,
	})
}

func findMarkerDay(fs *testutil.FakeSupabase, markerID string) *testutil.FakeMarkerDay {
	for i := range fs.MarkerDays {
		if fs.MarkerDays[i].MarkerID == markerID {
			return &fs.MarkerDays[i]
		}
	}
	return nil
}

func dayMarkersPath(day int) string {
	return "/api/v1/trips/" + routeTripID + "/days/" + strconv.Itoa(day) + "/markers"
}

func stopPath(day int, markerID string) string {
	return dayMarkersPath(day) + "/" + markerID
}

func reorderPath(day int) string {
	return "/api/v1/trips/" + routeTripID + "/days/" + strconv.Itoa(day) + "/reorder"
}

// ── GET /days/:dayIndex/markers ─────────────────────────────────────────────────

func TestGetDayStops_SortedByVisitTime(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")

	seedStop(fs, "md-a", "ma", 1, strPtr("11:00"))
	seedStop(fs, "md-b", "mb", 2, strPtr("09:00"))
	seedStop(fs, "md-c", "mc", 3, nil) // 미정 → 하단

	w := doMarker(router, http.MethodGet, dayMarkersPath(1), tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var stops []domain.RouteStop
	json.NewDecoder(w.Body).Decode(&stops)
	if len(stops) != 3 {
		t.Fatalf("len=%d want 3", len(stops))
	}
	want := []string{"mb", "ma", "mc"}
	for i, id := range want {
		if stops[i].MarkerID != id {
			t.Errorf("stops[%d]=%q want %q", i, stops[i].MarkerID, id)
		}
	}
}

func TestGetDayStops_SortedByOrder(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")

	seedStop(fs, "md-a", "ma", 1, strPtr("11:00"))
	seedStop(fs, "md-b", "mb", 2, strPtr("09:00"))
	seedStop(fs, "md-c", "mc", 3, nil)

	w := doMarker(router, http.MethodGet, dayMarkersPath(1)+"?sort=order", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var stops []domain.RouteStop
	json.NewDecoder(w.Body).Decode(&stops)
	want := []string{"ma", "mb", "mc"} // order asc, visit_time 무시
	if len(stops) != len(want) {
		t.Fatalf("len=%d want %d", len(stops), len(want))
	}
	for i, id := range want {
		if stops[i].MarkerID != id {
			t.Errorf("stops[%d]=%q want %q", i, stops[i].MarkerID, id)
		}
	}
}

func TestGetDayStops_InvalidSort(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, dayMarkersPath(1)+"?sort=bogus", tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestGetDayStops_EmptyDayNoRoute(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, dayMarkersPath(2), tok, nil) // day2 route 없음
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var stops []domain.RouteStop
	json.NewDecoder(w.Body).Decode(&stops)
	if len(stops) != 0 {
		t.Errorf("len=%d want 0", len(stops))
	}
}

func TestGetDayStops_TripNotFound(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, "/api/v1/trips/no-such/days/1/markers", tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestGetDayStops_NoToken(t *testing.T) {
	router, _, _ := setupRoute(t)
	w := doMarker(router, http.MethodGet, dayMarkersPath(1), "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── PATCH /days/:dayIndex/markers/:markerId ─────────────────────────────────────

func TestUpdateStop_VisitTimeSuccess(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)

	w := doMarker(router, http.MethodPatch, stopPath(1, "ma"), tok, map[string]any{"visit_time": "09:30"})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var stop domain.RouteStop
	json.NewDecoder(w.Body).Decode(&stop)
	if stop.VisitTime == nil || *stop.VisitTime != "09:30" {
		t.Errorf("visit_time=%v want 09:30", stop.VisitTime)
	}
	if md := findMarkerDay(fs, "ma"); md == nil || md.VisitTime == nil || *md.VisitTime != "09:30" {
		t.Errorf("persisted visit_time mismatch: %+v", md)
	}
}

func TestUpdateStop_TransportSuccess(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)

	w := doMarker(router, http.MethodPatch, stopPath(1, "ma"), tok, map[string]any{"transport_to_next": "car"})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var stop domain.RouteStop
	json.NewDecoder(w.Body).Decode(&stop)
	if stop.TransportToNext == nil || *stop.TransportToNext != "car" {
		t.Errorf("transport_to_next=%v want car", stop.TransportToNext)
	}
}

func TestUpdateStop_TransportOnLastStop(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil) // mb가 마지막

	w := doMarker(router, http.MethodPatch, stopPath(1, "mb"), tok, map[string]any{"transport_to_next": "car"})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateStop_InvalidTransport(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)

	w := doMarker(router, http.MethodPatch, stopPath(1, "ma"), tok, map[string]any{"transport_to_next": "subway"})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateStop_InvalidVisitTime(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)

	w := doMarker(router, http.MethodPatch, stopPath(1, "ma"), tok, map[string]any{"visit_time": "25:99"})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateStop_MarkerNotInDay(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)

	w := doMarker(router, http.MethodPatch, stopPath(1, "zzz"), tok, map[string]any{"visit_time": "09:30"})
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestUpdateStop_NoToken(t *testing.T) {
	router, _, _ := setupRoute(t)
	w := doMarker(router, http.MethodPatch, stopPath(1, "ma"), "", map[string]any{"visit_time": "09:30"})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── PATCH /days/:dayIndex/reorder ───────────────────────────────────────────────

func TestReorderDay_Success(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)
	seedStop(fs, "md-c", "mc", 3, nil)

	w := doMarker(router, http.MethodPatch, reorderPath(1), tok, map[string]any{"marker_ids": []string{"mc", "ma", "mb"}})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]int
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["reordered"] != 3 {
		t.Errorf("reordered=%d want 3", resp["reordered"])
	}
	expect := map[string]int{"mc": 1, "ma": 2, "mb": 3}
	for id, want := range expect {
		if md := findMarkerDay(fs, id); md == nil || md.Order != want {
			t.Errorf("%s order=%v want %d", id, md, want)
		}
	}
}

func TestReorderDay_SetMismatch(t *testing.T) {
	router, fs, keys := setupRoute(t)
	tok := markerToken(t, keys, fs, "user-1")
	seedStop(fs, "md-a", "ma", 1, nil)
	seedStop(fs, "md-b", "mb", 2, nil)

	w := doMarker(router, http.MethodPatch, reorderPath(1), tok, map[string]any{"marker_ids": []string{"ma"}})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestReorderDay_NoToken(t *testing.T) {
	router, _, _ := setupRoute(t)
	w := doMarker(router, http.MethodPatch, reorderPath(1), "", map[string]any{"marker_ids": []string{"ma"}})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}
