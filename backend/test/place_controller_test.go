package test

import (
	"encoding/json"
	"net/http"
	"strings"
	"testing"
)

// ── GET /api/v1/places/search (네이버+카카오 통합) ─────────────────────────

// 성공: 병합 순서(naver 먼저)·통일 형식 필드·양쪽 쿼리 전달 확인
func TestSearchPlaces_Success(t *testing.T) {
	router, fn, fk, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=%EC%B9%B4%ED%8E%98&x=127.0&y=37.5", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}

	var resp struct {
		Places []map[string]any `json:"places"`
	}
	json.NewDecoder(w.Body).Decode(&resp)
	// fake 데이터는 서로 다른 장소 → dedup 없이 2건
	if len(resp.Places) != 2 {
		t.Fatalf("places=%d want 2: %+v", len(resp.Places), resp.Places)
	}
	// 병합 순서: naver 먼저, kakao 뒤
	if resp.Places[0]["provider"] != "naver" || resp.Places[1]["provider"] != "kakao" {
		t.Errorf("병합 순서: %v, %v want naver, kakao", resp.Places[0]["provider"], resp.Places[1]["provider"])
	}
	// 네이버: <b> 제거 + ×1e7 → 도(degree) 변환
	if resp.Places[0]["title"] != "카페테스트" {
		t.Errorf("title=%q want <b> 제거", resp.Places[0]["title"])
	}
	if resp.Places[0]["mapx"] != 127.0 || resp.Places[0]["mapy"] != 37.5 {
		t.Errorf("coords=(%v,%v) want (127.0,37.5)", resp.Places[0]["mapx"], resp.Places[0]["mapy"])
	}
	// 카카오: 카테고리 구분자·필드 매핑
	if resp.Places[1]["category"] != "음식점>패스트푸드>햄버거" {
		t.Errorf("category=%q want 구분자 정규화", resp.Places[1]["category"])
	}
	if resp.Places[1]["telephone"] != "02-000-0000" {
		t.Errorf("telephone=%q want phone 매핑", resp.Places[1]["telephone"])
	}
	// 양쪽 업스트림에 같은 검색어 전달
	if fn.LastQuery != "카페" || fk.LastQuery != "카페" {
		t.Errorf("query naver=%q kakao=%q want 카페", fn.LastQuery, fk.LastQuery)
	}
}

// Authorization 헤더가 KakaoAK 형식으로 전달되는지
func TestSearchPlaces_KakaoAuthHeader(t *testing.T) {
	router, _, fk, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	if !strings.HasPrefix(fk.LastAuth, "KakaoAK ") {
		t.Errorf("auth=%q want KakaoAK 접두", fk.LastAuth)
	}
}

func TestSearchPlaces_MissingQuery(t *testing.T) {
	router, _, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search", tok, nil)
	if w.Code != http.StatusBadRequest {
		t.Fatalf("status=%d want 400", w.Code)
	}
}

// x·y는 쌍으로만, 범위 밖·비숫자 거부
func TestSearchPlaces_InvalidCoords(t *testing.T) {
	router, _, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	for _, qs := range []string{
		"q=x&x=127.0",      // x만
		"q=x&y=37.5",       // y만
		"q=x&x=181&y=37.5", // 경도 초과
		"q=x&x=127.0&y=91", // 위도 초과
		"q=x&x=abc&y=37.5", // 비숫자
	} {
		w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?"+qs, tok, nil)
		if w.Code != http.StatusBadRequest {
			t.Errorf("qs=%q status=%d want 400", qs, w.Code)
		}
	}
}

// zoom 미전달 → 반경 및 개수 기본값(radius 20000, size 15) 유지
func TestSearchPlaces_NoZoom_DefaultParams(t *testing.T) {
	router, _, fk, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x&x=127.0&y=37.5", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	if fk.LastRadius != "20000" || fk.LastSize != "15" {
		t.Errorf("radius=%q size=%q want 20000, 15", fk.LastRadius, fk.LastSize)
	}
}

