package testutil

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// FakeNaver는 검색·역지오코딩 업스트림을 재현한다.
type FakeNaver struct {
	Server      *httptest.Server
	SearchError int // 0이면 성공, 그 외 HTTP status
	GeoError    int
	LastQuery   string // 전달된 검색어 기록 (프록시 파라미터 검증용)
}

func NewFakeNaver(t *testing.T) *FakeNaver {
	t.Helper()
	fn := &FakeNaver{}

	mux := http.NewServeMux()

	mux.HandleFunc("/v1/search/local.json", func(w http.ResponseWriter, r *http.Request) {
		// 시크릿 헤더가 실제로 붙는지 확인 — 없으면 401 (실제 네이버와 동일)
		if r.Header.Get("X-Naver-Client-Secret") == "" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		if fn.SearchError != 0 {
			w.WriteHeader(fn.SearchError)
			return
		}
		fn.LastQuery = r.URL.Query().Get("query")
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"items":[{"title":"카페<b>테스트</b>","roadAddress":"서울 어딘가","mapx":"1270000000","mapy":"375000000"}]}`))
	})

	mux.HandleFunc("/map-reversegeocode/v2/gc", func(w http.ResponseWriter, r *http.Request) {
		if r.Header.Get("X-NCP-APIGW-API-KEY") == "" {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		if fn.GeoError != 0 {
			w.WriteHeader(fn.GeoError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"results":[{"name":"roadaddr","region":{"area1":{"name":"서울특별시"}}}]}`))
	})

	fn.Server = httptest.NewServer(mux)
	t.Cleanup(fn.Server.Close)
	return fn
}
