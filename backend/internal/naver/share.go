package naver

import (
	"context"
	"errors"
	"fmt"
	"html"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"strings"
)

// 공유 링크가 향할 수 있는 호스트 allowlist (SSRF 방지 — 내부망 등 임의 주소 차단).
// 테스트에서 fake 서버 호스트를 추가할 수 있도록 var로 seam을 연다.
var ShareHosts = map[string]bool{
	"naver.me":            true, // 공유 단축링크
	"map.naver.com":       true, // PC 지도
	"m.map.naver.com":     true,
	"m.place.naver.com":   true, // 모바일 플레이스 (단축링크의 최종 목적지)
	"place.map.naver.com": true,
}

// allowlist 밖 호스트 → 컨트롤러가 400으로 매핑하기 위한 센티널 에러
var ErrShareHostNotAllowed = errors.New("share: host not allowed")

const (
	maxShareRedirects = 5          // 단축링크 → 최종 페이지는 보통 1~2회
	maxShareBodyBytes = 512 * 1024 // og:title은 <head>에 있어 앞부분이면 충분
)

// og:title 추출 — 속성 순서(property/content)가 페이지마다 달라 양방향 패턴 준비
var (
	ogTitleRe    = regexp.MustCompile(`(?i)<meta[^>]*property=["']og:title["'][^>]*content=["']([^"']*)["']`)
	ogTitleRevRe = regexp.MustCompile(`(?i)<meta[^>]*content=["']([^"']*)["'][^>]*property=["']og:title["']`)
	// "장소명 : 네이버", "장소명 : 네이버 지도" 등 사이트명 꼬리 제거
	naverSuffixRe = regexp.MustCompile(`\s*:\s*네이버.*$`)
)

// ResolveShareTitle은 네이버 공유 링크(naver.me 등)를 리다이렉트 끝까지 따라가
// 최종 페이지의 og:title에서 장소명을 추출한다.
func (c *Client) ResolveShareTitle(ctx context.Context, rawURL string) (string, error) {
	u, err := url.Parse(rawURL)
	if err != nil || !ShareHosts[u.Hostname()] {
		return "", ErrShareHostNotAllowed
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawURL, nil)
	if err != nil {
		return "", err
	}
	// 기본 Go UA는 봇으로 차단될 수 있어 모바일 브라우저 UA로 요청
	req.Header.Set("User-Agent",
		"Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36")

	resp, err := c.shareClient().Do(req)
	if err != nil {
		// CheckRedirect 에러는 *url.Error로 감싸져 나옴 → 센티널로 복원
		var uerr *url.Error
		if errors.As(err, &uerr) && errors.Is(uerr.Err, ErrShareHostNotAllowed) {
			return "", ErrShareHostNotAllowed
		}
		return "", err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("share: upstream status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, maxShareBodyBytes))
	if err != nil {
		return "", err
	}

	title := extractOgTitle(string(body))
	if title == "" {
		return "", errors.New("share: og:title not found")
	}
	return title, nil
}

// shareClient는 리다이렉트마다 호스트를 재검증하는 전용 클라이언트를 만든다.
// (기본 클라이언트는 redirect 정책이 없어 임의 호스트로 따라갈 수 있음)
func (c *Client) shareClient() *http.Client {
	return &http.Client{
		Transport: c.httpClient.Transport,
		Timeout:   c.httpClient.Timeout,
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= maxShareRedirects {
				return errors.New("share: too many redirects")
			}
			if !ShareHosts[req.URL.Hostname()] {
				return ErrShareHostNotAllowed
			}
			return nil
		},
	}
}

// extractOgTitle은 HTML에서 og:title 값을 찾아 네이버 사이트명 꼬리를 정리한다.
func extractOgTitle(page string) string {
	m := ogTitleRe.FindStringSubmatch(page)
	if m == nil {
		m = ogTitleRevRe.FindStringSubmatch(page)
	}
	if m == nil {
		return ""
	}
	title := html.UnescapeString(m[1]) // &amp; 등 HTML 엔티티 복원
	title = naverSuffixRe.ReplaceAllString(title, "")
	return strings.TrimSpace(title)
}
