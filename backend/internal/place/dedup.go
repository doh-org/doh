package place

import (
	"math"
	"regexp"
	"strings"
	"unicode"
)

// 동일 장소 판정 기준: 도로명·좌표·이름 중 2개 이상 일치 시 같은 장소로 판정
const (
	dedupMinSignals     = 2
	dedupDistanceMeters = 100 // 좌표 차이: dedupDistanceMeters 이내면 같은 위치
	earthRadiusMeters   = 6371000.0
)

// 1. 도로명
// 네이버는 전체 명칭, 카카오는 축약형 사용
// 시/도 전체 명칭 → 축약형
var regionShort = map[string]string{
	"서울특별시": "서울", "부산광역시": "부산", "대구광역시": "대구",
	"인천광역시": "인천", "광주광역시": "광주", "대전광역시": "대전",
	"울산광역시": "울산", "세종특별자치시": "세종", "경기도": "경기",
	"강원특별자치도": "강원", "충청북도": "충북", "충청남도": "충남",
	"전북특별자치도": "전북", "전라남도": "전남", "경상북도": "경북",
	"경상남도": "경남", "제주특별자치도": "제주",
}

// 건물번호 형태: "358", "12-3"
var buildingNoRe = regexp.MustCompile(`^\d+(-\d+)?$`)

// Dedup: 네이버·카카오 양쪽에 나온 동일 장소를 하나로
// 동일 판정 시: 필드가 더 많은 kakao 항목을 naver 인덱스로 승격해
// 병합 순서(네이버 관련도순)를 보존한다
func Dedup(places []Place) []Place {
	replaceWith := make([]int, len(places)) // naver 자리에 승격할 kakao 인덱스 (-1: 승격 없음)
	consumed := make([]bool, len(places))   // 승격돼 원래 자리에서 빠지는 kakao
	removed := make([]bool, len(places))    // 승격 없이 버려지는 naver
	for i := range replaceWith {
		replaceWith[i] = -1
	}

	for i, a := range places {
		if a.Provider != ProviderNaver {
			continue
		}
		for j, b := range places {
			if b.Provider != ProviderKakao {
				continue
			}
			if matchSignals(a, b) >= dedupMinSignals {
				// 이미 승격된 kakao → naver만 버림 (응답 중복 방지)
				// 아니면 → kakao를 이 naver 자리로 승격
				if consumed[j] {
					removed[i] = true
				} else {
					replaceWith[i] = j
					consumed[j] = true
				}
				break
			}
		}
	}

	out := make([]Place, 0, len(places))
	for i, p := range places {
		switch {
		case removed[i] || consumed[i]: // 버려진 naver / 자리 옮긴 kakao
		case replaceWith[i] >= 0:
			out = append(out, places[replaceWith[i]]) // naver 자리에 kakao
		default:
			out = append(out, p)
		}
	}
	return out
}

// matchSignals: 두 장소의 일치 개수를 카운트
func matchSignals(a, b Place) int {
	n := 0
	// 도로명: 빈값끼리 일치로 치면 오탐 → 양쪽 다 있어야 유효
	ra, rb := normalizeRoadAddress(a.RoadAddress), normalizeRoadAddress(b.RoadAddress)
	if ra != "" && ra == rb {
		n++
	}
	if haversineMeters(a.Mapy, a.Mapx, b.Mapy, b.Mapx) <= dedupDistanceMeters {
		n++
	}
	ta, tb := normalizeTitle(a.Title), normalizeTitle(b.Title)
	if ta != "" && ta == tb {
		n++
	}
	return n
}

// normalizeRoadAddress: 시/도 축약 통일 + "도로명+건물번호"까지만 남김
// 뒤 토큰(건물명·층)을 버린 뒤 공백을 정리
func normalizeRoadAddress(s string) string {
	fields := strings.Fields(s)
	if len(fields) == 0 {
		return ""
	}
	if short, ok := regionShort[fields[0]]; ok {
		fields[0] = short
	}
	// "...로/...길" 다음 토큰이 건물번호면 거기서 자르기
	for i := 0; i+1 < len(fields); i++ {
		endsRoad := strings.HasSuffix(fields[i], "로") || strings.HasSuffix(fields[i], "길")
		if endsRoad && buildingNoRe.MatchString(fields[i+1]) {
			fields = fields[:i+2]
			break
		}
	}
	return strings.Join(fields, " ")
}

// normalizeTitle: 공백·특수문자를 제거하고 소문자화
func normalizeTitle(s string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(s) {
		if unicode.IsLetter(r) || unicode.IsDigit(r) {
			b.WriteRune(r)
		}
	}
	return b.String()
}

// haversineMeters: 두 WGS84 좌표 사이 거리(미터) 계산
func haversineMeters(lat1, lng1, lat2, lng2 float64) float64 {
	toRad := func(deg float64) float64 { return deg * math.Pi / 180 }
	dLat := toRad(lat2 - lat1)
	dLng := toRad(lng2 - lng1)
	h := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(toRad(lat1))*math.Cos(toRad(lat2))*math.Sin(dLng/2)*math.Sin(dLng/2)
	return 2 * earthRadiusMeters * math.Asin(math.Sqrt(h))
}
