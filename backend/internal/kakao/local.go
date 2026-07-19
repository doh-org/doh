package kakao

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

// 테스트에서 fake 서버로 교체 가능
var LocalBaseURL = "https://dapi.kakao.com"

type LocalClient struct {
	restKey    string // 카카오 developers REST API 키
	httpClient *http.Client
}

func NewLocalClient(restKey string, client *http.Client) *LocalClient {
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	return &LocalClient{restKey: restKey, httpClient: client}
}

// SearchKeyword: 키워드 장소 검색 결과 JSON을 그대로 반환
// x=경도, y=위도 문자열. 빈 문자열이면 좌표·radius 생략, sort 기본 accuracy
// size는 결과 개수(카카오 최대 15) — 줌 티어에 따라 호출자가 결정
func (c *LocalClient) SearchKeyword(ctx context.Context, query, x, y string, radius, size int) ([]byte, error) {
	q := url.Values{}
	q.Set("query", query)
	q.Set("size", strconv.Itoa(size))
	// 좌표가 있으면 반경 검색(없으면 전국 정확도순)
	if x != "" && y != "" {
		q.Set("x", x)
		q.Set("y", y)
		q.Set("radius", strconv.Itoa(radius))
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		LocalBaseURL+"/v2/local/search/keyword.json?"+q.Encode(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "KakaoAK "+c.restKey)

	return c.do(req, "searchKeyword")
}

// 요청 보내고 200 응답 반환. 응답 크기 256KB 제한.
// naver.do와 동일
func (c *LocalClient) do(req *http.Request, op string) ([]byte, error) {
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
		return nil, fmt.Errorf("%s: upstream status %d", op, resp.StatusCode)
	}
	return body, nil
}
