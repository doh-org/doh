package place

import "testing"

// 티어 경계·radius 계산 검증. 기대값은 R(z)=25,000,000/2^z 수기 계산.
func TestKakaoParamsForZoom(t *testing.T) {
	tests := []struct {
		name string
		zoom float64
		want KakaoSearchParams
	}{
		// 경계 직전 → 전국 뷰, 좌표 생략
		{"전국 뷰(z<9)", 8.99, KakaoSearchParams{Radius: 0, Size: 15, UseCoord: false}},
		// R(9)=48,828 > 상한 → 20km로 잘림
		{"도시 하한(z=9)", 9, KakaoSearchParams{Radius: 20000, Size: 15, UseCoord: true}},
		// R(11)=12,207 — 상한 미만이라 그대로
		{"도시(z=11)", 11, KakaoSearchParams{Radius: 12207, Size: 15, UseCoord: true}},
		// 동네 티어 진입 → size 10
		{"동네 하한(z=12)", 12, KakaoSearchParams{Radius: 6103, Size: 10, UseCoord: true}},
		// 골목 티어 진입 → size 5
		{"골목 하한(z=15)", 15, KakaoSearchParams{Radius: 762, Size: 5, UseCoord: true}},
		// SDK 최대 줌 — radius가 아주 작아짐(하한 없음)
		{"최대 줌(z=21)", 21, KakaoSearchParams{Radius: 11, Size: 5, UseCoord: true}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := KakaoParamsForZoom(tt.zoom); got != tt.want {
				t.Errorf("zoom=%v got=%+v want=%+v", tt.zoom, got, tt.want)
			}
		})
	}
}

// zoom 미전달 시 기존 동작(20km·15건) 유지
func TestDefaultKakaoParams(t *testing.T) {
	want := KakaoSearchParams{Radius: 20000, Size: 15, UseCoord: true}
	if got := DefaultKakaoParams(); got != want {
		t.Errorf("got=%+v want=%+v", got, want)
	}
}
