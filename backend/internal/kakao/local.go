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

// 외부 엔드포인트. 테스트에서 fake 서버로 교체 가능한 seam (naver 패턴 동일).
var LocalBaseURL = "https://dapi.kakao.com"

// LocalClient는 카카오 로컬 API(장소 키워드 검색)를 호출한다.
// REST API 키가 시크릿이라 백엔드에 격리한다 (앱에 넣으면 디컴파일로 추출 가능).
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

// SearchKeyword는 키워드 장소 검색 결과 JSON을 그대로 반환한다.
// x=경도, y=위도 문자열. 빈 문자열이면 좌표·radius 생략, sort 미지정(accuracy 기본).
func (c *LocalClient) SearchKeyword(ctx context.Context, query, x, y string, radius int) ([]byte, error) {
	q := url.Values{}
	q.Set("query", query)
	q.Set("size", "15") // 카카오 최대 15건
	// 좌표가 있으면 반경 검색 — 없으면 전국 정확도순
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

// do는 요청을 보내고 200 응답 본문을 반환한다. 응답 크기 256KB 제한.
// naver.do 복제(2회째) — 3회째 등장 시 공용화한다.
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
		// 상세(쿼터 초과 등)는 로그로만 — 클라이언트엔 일반화된 에러
		return nil, fmt.Errorf("%s: upstream status %d", op, resp.StatusCode)
	}
	return body, nil
}
