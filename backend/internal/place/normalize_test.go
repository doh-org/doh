package place

import "testing"

// 네이버: <b> 제거, ×1e7 정수 문자열 → 도(degree) 변환
func TestFromNaver(t *testing.T) {
	raw := []byte(`{"items":[
		{"title":"버거킹 <b>강남</b>점","category":"음식점>햄버거","address":"서울 역삼동 815",
		 "roadAddress":"서울특별시 강남구 강남대로 358","telephone":"","link":"https://naver.example",
		 "mapx":"1270276000","mapy":"374979000"}
	]}`)

	places, err := FromNaver(raw)
	if err != nil {
		t.Fatalf("err=%v", err)
	}
	if len(places) != 1 {
		t.Fatalf("len=%d want 1", len(places))
	}
	p := places[0]
	if p.Provider != ProviderNaver {
		t.Errorf("provider=%q want naver", p.Provider)
	}
	if p.Title != "버거킹 강남점" {
		t.Errorf("title=%q want <b> 제거", p.Title)
	}
	if p.Mapx != 127.0276 || p.Mapy != 37.4979 {
		t.Errorf("coords=(%v,%v) want (127.0276,37.4979)", p.Mapx, p.Mapy)
	}
	if p.RoadAddress != "서울특별시 강남구 강남대로 358" {
		t.Errorf("roadAddress=%q", p.RoadAddress)
	}
}

// 카카오: x/y ParseFloat, 카테고리 " > " → ">" 정규화, 필드 매핑
func TestFromKakao(t *testing.T) {
	raw := []byte(`{"documents":[
		{"place_name":"버거킹 강남점","category_name":"음식점 > 패스트푸드 > 햄버거",
		 "address_name":"서울 강남구 역삼동 815","road_address_name":"서울 강남구 강남대로 358",
		 "phone":"02-000-0000","place_url":"http://place.map.kakao.com/1",
		 "x":"127.0297","y":"37.4923"}
	]}`)

	places, err := FromKakao(raw)
	if err != nil {
		t.Fatalf("err=%v", err)
	}
	if len(places) != 1 {
		t.Fatalf("len=%d want 1", len(places))
	}
	p := places[0]
	if p.Provider != ProviderKakao {
		t.Errorf("provider=%q want kakao", p.Provider)
	}
	if p.Category != "음식점>패스트푸드>햄버거" {
		t.Errorf("category=%q want 구분자 정규화", p.Category)
	}
	if p.Telephone != "02-000-0000" || p.Link != "http://place.map.kakao.com/1" {
		t.Errorf("telephone=%q link=%q 매핑 실패", p.Telephone, p.Link)
	}
	if p.Mapx != 127.0297 || p.Mapy != 37.4923 {
		t.Errorf("coords=(%v,%v)", p.Mapx, p.Mapy)
	}
}

// 좌표 파싱 실패 항목은 스킵, 나머지는 살아남는다
func TestFromNaver_BadCoordsSkipped(t *testing.T) {
	raw := []byte(`{"items":[
		{"title":"좌표없음","mapx":"","mapy":""},
		{"title":"비숫자","mapx":"abc","mapy":"374979000"},
		{"title":"정상","mapx":"1270276000","mapy":"374979000"}
	]}`)

	places, err := FromNaver(raw)
	if err != nil {
		t.Fatalf("err=%v", err)
	}
	if len(places) != 1 || places[0].Title != "정상" {
		t.Fatalf("places=%+v want 정상 1건", places)
	}
}

func TestFromKakao_BadCoordsSkipped(t *testing.T) {
	raw := []byte(`{"documents":[
		{"place_name":"좌표없음","x":"","y":""},
		{"place_name":"정상","x":"127.0","y":"37.5"}
	]}`)

	places, err := FromKakao(raw)
	if err != nil {
		t.Fatalf("err=%v", err)
	}
	if len(places) != 1 || places[0].Title != "정상" {
		t.Fatalf("places=%+v want 정상 1건", places)
	}
}

// 원본이 JSON이 아니면 에러 (호출자가 소스 실패로 처리)
func TestFromNaver_InvalidJSON(t *testing.T) {
	if _, err := FromNaver([]byte("not json")); err == nil {
		t.Fatal("want error")
	}
}
