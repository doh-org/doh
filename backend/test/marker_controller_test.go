package test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"doh/backend/domain"
	"doh/backend/test/testutil"
)

const defaultTripID = "trip-aaa"
const defaultRouteID = "route-aaa"

func setupMarker(t *testing.T) (http.Handler, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	fs.Trips = append(fs.Trips, domain.Trip{ID: defaultTripID})
	fs.AddRoute(defaultRouteID, defaultTripID)
	keys := testutil.NewTestKeys(t)
	router := testutil.NewTestMarkerRouter(t, fs.Server.URL, keys, fs.Server.Client())
	return router, fs, keys
}

func markerToken(t *testing.T, keys *testutil.TestKeys, fs *testutil.FakeSupabase, userID string) string {
	t.Helper()
	return keys.Sign(userID, userID+"@test.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))
}

func doMarker(router http.Handler, method, path, token string, body any) *httptest.ResponseRecorder {
	var buf bytes.Buffer
	if body != nil {
		json.NewEncoder(&buf).Encode(body)
	}
	req := httptest.NewRequest(method, path, &buf)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func markerPath(tripID, markerID string) string {
	if markerID == "" {
		return "/api/v1/trips/" + tripID + "/markers"
	}
	return "/api/v1/trips/" + tripID + "/markers/" + markerID
}

func createMarkerBody() map[string]any {
	return map[string]any{
		"name":      "테스트 장소",
		"latitude":  37.5264,
		"longitude": 126.8977,
		"source":    "search",
	}
}

func createMarker(t *testing.T, router http.Handler, tok, tripID string) domain.Marker {
	t.Helper()
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+tripID+"/markers/add", tok, createMarkerBody())
	if w.Code != http.StatusCreated {
		t.Fatalf("createMarker failed: status=%d body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	return m
}

// ── POST /add ─────────────────────────────────────────────────────────────────

func TestCreateMarker_Success(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, createMarkerBody())
	if w.Code != http.StatusCreated {
		t.Fatalf("status=%d want 201, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.ID == "" {
		t.Error("id is empty")
	}
	if m.TripID != defaultTripID {
		t.Errorf("trip_id=%q want %q", m.TripID, defaultTripID)
	}
	if m.Name != "테스트 장소" {
		t.Errorf("name=%q", m.Name)
	}
}

func TestCreateMarker_AllFields(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	addr := "서울 강남구 역삼로 123"
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, map[string]any{
		"name":      "카페베네",
		"latitude":  37.51,
		"longitude": 127.02,
		"source":    "longpress",
		"address":   addr,
		"detail":    map[string]any{"phone": "02-0000-0000"},
	})
	if w.Code != http.StatusCreated {
		t.Fatalf("status=%d want 201, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.Address == nil || *m.Address != addr {
		t.Errorf("address=%v want %q", m.Address, addr)
	}
}

func TestCreateMarker_EmptyName(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["name"] = ""
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_BlankName(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["name"] = "   "
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_NameTooLong(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["name"] = strings.Repeat("가", 101)
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_InvalidSource(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["source"] = "manual"
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_ValidSources(t *testing.T) {
	for _, src := range []string{"search", "longpress", "share"} {
		t.Run(src, func(t *testing.T) {
			router, fs, keys := setupMarker(t)
			tok := markerToken(t, keys, fs, "user-1")
			body := createMarkerBody()
			body["source"] = src
			w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
			if w.Code != http.StatusCreated {
				t.Errorf("source=%q: status=%d want 201", src, w.Code)
			}
		})
	}
}

func TestCreateMarker_LatitudeOutOfRange(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["latitude"] = 91
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_LongitudeOutOfRange(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["longitude"] = 181
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateMarker_TripNotFound(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodPost, "/api/v1/trips/00000000-0000-0000-0000-000000000000/markers/add", tok, createMarkerBody())
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestCreateMarker_NoToken(t *testing.T) {
	router, _, _ := setupMarker(t)
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", "", createMarkerBody())
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestCreateMarker_BodyTooLarge(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body := createMarkerBody()
	body["address"] = strings.Repeat("x", 5000)
	w := doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body)
	if w.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("status=%d want 413", w.Code)
	}
}

// ── GET /markers ──────────────────────────────────────────────────────────────

func TestGetMarkers_Empty(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, ""), tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var markers []domain.Marker
	json.NewDecoder(w.Body).Decode(&markers)
	if len(markers) != 0 {
		t.Errorf("len=%d want 0", len(markers))
	}
}

func TestGetMarkers_ReturnsList(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	createMarker(t, router, tok, defaultTripID)
	createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, ""), tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200", w.Code)
	}
	var markers []domain.Marker
	json.NewDecoder(w.Body).Decode(&markers)
	if len(markers) != 2 {
		t.Errorf("len=%d want 2", len(markers))
	}
}

func TestGetMarkers_QueryFilter(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	body1 := createMarkerBody()
	body1["name"] = "스타벅스 강남점"
	body2 := createMarkerBody()
	body2["name"] = "투썸플레이스"
	doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body1)
	doMarker(router, http.MethodPost, "/api/v1/trips/"+defaultTripID+"/markers/add", tok, body2)

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, "")+"?q=스타벅스", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200", w.Code)
	}
	var markers []domain.Marker
	json.NewDecoder(w.Body).Decode(&markers)
	if len(markers) != 1 {
		t.Errorf("len=%d want 1", len(markers))
	}
	if len(markers) > 0 && !strings.Contains(markers[0].Name, "스타벅스") {
		t.Errorf("name=%q does not contain 스타벅스", markers[0].Name)
	}
}

func TestGetMarkers_TripNotFound(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, markerPath("00000000-0000-0000-0000-000000000000", ""), tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestGetMarkers_NoToken(t *testing.T) {
	router, _, _ := setupMarker(t)
	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, ""), "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── GET /:markerId ────────────────────────────────────────────────────────────

func TestGetMarker_Success(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, created.ID), tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.ID != created.ID {
		t.Errorf("id=%q want %q", m.ID, created.ID)
	}
}

func TestGetMarker_NotFound(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, "00000000-0000-0000-0000-000000000000"), tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestGetMarker_TripMismatch(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	otherTripID := "trip-other"
	fs.Trips = append(fs.Trips, domain.Trip{ID: otherTripID})
	fs.AddRoute("route-other", otherTripID)

	w := doMarker(router, http.MethodGet, markerPath(otherTripID, created.ID), tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestGetMarker_NoToken(t *testing.T) {
	router, _, _ := setupMarker(t)
	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, "some-id"), "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── PATCH /:markerId ──────────────────────────────────────────────────────────

func TestUpdateMarker_Name(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"name": "수정된 장소"})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.Name != "수정된 장소" {
		t.Errorf("name=%q want 수정된 장소", m.Name)
	}
}

func TestUpdateMarker_LatLng(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{
		"latitude": 37.9999, "longitude": 126.9999,
	})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.Latitude != 37.9999 {
		t.Errorf("latitude=%v want 37.9999", m.Latitude)
	}
}

func TestUpdateMarker_LatWithoutLng(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"latitude": 37.5})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateMarker_BlankName(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"name": "   "})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateMarker_NameTooLong(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{
		"name": strings.Repeat("가", 101),
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateMarker_LatitudeOutOfRange(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{
		"latitude": 91, "longitude": 127.0,
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateMarker_LongitudeOutOfRange(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{
		"latitude": 37.5, "longitude": -181,
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestUpdateMarker_NullCategory(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)
	catID := "cat-1"
	for i := range fs.Markers {
		if fs.Markers[i].ID == created.ID {
			fs.Markers[i].CategoryID = &catID
		}
	}

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"category_id": nil})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.CategoryID != nil {
		t.Errorf("category_id=%v want nil", m.CategoryID)
	}
}

func TestUpdateMarker_NotFound(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, "00000000-0000-0000-0000-000000000000"), tok, map[string]any{"name": "수정"})
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestUpdateMarker_NoToken(t *testing.T) {
	router, _, _ := setupMarker(t)
	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, "some-id"), "", map[string]any{"name": "수정"})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestUpdateMarker_VisitTime(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)
	vt := "2026-07-01T00:00:00Z"

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"visit_time": vt})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.VisitTime == nil || *m.VisitTime != vt {
		t.Errorf("visit_time=%v want %q", m.VisitTime, vt)
	}
}

