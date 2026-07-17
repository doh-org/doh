// Package place는 네이버·카카오 장소 검색 결과를 단일 형식으로 정규화·병합한다.
package place

import (
	"encoding/json"
	"log/slog"
	"strconv"
	"strings"
)

// 응답 provider 값
const (
	ProviderNaver = "naver"
	ProviderKakao = "kakao"
)

// 네이버 mapx/mapy는 WGS84 ×1e7 정수 문자열 → 나눠서 도(degree)로 복원
const naverMapScale = 1e7

// Place는 소스와 무관한 통일 장소 형식. 좌표는 WGS84 number.
type Place struct {
	Provider    string  `json:"provider"`
	Title       string  `json:"title"`
	Category    string  `json:"category"`
	Address     string  `json:"address"`
	RoadAddress string  `json:"roadAddress"`
	Telephone   string  `json:"telephone"`
	Link        string  `json:"link"`
	Mapx        float64 `json:"mapx"` // 경도
	Mapy        float64 `json:"mapy"` // 위도
}

type naverItem struct {
	Title       string `json:"title"`
	Link        string `json:"link"`
	Category    string `json:"category"`
	Telephone   string `json:"telephone"`
	Address     string `json:"address"`
	RoadAddress string `json:"roadAddress"`
	Mapx        string `json:"mapx"`
	Mapy        string `json:"mapy"`
}

// FromNaver는 네이버 지역검색 원본 JSON을 통일 형식으로 변환한다.
func FromNaver(raw []byte) ([]Place, error) {
	var resp struct {
		Items []naverItem `json:"items"`
	}
	if err := json.Unmarshal(raw, &resp); err != nil {
		return nil, err
	}

	places := make([]Place, 0, len(resp.Items))
	for _, it := range resp.Items {
		x, errX := strconv.ParseFloat(it.Mapx, 64)
		y, errY := strconv.ParseFloat(it.Mapy, 64)
		// 좌표 없이는 지도에 못 찍음 → 해당 항목만 스킵 (전체 실패 아님)
		if errX != nil || errY != nil {
			slog.Warn("naver place skipped: bad coords", "mapx", it.Mapx, "mapy", it.Mapy)
			continue
		}
		places = append(places, Place{
			Provider:    ProviderNaver,
			Title:       stripBold(it.Title),
			Category:    it.Category,
			Address:     it.Address,
			RoadAddress: it.RoadAddress,
			Telephone:   it.Telephone,
			Link:        it.Link,
			Mapx:        x / naverMapScale,
			Mapy:        y / naverMapScale,
		})
	}
	return places, nil
}

type kakaoDocument struct {
	PlaceName       string `json:"place_name"`
	CategoryName    string `json:"category_name"`
	AddressName     string `json:"address_name"`
	RoadAddressName string `json:"road_address_name"`
	Phone           string `json:"phone"`
	PlaceURL        string `json:"place_url"`
	X               string `json:"x"` // 경도, 소수 문자열
	Y               string `json:"y"` // 위도, 소수 문자열
}

// FromKakao는 카카오 키워드 검색 원본 JSON을 통일 형식으로 변환한다.
func FromKakao(raw []byte) ([]Place, error) {
	var resp struct {
		Documents []kakaoDocument `json:"documents"`
	}
	if err := json.Unmarshal(raw, &resp); err != nil {
		return nil, err
	}

	places := make([]Place, 0, len(resp.Documents))
	for _, d := range resp.Documents {
		x, errX := strconv.ParseFloat(d.X, 64)
		y, errY := strconv.ParseFloat(d.Y, 64)
		if errX != nil || errY != nil {
			slog.Warn("kakao place skipped: bad coords", "x", d.X, "y", d.Y)
			continue
		}
		places = append(places, Place{
			Provider:    ProviderKakao,
			Title:       d.PlaceName,
			Category:    strings.ReplaceAll(d.CategoryName, " > ", ">"), // 네이버 구분자에 맞춤
			Address:     d.AddressName,
			RoadAddress: d.RoadAddressName,
			Telephone:   d.Phone,
			Link:        d.PlaceURL,
			Mapx:        x,
			Mapy:        y,
		})
	}
	return places, nil
}

// stripBold는 네이버 title의 검색어 강조 태그(<b>)를 제거한다.
func stripBold(s string) string {
	s = strings.ReplaceAll(s, "<b>", "")
	return strings.ReplaceAll(s, "</b>", "")
}
