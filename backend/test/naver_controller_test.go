package test

import (
	"encoding/json"
	"net/http"
	"testing"

	"doh/backend/internal/naver"
	"doh/backend/test/testutil"
)

// setupNaver는 fake 업스트림으로 프록시 라우터를 구성한다.
// naver 패키지 엔드포인트 seam을 fake 서버로 교체하고 테스트 후 복원.
func setupNaver(t *testing.T) (http.Handler, *testutil.FakeNaver, *testutil.FakeSupabase, *testutil.TestKeys) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	fn := testutil.NewFakeNaver(t)

	oldSearch, oldGeo := naver.SearchBaseURL, naver.GeocodeBaseURL
	naver.SearchBaseURL = fn.Server.URL
	naver.GeocodeBaseURL = fn.Server.URL
	t.Cleanup(func() {
		naver.SearchBaseURL = oldSearch
		naver.GeocodeBaseURL = oldGeo
	})

	keys := testutil.NewTestKeys(t)
	router := testutil.NewTestNaverRouter(t, fs.Server.URL, keys, fn.Server.Client())
	return router, fn, fs, keys
}

// ── GET /api/v1/places/search ─────────────────────────────────────────────

func TestSearchPlaces_Success(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=%EC%B9%B4%ED%8E%98&coordinate=127.0,37.5", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	// 네이버 응답이 그대로 패스스루되는지
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["items"] == nil {
		t.Error("expected items in passthrough response")
	}
	if fn.LastQuery != "카페" {
		t.Errorf("query=%q want 카페", fn.LastQuery)
	}
}

func TestSearchPlaces_MissingQuery(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search", tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", w.Code)
	}
}

func TestSearchPlaces_Unauthorized(t *testing.T) {
	router, _, _, _ := setupNaver(t)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", w.Code)
	}
}

// 업스트림 장애 → 502 (상세 미노출)
func TestSearchPlaces_UpstreamError(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	fn.SearchError = http.StatusTooManyRequests // 쿼터 초과 재현
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", tok, nil)
	if w.Code != http.StatusBadGateway {
		t.Fatalf("status=%d want 502, body=%s", w.Code, w.Body)
	}
}

// ── GET /api/v1/geocode/reverse ───────────────────────────────────────────

func TestReverseGeocode_Success(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/geocode/reverse?lat=37.5665&lng=126.9780", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	if resp["results"] == nil {
		t.Error("expected results in passthrough response")
	}
}

func TestReverseGeocode_InvalidCoords(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	for _, qs := range []string{"", "lat=91&lng=127", "lat=abc&lng=127", "lat=37.5&lng=181"} {
		w := doAccount(t, router, http.MethodGet, "/api/v1/geocode/reverse?"+qs, tok, nil)
		if w.Code != http.StatusBadRequest {
			t.Errorf("qs=%q status=%d want 400", qs, w.Code)
		}
	}
}

// 허용 외 orders 값 → 400 (임의 파라미터 전달 차단)
func TestReverseGeocode_InvalidOrders(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/geocode/reverse?lat=37.5&lng=127&orders=evil", tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", w.Code)
	}
}

func TestReverseGeocode_UpstreamError(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	fn.GeoError = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/geocode/reverse?lat=37.5&lng=127", tok, nil)
	if w.Code != http.StatusBadGateway {
		t.Fatalf("status=%d want 502", w.Code)
	}
}