func TestUpdateMarker_ClearVisitTime(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)
	vt := "2026-07-01T00:00:00Z"
	for i := range fs.Markers {
		if fs.Markers[i].ID == created.ID {
			fs.Markers[i].VisitTime = &vt
		}
	}

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{"visit_time": nil})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var m domain.Marker
	json.NewDecoder(w.Body).Decode(&m)
	if m.VisitTime != nil {
		t.Errorf("visit_time=%v want nil", m.VisitTime)
	}
}

func TestUpdateMarker_BodyTooLarge(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodPatch, markerPath(defaultTripID, created.ID), tok, map[string]any{
		"address": strings.Repeat("x", 5000),
	})
	if w.Code != http.StatusRequestEntityTooLarge {
		t.Errorf("status=%d want 413", w.Code)
	}
}

// ── DELETE /:markerId ─────────────────────────────────────────────────────────

func TestDeleteMarker_Success(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)

	w := doMarker(router, http.MethodDelete, markerPath(defaultTripID, created.ID), tok, nil)
	if w.Code != http.StatusNoContent {
		t.Fatalf("status=%d want 204, body=%s", w.Code, w.Body)
	}
}

func TestDeleteMarker_ThenGet404(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)
	doMarker(router, http.MethodDelete, markerPath(defaultTripID, created.ID), tok, nil)

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, created.ID), tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("after delete: status=%d want 404", w.Code)
	}
}

func TestDeleteMarker_ThenNotInList(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	created := createMarker(t, router, tok, defaultTripID)
	doMarker(router, http.MethodDelete, markerPath(defaultTripID, created.ID), tok, nil)

	w := doMarker(router, http.MethodGet, markerPath(defaultTripID, ""), tok, nil)
	var markers []domain.Marker
	json.NewDecoder(w.Body).Decode(&markers)
	for _, m := range markers {
		if m.ID == created.ID {
			t.Errorf("deleted marker still in list: %s", created.ID)
		}
	}
}

func TestDeleteMarker_NotFound(t *testing.T) {
	router, fs, keys := setupMarker(t)
	tok := markerToken(t, keys, fs, "user-1")

	w := doMarker(router, http.MethodDelete, markerPath(defaultTripID, "00000000-0000-0000-0000-000000000000"), tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestDeleteMarker_NoToken(t *testing.T) {
	router, _, _ := setupMarker(t)
	w := doMarker(router, http.MethodDelete, markerPath(defaultTripID, "some-id"), "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}
