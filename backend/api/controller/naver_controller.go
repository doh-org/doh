package controller

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"

	"doh/backend/internal/naver"
)

// NaverController는 시크릿이 필요한 네이버 API를 대신 호출하는 프록시.
type NaverController struct {
	client *naver.Client
}

func NewNaverController(client *naver.Client) *NaverController {
	return &NaverController{client: client}
}

// SearchPlaces는 장소 검색 프록시. GET /places/search?q=&coordinate=
func (nc *NaverController) SearchPlaces(c *gin.Context) {
	query := strings.TrimSpace(c.Query("q"))
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "검색어를 입력해주세요."})
		return
	}
	// coordinate는 "경도,위도" 선택 파라미터 — 형식만 느슨히 확인
	coordinate := strings.TrimSpace(c.Query("coordinate"))
	if coordinate != "" && strings.Count(coordinate, ",") != 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 좌표 형식입니다."})
		return
	}

	body, err := nc.client.SearchLocal(c.Request.Context(), query, coordinate)
	if err != nil {
		slog.Error("naver search proxy failed", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "장소 검색에 실패했습니다."})
		return
	}
	c.Data(http.StatusOK, "application/json", body) // 네이버 응답 패스스루
}

// ReverseGeocode는 좌표→주소 변환 프록시. GET /geocode/reverse?lat=&lng=&orders=
func (nc *NaverController) ReverseGeocode(c *gin.Context) {
	lat, err1 := strconv.ParseFloat(c.Query("lat"), 64)
	lng, err2 := strconv.ParseFloat(c.Query("lng"), 64)
	// 위경도 유효 범위 검증
	if err1 != nil || err2 != nil || lat < -90 || lat > 90 || lng < -180 || lng > 180 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 좌표입니다."})
		return
	}

	orders := c.DefaultQuery("orders", "roadaddr,addr")
	if !isValidOrders(orders) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "잘못된 orders 값입니다."})
		return
	}

	body, err := nc.client.ReverseGeocode(c.Request.Context(), lat, lng, orders)
	if err != nil {
		slog.Error("naver reverse geocode proxy failed", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "주소 조회에 실패했습니다."})
		return
	}
	c.Data(http.StatusOK, "application/json", body)
}

// ResolvePlace는 네이버 공유 링크를 장소 검색 결과로 변환한다.
// GET /places/resolve?url= — 링크 → og:title 장소명 → 지역 검색 순서.
func (nc *NaverController) ResolvePlace(c *gin.Context) {
	rawURL := strings.TrimSpace(c.Query("url"))
	if rawURL == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "링크를 입력해주세요."})
		return
	}

	title, err := nc.client.ResolveShareTitle(c.Request.Context(), rawURL)
	if err != nil {
		// allowlist 밖 호스트 → 사용자 입력 문제(400), 나머지는 업스트림 문제(502)
		if errors.Is(err, naver.ErrShareHostNotAllowed) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "지원하지 않는 링크입니다."})
			return
		}
		slog.Error("naver share resolve failed", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "링크 해석에 실패했습니다."})
		return
	}

	body, err := nc.client.SearchLocal(c.Request.Context(), title, "")
	if err != nil {
		slog.Error("naver search after resolve failed", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "장소 검색에 실패했습니다."})
		return
	}

	// 검색 결과에 장소명(query)을 얹어 반환 — 클라이언트가 첫 항목을 사용
	var parsed map[string]any
	if err := json.Unmarshal(body, &parsed); err != nil {
		slog.Error("naver search response parse failed", "err", err)
		c.JSON(http.StatusBadGateway, gin.H{"error": "장소 검색에 실패했습니다."})
		return
	}
	items, _ := parsed["items"].([]any) // 형식이 다르면 nil → 빈 배열로
	if items == nil {
		items = []any{}
	}
	c.JSON(http.StatusOK, gin.H{"query": title, "items": items})
}

// isValidOrders는 NCP orders 파라미터를 허용 목록으로 검증한다(임의 값 전달 차단).
func isValidOrders(orders string) bool {
	allowed := map[string]bool{
		"legalcode": true, "admcode": true, "addr": true, "roadaddr": true,
	}
	for _, o := range strings.Split(orders, ",") {
		if !allowed[o] {
			return false
		}
	}
	return true
}