// z=13(동네): radius=R(13)=3051, size=10
func TestSearchPlaces_ZoomTown(t *testing.T) {
	router, _, fk, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x&x=127.0&y=37.5&zoom=13", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	if fk.LastRadius != "3051" || fk.LastSize != "10" {
		t.Errorf("radius=%q size=%q want 3051, 10", fk.LastRadius, fk.LastSize)
	}
	if fk.LastX != "127.0" || fk.LastY != "37.5" {
		t.Errorf("coords=(%q,%q) want 전달됨", fk.LastX, fk.LastY)
	}
}

// z<9(전국): 좌표·radius 생략, size 15, 카카오는 전국 정확도순
func TestSearchPlaces_ZoomNationwide_NoCoords(t *testing.T) {
	router, _, fk, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x&x=127.0&y=37.5&zoom=7", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	if fk.LastX != "" || fk.LastY != "" || fk.LastRadius != "" {
		t.Errorf("x=%q y=%q radius=%q want 모두 생략", fk.LastX, fk.LastY, fk.LastRadius)
	}
	if fk.LastSize != "15" {
		t.Errorf("size=%q want 15", fk.LastSize)
	}
}

// zoom 형식·범위(0~21) 밖 → 400
func TestSearchPlaces_InvalidZoom(t *testing.T) {
	router, _, _, fs, keys := setupNaver(t)
	tok := accountToken(t, keys, fs)

	for _, qs := range []string{
		"q=x&zoom=abc", // 비숫자
		"q=x&zoom=22",  // 범위 초과
		"q=x&zoom=-1",  // 음수
	} {
		w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?"+qs, tok, nil)
		if w.Code != http.StatusBadRequest {
			t.Errorf("qs=%q status=%d want 400", qs, w.Code)
		}
	}
}

// 카카오만 실패 → 네이버 결과만 200
func TestSearchPlaces_KakaoDown_NaverOnly(t *testing.T) {
	router, _, fk, fs, keys := setupNaver(t)
	fk.Error = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp struct {
		Places []map[string]any `json:"places"`
	}
	json.NewDecoder(w.Body).Decode(&resp)
	if len(resp.Places) != 1 || resp.Places[0]["provider"] != "naver" {
		t.Fatalf("places=%+v want naver 1건", resp.Places)
	}
}

// 네이버만 실패 → 카카오 결과만 200
func TestSearchPlaces_NaverDown_KakaoOnly(t *testing.T) {
	router, fn, _, fs, keys := setupNaver(t)
	fn.SearchError = http.StatusTooManyRequests // 쿼터 초과 재현
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", tok, nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200, body=%s", w.Code, w.Body)
	}
	var resp struct {
		Places []map[string]any `json:"places"`
	}
	json.NewDecoder(w.Body).Decode(&resp)
	if len(resp.Places) != 1 || resp.Places[0]["provider"] != "kakao" {
		t.Fatalf("places=%+v want kakao 1건", resp.Places)
	}
}

// 둘 다 실패 → 502 (상세 미노출)
func TestSearchPlaces_BothDown(t *testing.T) {
	router, fn, fk, fs, keys := setupNaver(t)
	fn.SearchError = http.StatusInternalServerError
	fk.Error = http.StatusInternalServerError
	tok := accountToken(t, keys, fs)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", tok, nil)
	if w.Code != http.StatusBadGateway {
		t.Fatalf("status=%d want 502, body=%s", w.Code, w.Body)
	}
}

// 공개 프록시 — 무토큰 요청도 200.
func TestSearchPlaces_NoToken_Public(t *testing.T) {
	router, _, _, _, _ := setupNaver(t)

	w := doAccount(t, router, http.MethodGet, "/api/v1/places/search?q=x", "", nil)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200 (public), body=%s", w.Code, w.Body)
	}
}
