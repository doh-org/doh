package test

import (
	"encoding/json"
	"net/http"
	"net/url"
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
	// 공유 링크 리졸버가 fake 서버(127.0.0.1)로 요청할 수 있게 allowlist에 추가
	fakeHost := mustHostname(t, fn.Server.URL)
	naver.ShareHosts[fakeHost] = true
	t.Cleanup(func() {
		naver.SearchBaseURL = oldSearch
		naver.GeocodeBaseURL = oldGeo
		delete(naver.ShareHosts, fakeHost)
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

// ── GET /api/v1/places/resolve ────────────────────────────────────────────

// mustHostname은 URL에서 호스트명(포트 제외)을 꺼낸다.
func mustHostname(t *testing.T, rawURL string) string {
	t.Helper()
	u, err := url.Parse(rawURL)
	if err != nil {
		t.Fatalf("parse url %q: %v", rawURL, err)
	}
	return u.Hostname()
}

// 성공 경로: 단축링크 리다이렉트 → og:title 추출 → 그 이름으로 검색
func TestResolvePlace_Success(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	shareURL := url.QueryEscape(fn.Server.URL + "/share/redirect")
	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve?url="+shareURL, tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp map[string]any
	json.NewDecoder(w.Body).Decode(&resp)
	// og:title의 " : 네이버" 꼬리가 제거된 장소명인지
	if resp["query"] != "카페테스트" {
		t.Errorf("query=%q want 카페테스트", resp["query"])
	}
	if resp["items"] == nil {
		t.Error("expected items in response")
	}
	// 추출한 장소명이 검색 쿼리로 쓰였는지
	if fn.LastQuery != "카페테스트" {
		t.Errorf("search query=%q want 카페테스트", fn.LastQuery)
	}
}

func TestResolvePlace_MissingURL(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve", tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", w.Code)
	}
}

// allowlist 밖 호스트 → 400 (SSRF 차단)
func TestResolvePlace_DisallowedHost(t *testing.T) {
	router, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	shareURL := url.QueryEscape("https://evil.example.com/place")
	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve?url="+shareURL, tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

// 리다이렉트가 allowlist 밖으로 향하면 차단 → 502가 아닌 400
func TestResolvePlace_DisallowedRedirect(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	shareURL := url.QueryEscape(fn.Server.URL + "/share/evil")
	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve?url="+shareURL, tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400, body=%s", w.Code, w.Body)
	}
}

func TestResolvePlace_UpstreamError(t *testing.T) {
	router, fn, fs, keys := setupNaver(t)
	fn.ShareError = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	shareURL := url.QueryEscape(fn.Server.URL + "/share/place")
	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve?url="+shareURL, tok, nil)
	if w.Code != http.StatusBadGateway {
		t.Fatalf("status=%d want 502, body=%s", w.Code, w.Body)
	}
}

func TestResolvePlace_Unauthorized(t *testing.T) {
	router, _, _, _ := setupNaver(t)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/resolve?url=https://naver.me/x", "", nil)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", w.Code)
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
