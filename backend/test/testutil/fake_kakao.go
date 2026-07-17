package testutil

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// FakeKakao는 카카오 로컬 키워드 검색 업스트림을 재현한다.
type FakeKakao struct {
	Server    *httptest.Server
	Error     int    // 0이면 성공, 그 외 HTTP status
	LastQuery string // 전달된 검색어 기록 (프록시 파라미터 검증용)
	LastAuth  string // Authorization 헤더 기록 (KakaoAK 전달 검증용)
}

func NewFakeKakao(t *testing.T) *FakeKakao {
	t.Helper()
	fk := &FakeKakao{}

	mux := http.NewServeMux()
	mux.HandleFunc("/v2/local/search/keyword.json", func(w http.ResponseWriter, r *http.Request) {
		fk.LastAuth = r.Header.Get("Authorization")
		// KakaoAK 헤더 없으면 401 (실제 카카오와 동일)
		if !strings.HasPrefix(fk.LastAuth, "KakaoAK ") {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		if fk.Error != 0 {
			w.WriteHeader(fk.Error)
			return
		}
		fk.LastQuery = r.URL.Query().Get("query")
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"documents":[{"place_name":"버거킹 강남점","category_name":"음식점 > 패스트푸드 > 햄버거","address_name":"서울 강남구 역삼동 815","road_address_name":"서울 강남구 강남대로 358","phone":"02-000-0000","place_url":"http://place.map.kakao.com/1","x":"127.0297","y":"37.4923"}]}`))
	})

	fk.Server = httptest.NewServer(mux)
	t.Cleanup(fk.Server.Close)
	return fk
}
