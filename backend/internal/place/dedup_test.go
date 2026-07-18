package place

import "testing"

// 기준 장소 쌍: 같은 가게가 네이버(전체 시/도명·건물명 붙음)와
// 카카오(축약 시/도명)에 다르게 표기된 상황을 재현
func naverBurger() Place {
	return Place{
		Provider:    ProviderNaver,
		Title:       "버거킹 강남점",
		RoadAddress: "서울특별시 강남구 강남대로 358 강남N타워 1층",
		Mapx:        127.0297, Mapy: 37.4923,
	}
}

func kakaoBurger() Place {
	return Place{
		Provider:    ProviderKakao,
		Title:       "버거킹 강남점",
		RoadAddress: "서울 강남구 강남대로 358",
		Mapx:        127.0298, Mapy: 37.4924, // 약 14m 차이
	}
}

// 3신호 모두 일치 → naver 제거, kakao 유지
func TestDedup_AllSignalsMatch(t *testing.T) {
	out := Dedup([]Place{naverBurger(), kakaoBurger()})
	if len(out) != 1 {
		t.Fatalf("len=%d want 1: %+v", len(out), out)
	}
	if out[0].Provider != ProviderKakao {
		t.Errorf("provider=%q want kakao 유지", out[0].Provider)
	}
}

// 2신호(이름+좌표) 일치 — 도로명은 다름 → 제거
func TestDedup_TitleAndCoords(t *testing.T) {
	n := naverBurger()
	n.RoadAddress = "서울특별시 강남구 테헤란로 1"
	out := Dedup([]Place{n, kakaoBurger()})
	if len(out) != 1 || out[0].Provider != ProviderKakao {
		t.Fatalf("out=%+v want kakao 1건", out)
	}
}

// 2신호(도로명+좌표) 일치 — 이름은 다름 → 제거
func TestDedup_RoadAndCoords(t *testing.T) {
	n := naverBurger()
	n.Title = "버거킹 강남역사거리점"
	out := Dedup([]Place{n, kakaoBurger()})
	if len(out) != 1 || out[0].Provider != ProviderKakao {
		t.Fatalf("out=%+v want kakao 1건", out)
	}
}

// 1신호(이름만) 일치 — 좌표 멀고 도로명 다름 → 별개 장소로 둘 다 유지
func TestDedup_OnlyTitleMatch(t *testing.T) {
	n := naverBurger()
	n.RoadAddress = "부산광역시 해운대구 해운대로 100"
	n.Mapx, n.Mapy = 129.16, 35.16 // 부산 — 좌표 멀리
	out := Dedup([]Place{n, kakaoBurger()})
	if len(out) != 2 {
		t.Fatalf("len=%d want 2 (별개 장소): %+v", len(out), out)
	}
}

// 양쪽 도로명 빈값 → 도로명 신호 불일치 취급 (이름만 일치로는 유지)
func TestDedup_BothEmptyRoadAddress(t *testing.T) {
	n := naverBurger()
	k := kakaoBurger()
	n.RoadAddress, k.RoadAddress = "", ""
	n.Mapx, n.Mapy = 129.16, 35.16 // 좌표도 멀게 → 남는 신호는 이름 1개
	out := Dedup([]Place{n, k})
	if len(out) != 2 {
		t.Fatalf("len=%d want 2 (빈 도로명은 일치 아님): %+v", len(out), out)
	}
}

// 도로명 정규화: 시/도 축약 + 건물번호 뒤 토큰 제거
func TestNormalizeRoadAddress(t *testing.T) {
	cases := []struct{ in, want string }{
		{"서울특별시 강남구 강남대로 358 강남N타워 1층", "서울 강남구 강남대로 358"},
		{"서울 강남구 강남대로 358", "서울 강남구 강남대로 358"},
		{"서울특별시 강남구 테헤란로44길 8", "서울 강남구 테헤란로44길 8"},
		{"전북특별자치도 전주시 완산구 전주객사3길 22", "전북 전주시 완산구 전주객사3길 22"},
		{"", ""},
	}
	for _, c := range cases {
		if got := normalizeRoadAddress(c.in); got != c.want {
			t.Errorf("in=%q got=%q want=%q", c.in, got, c.want)
		}
	}
}

// 이름 정규화: 공백·특수문자 제거 + 소문자화
func TestNormalizeTitle(t *testing.T) {
	if normalizeTitle("Burger King 강남점!") != normalizeTitle("burgerking강남점") {
		t.Error("공백·특수문자·대소문자 무시하고 같아야 함")
	}
}

// naver끼리는 제거 안 함 (교차 소스만 판정)
func TestDedup_SameProviderKept(t *testing.T) {
	a, b := naverBurger(), naverBurger()
	out := Dedup([]Place{a, b})
	if len(out) != 2 {
		t.Fatalf("len=%d want 2 (같은 소스는 유지)", len(out))
	}
}
