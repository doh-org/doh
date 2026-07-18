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

// 카카오 반경 검색 기본값(미터). 네이버는 coordinate 기준 정렬만 지원해 미적용.
const defaultRadiusMeters = 20000

// PlaceController: 네이버+카카오 장소 검색을 병렬 호출해 통일 형식으로 응답
type PlaceController struct {
	naver *naver.Client
	kakao *kakao.LocalClient
}

func NewPlaceController(n *naver.Client, k *kakao.LocalClient) *PlaceController {
	return &PlaceController{naver: n, kakao: k}
}

// SearchPlaces: 통합 장소 검색. GET /places/search?q=&x=&y=
// x=경도, y=위도 — 쌍으로만 허용되는 선택 파라미터.
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

	naverPlaces, naverErr, kakaoPlaces, kakaoErr := pc.searchBoth(c, query, x, y)

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
func (pc *PlaceController) searchBoth(c *gin.Context, query, x, y string) (np []place.Place, ne error, kp []place.Place, ke error) {
	ctx := c.Request.Context()
	coordinate := ""
	if x != "" {
		coordinate = x + "," + y // 네이버는 "경도,위도" 단일 파라미터
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
		body, err := pc.kakao.SearchKeyword(ctx, query, x, y, defaultRadiusMeters)
		if err != nil {
			ke = err
			return
		}
		kp, ke = place.FromKakao(body)
	}()
	wg.Wait()
	return np, ne, kp, ke
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
