package testutil

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// FakeKakao 카카오 로컬 키워드 검색 업스트림 재현
type FakeKakao struct {
	Server    *httptest.Server
	Error     int    // 0은 성공, 그외는 HTTP status
	LastQuery string // 전달된 검색어(프록시 파라미터 검증용)
	LastAuth  string // Authorization 헤더(KakaoAK 전달 검증용)
}

// t: 테스트 핸들(실패 보고·정리용), 반환: 서버 주소·기록 필드를 가진 *FakeKakao
func NewFakeKakao(t *testing.T) *FakeKakao {
	t.Helper() // 실패 시 이 함수가 아니라 호출한 테스트 줄로 위치 보고
	fk := &FakeKakao{}

	mux := http.NewServeMux() // 빈 라우터 생성 (미등록 경로는 404)

	// 카카오 검색 경로에 핸들러 등록 — HandleFunc(경로 문자열, 핸들러 함수)
	// 핸들러가 fk를 클로저로 캡처해 요청 내용 기록
	// w: 응답 쓰기, r: 받은 요청
	mux.HandleFunc("/v2/local/search/keyword.json", func(w http.ResponseWriter, r *http.Request) {
		fk.LastAuth = r.Header.Get("Authorization") // "KakaoAK {REST키}"

		// "KakaoAK "로 시작 안 함 → 401
		if !strings.HasPrefix(fk.LastAuth, "KakaoAK ") {
			w.WriteHeader(http.StatusUnauthorized)
			return
		}

		// Error 설정됨 → 해당 status로 응답
		if fk.Error != 0 {
			w.WriteHeader(fk.Error)
			return
		}

		// 성공 → 검색어 저장 후 고정 JSON 1건 응답
		fk.LastQuery = r.URL.Query().Get("query") // ?query= 값
		w.Header().Set("Content-Type", "application/json")

		// 실제 카카오 documents 포맷 (WriteHeader 생략 시 200)
		w.Write([]byte(`{"documents":[{"place_name":"버거킹 강남점","category_name":"음식점 > 패스트푸드 > 햄버거","address_name":"서울 강남구 역삼동 815","road_address_name":"서울 강남구 강남대로 358","phone":"02-000-0000","place_url":"http://place.map.kakao.com/1","x":"127.0297","y":"37.4923"}]}`))
	})

	fk.Server = httptest.NewServer(mux) // ServeMux가 http.Handler 구현 → 테스트 서버 핸들러로 사용
	t.Cleanup(fk.Server.Close) // 테스트 종료 시 서버 자동 종료
	return fk
}
