// Package naver는 시크릿이 필요한 네이버 API 호출을 백엔드에 격리한다.
// (시크릿을 앱에 넣으면 디컴파일로 추출 가능 → 과금·쿼터 도용)
package naver

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// 외부 엔드포인트. 테스트에서 fake 서버로 교체 가능한 seam.
var (
	SearchBaseURL  = "https://openapi.naver.com"
	GeocodeBaseURL = "https://maps.apigw.ntruss.com"
)

type Client struct {
	searchID     string // 네이버 개발자센터 (검색 오픈API)
	searchSecret string
	ncpID        string // NCP API Gateway (역지오코딩)
	ncpSecret    string
	httpClient   *http.Client
}

func NewClient(searchID, searchSecret, ncpID, ncpSecret string, client *http.Client) *Client {
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	return &Client{
		searchID:     searchID,
		searchSecret: searchSecret,
		ncpID:        ncpID,
		ncpSecret:    ncpSecret,
		httpClient:   client,
	}
}

// SearchLocal은 장소 검색 결과 JSON을 그대로 반환한다(패스스루).
// coordinate는 "경도,위도" 형식, 빈 문자열이면 생략.
func (c *Client) SearchLocal(ctx context.Context, query, coordinate string) ([]byte, error) {
	q := url.Values{}
	q.Set("query", query)
	q.Set("display", "15")
	if coordinate != "" {
		q.Set("coordinate", coordinate)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		SearchBaseURL+"/v1/search/local.json?"+q.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("X-Naver-Client-Id", c.searchID)
	req.Header.Set("X-Naver-Client-Secret", c.searchSecret)

	return c.do(req, "searchLocal")
}

// ReverseGeocode는 좌표→주소 변환 결과 JSON을 그대로 반환한다(패스스루).
func (c *Client) ReverseGeocode(ctx context.Context, lat, lng float64, orders string) ([]byte, error) {
	q := url.Values{}
	q.Set("coords", fmt.Sprintf("%f,%f", lng, lat)) // NCP는 "경도,위도" 순서
	q.Set("output", "json")
	q.Set("orders", orders)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		GeocodeBaseURL+"/map-reversegeocode/v2/gc?"+q.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("X-NCP-APIGW-API-KEY-ID", c.ncpID)
	req.Header.Set("X-NCP-APIGW-API-KEY", c.ncpSecret)

	return c.do(req, "reverseGeocode")
}

// do는 요청을 보내고 200 응답 본문을 반환한다. 응답 크기 256KB 제한.
func (c *Client) do(req *http.Request, op string) ([]byte, error) {
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 256*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		// 상세(쿼터 초과 등)는 로그로만 — 클라이언트엔 일반화된 에러
		return nil, fmt.Errorf("%s: upstream status %d", op, resp.StatusCode)
	}
	return body, nil
}
