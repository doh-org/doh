package place

import "math"

// 카메라 줌 → 카카오 radius·size 정책. 티어 표는 docs/api.md 참고.
const (
	// 화면 반경 근사식 R(z) = 25,000,000 / 2^z 의 분자.
	// 156,543(zoom 0 픽셀당 m) × cos(위도 37°)≈0.8 × 화면 반폭 200dp
	screenRadiusNumerator = 25_000_000

	kakaoMaxRadiusMeters = 20_000 // 카카오 radius 파라미터 상한(m)

	kakaoSizeWide  = 15 // 전국·도시 뷰 결과 개수 (카카오 최대)
	kakaoSizeTown  = 10 // 동네 뷰 결과 개수
	kakaoSizeAlley = 5  // 골목 뷰 결과 개수

	zoomCity  = 9  // 이 미만 → 전국·광역 뷰, 좌표 생략
	zoomTown  = 12 // 도시 ↔ 동네 경계
	zoomAlley = 15 // 동네 ↔ 골목 경계
)

// KakaoSearchParams: 카카오 키워드 검색에 넣을 값 묶음
type KakaoSearchParams struct {
	Radius   int  // 반경(m) — UseCoord=false면 무시
	Size     int  // 결과 개수(1~15)
	UseCoord bool // false → 좌표·radius 생략(전국 정확도순)
}

// DefaultKakaoParams: zoom 미전달 시 기존 동작 유지(반경 20km, 15건)
func DefaultKakaoParams() KakaoSearchParams {
	return KakaoSearchParams{Radius: kakaoMaxRadiusMeters, Size: kakaoSizeWide, UseCoord: true}
}

// KakaoParamsForZoom: 카메라 줌을 티어에 매핑해 radius·size 결정
func KakaoParamsForZoom(zoom float64) KakaoSearchParams {
	// 전국 뷰 → 반경 검색이 의미 없어 좌표 자체를 생략
	if zoom < zoomCity {
		return KakaoSearchParams{Size: kakaoSizeWide, UseCoord: false}
	}

	r := screenRadius(zoom)
	switch {
	// 도시 → 화면 반경이 카카오 상한(20km)을 넘을 수 있어 잘라냄
	case zoom < zoomTown:
		return KakaoSearchParams{Radius: min(r, kakaoMaxRadiusMeters), Size: kakaoSizeWide, UseCoord: true}
	// 동네
	case zoom < zoomAlley:
		return KakaoSearchParams{Radius: r, Size: kakaoSizeTown, UseCoord: true}
	// 골목 → 화면이 좁으니 결과도 적게
	default:
		return KakaoSearchParams{Radius: r, Size: kakaoSizeAlley, UseCoord: true}
	}
}

// screenRadius: 줌 z에서 화면에 보이는 대략적 반경(m). 오차 ±15% 근사.
func screenRadius(zoom float64) int {
	return int(screenRadiusNumerator / math.Pow(2, zoom))
}
