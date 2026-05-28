package test

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"doh/backend/domain"
	"doh/backend/test/testutil"
)

func setupTrip(t *testing.T) (http.Handler, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)
	router := testutil.NewTestTripRouter(t, fs.Server.URL, keys, fs.Server.Client())
	return router, fs, keys
}

func tripToken(t *testing.T, keys *testutil.TestKeys, fs *testutil.FakeSupabase, userID string) string {
	t.Helper()
	return keys.Sign(userID, userID+"@test.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))
}

func doTrip(router http.Handler, method, path, token string, body any) *httptest.ResponseRecorder {
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

// ── POST /api/v1/trips/add ────────────────────────────────────────────────────

func TestCreateTrip_Success(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{
		"title": "제주도 여행",
	})
	if w.Code != http.StatusCreated {
		t.Fatalf("status=%d want 201, body=%s", w.Code, w.Body)
	}
	var trip domain.Trip
	json.NewDecoder(w.Body).Decode(&trip)
	if trip.ID == "" {
		t.Error("id is empty")
	}
	if trip.Title != "제주도 여행" {
		t.Errorf("title=%q want 제주도 여행", trip.Title)
	}
}

func TestCreateTrip_WithOptionalFields(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	desc := "바다 보기"
	dest := "제주"
	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{
		"title":       "여름 휴가",
		"description": desc,
		"destination": dest,
		"start_date":  "2026-08-01",
		"end_date":    "2026-08-07",
	})
	if w.Code != http.StatusCreated {
		t.Fatalf("status=%d want 201, body=%s", w.Code, w.Body)
	}
}

func TestCreateTrip_EmptyTitle(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": ""})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateTrip_TitleTooLong(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{
		"title": strings.Repeat("가", 51),
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateTrip_InvalidDateRange(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{
		"title":      "날짜오류",
		"start_date": "2026-08-10",
		"end_date":   "2026-08-01",
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

func TestCreateTrip_NoAuth(t *testing.T) {
	router, _, _ := setupTrip(t)
	w := doTrip(router, http.MethodPost, "/api/v1/trips/add", "", map[string]any{"title": "여행"})
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

// ── GET /api/v1/trips ─────────────────────────────────────────────────────────

func TestGetTrips_Empty(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodGet, "/api/v1/trips", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var trips []domain.Trip
	json.NewDecoder(w.Body).Decode(&trips)
	if len(trips) != 0 {
		t.Errorf("len=%d want 0", len(trips))
	}
}

func TestGetTrips_ReturnsList(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	// 여행 2개 생성
	doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "여행A"})
	doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "여행B"})

	w := doTrip(router, http.MethodGet, "/api/v1/trips", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200", w.Code)
	}
	var trips []domain.Trip
	json.NewDecoder(w.Body).Decode(&trips)
	if len(trips) != 2 {
		t.Errorf("len=%d want 2", len(trips))
	}
}

// ── GET /api/v1/trips/:tripId ─────────────────────────────────────────────────

func TestGetTrip_Success(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	// 생성 후 ID 획득
	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "단건조회"})
	if cw.Code != http.StatusCreated {
		t.Fatalf("create failed: %d %s", cw.Code, cw.Body)
	}
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodGet, "/api/v1/trips/"+created.ID, tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var got domain.Trip
	json.NewDecoder(w.Body).Decode(&got)
	if got.ID != created.ID {
		t.Errorf("id=%q want %q", got.ID, created.ID)
	}
}

func TestGetTrip_NotFound(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodGet, "/api/v1/trips/no-such-id", tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

// ── PATCH /api/v1/trips/:tripId ───────────────────────────────────────────────

func TestUpdateTrip_Success(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "원본"})
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodPatch, "/api/v1/trips/"+created.ID, tok, map[string]any{"title": "수정됨"})
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var updated domain.Trip
	json.NewDecoder(w.Body).Decode(&updated)
	if updated.Title != "수정됨" {
		t.Errorf("title=%q want 수정됨", updated.Title)
	}
}

func TestUpdateTrip_Forbidden(t *testing.T) {
	router, fs, keys := setupTrip(t)
	ownerTok := tripToken(t, keys, fs, "owner")
	otherTok := tripToken(t, keys, fs, "other")

	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", ownerTok, map[string]any{"title": "여행"})
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodPatch, "/api/v1/trips/"+created.ID, otherTok, map[string]any{"title": "탈취"})
	if w.Code != http.StatusForbidden {
		t.Errorf("status=%d want 403", w.Code)
	}
}

func TestUpdateTrip_NotFound(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodPatch, "/api/v1/trips/no-such", tok, map[string]any{"title": "수정"})
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}

func TestUpdateTrip_TitleTooLong(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "원본"})
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodPatch, fmt.Sprintf("/api/v1/trips/%s", created.ID), tok, map[string]any{
		"title": strings.Repeat("가", 51),
	})
	if w.Code != http.StatusBadRequest {
		t.Errorf("status=%d want 400", w.Code)
	}
}

// ── DELETE /api/v1/trips/:tripId ──────────────────────────────────────────────

func TestDeleteTrip_Success(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", tok, map[string]any{"title": "삭제대상"})
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodDelete, "/api/v1/trips/"+created.ID, tok, nil)
	if w.Code != http.StatusNoContent {
		t.Fatalf("status=%d want 204, body=%s", w.Code, w.Body)
	}

	// 삭제 후 조회 → 404
	gw := doTrip(router, http.MethodGet, "/api/v1/trips/"+created.ID, tok, nil)
	if gw.Code != http.StatusNotFound {
		t.Errorf("after delete: status=%d want 404", gw.Code)
	}
}

func TestDeleteTrip_Forbidden(t *testing.T) {
	router, fs, keys := setupTrip(t)
	ownerTok := tripToken(t, keys, fs, "owner")
	otherTok := tripToken(t, keys, fs, "other")

	cw := doTrip(router, http.MethodPost, "/api/v1/trips/add", ownerTok, map[string]any{"title": "여행"})
	var created domain.Trip
	json.NewDecoder(cw.Body).Decode(&created)

	w := doTrip(router, http.MethodDelete, "/api/v1/trips/"+created.ID, otherTok, nil)
	if w.Code != http.StatusForbidden {
		t.Errorf("status=%d want 403", w.Code)
	}
}

func TestDeleteTrip_NotFound(t *testing.T) {
	router, fs, keys := setupTrip(t)
	tok := tripToken(t, keys, fs, "user-1")

	w := doTrip(router, http.MethodDelete, "/api/v1/trips/no-such", tok, nil)
	if w.Code != http.StatusNotFound {
		t.Errorf("status=%d want 404", w.Code)
	}
}
