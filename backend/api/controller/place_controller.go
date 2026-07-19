package controller

import (
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"sync"

	"github.com/gin-gonic/gin"

	"doh/backend/internal/kakao"
	"doh/backend/internal/naver"
	"doh/backend/internal/place"
)

// 네이버 SDK 카메라 줌 범위 (파라미터 검증용)
const (
	minZoomLevel = 0
	maxZoomLevel = 21
)

// PlaceController: 네이버+카카오 장소 검색을 병렬 호출해 통일 형식으로 응답
type PlaceController struct {
	naver *naver.Client
	kakao *kakao.LocalClient
}

func NewPlaceController(n *naver.Client, k *kakao.LocalClient) *PlaceController {
	return &PlaceController{naver: n, kakao: k}
}

// SearchPlaces: 통합 장소 검색. GET /places/search?q=&x=&y=&zoom=
// x=경도, y=위도 — 쌍으로만 허용되는 선택 파라미터.
// zoom=카메라 줌(0~21, 연속값) — 카카오 radius·size 티어 결정. 생략 시 20km·15 기본값.
func (pc *PlaceController) SearchPlaces(c *gin.Context) {
	query := strings.TrimSpace(c.Query("q"))
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "검색어를 입력해주세요."})
		return
	}
	x, y := strings.TrimSpace(c.Query("x")), strings.TrimSpace(c.Query("y"))
	if !validCoordPair(x, y) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 좌표입니다."})
		return
	}
	kp, ok := kakaoParams(strings.TrimSpace(c.Query("zoom")))
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 zoom 레벨입니다."})
		return
	}

	naverPlaces, naverErr, kakaoPlaces, kakaoErr := pc.searchBoth(c, query, x, y, kp)

	// 둘 다 실패 → 502, 한쪽만 실패 → 성공한 쪽만 응답
	if naverErr != nil && kakaoErr != nil {
		slog.Error("place search failed", "naverErr", naverErr, "kakaoErr", kakaoErr)
		c.JSON(http.StatusBadGateway, gin.H{"error": "장소 검색에 실패했습니다."})
		return
	}
	if naverErr != nil {
		slog.Warn("naver search failed, kakao only", "err", naverErr)
	}
	if kakaoErr != nil {
		slog.Warn("kakao search failed, naver only", "err", kakaoErr)
	}

	// 병합 순서: naver 먼저, kakao 뒤
	// 중복일 경우 kakao 쪽을 살림
	merged := place.Dedup(append(naverPlaces, kakaoPlaces...))
	c.JSON(http.StatusOK, gin.H{"places": merged})
}

// searchBoth: 두 소스를 병렬 호출하고 정규화까지 마친 결과 리턴
func (pc *PlaceController) searchBoth(c *gin.Context, query, x, y string, params place.KakaoSearchParams) (np []place.Place, ne error, kp []place.Place, ke error) {
	ctx := c.Request.Context()
	coordinate := ""
	if x != "" {
		coordinate = x + "," + y // 네이버는 "경도,위도" 단일 파라미터
	}
	// 전국 뷰 티어 → 카카오: 좌표 생략(기본: 전국 정확도순), 네이버: 유지
	kx, ky := x, y
	if !params.UseCoord {
		kx, ky = "", ""
	}

	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		body, err := pc.naver.SearchLocal(ctx, query, coordinate)
		if err != nil {
			ne = err
			return
		}
		np, ne = place.FromNaver(body)
	}()
	go func() {
		defer wg.Done()
		body, err := pc.kakao.SearchKeyword(ctx, query, kx, ky, params.Radius, params.Size)
		if err != nil {
			ke = err
			return
		}
		kp, ke = place.FromKakao(body)
	}()
	wg.Wait()
	return np, ne, kp, ke
}

// kakaoParams: zoom 문자열(카카오 검색 파라미터), 유효 여부(true)
func kakaoParams(zoom string) (place.KakaoSearchParams, bool) {
	// 미전달 → 기존 기본값(20km·15건) 유지
	if zoom == "" {
		return place.DefaultKakaoParams(), true
	}
	z, err := strconv.ParseFloat(zoom, 64)
	if err != nil || z < minZoomLevel || z > maxZoomLevel {
		return place.KakaoSearchParams{}, false
	}
	return place.KakaoParamsForZoom(z), true
}

// validCoordPair: x·y는 쌍으로만, 경도 -180~180 / 위도 -90~90.
func validCoordPair(x, y string) bool {
	// 둘 다 없음 → 좌표 미사용 검색
	if x == "" && y == "" {
		return true
	}
	// 한쪽만 있음 → 잘못된 요청
	if x == "" || y == "" {
		return false
	}
	lng, errX := strconv.ParseFloat(x, 64)
	lat, errY := strconv.ParseFloat(y, 64)
	return errX == nil && errY == nil &&
		lng >= -180 && lng <= 180 && lat >= -90 && lat <= 90
}
