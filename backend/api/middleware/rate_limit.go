package middleware

import (
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/time/rate"
)

type ipEntry struct {
	limiter  *rate.Limiter
	lastSeen time.Time
}

// limiterGroup은 용도별로 독립된 IP 리미터 묶음.
// 일반 API와 메일 발송처럼 제한 강도가 달라야 하는 경우 서로 간섭하지 않게 분리한다.
type limiterGroup struct {
	entries   sync.Map      // key: IP 문자열, value: *ipEntry
	cleanOnce sync.Once     // 정리 고루틴은 그룹당 1개만
	every     time.Duration // 토큰 보충 간격
	burst     int           // 순간 허용량(토큰 버킷 크기)
	message   string        // 429 응답 안내 문구
}

// 일반 API용: IP당 분당 10회 (버킷 10, 6초마다 1개 보충)
var defaultGroup = &limiterGroup{
	every:   6 * time.Second,
	burst:   10,
	message: "요청이 너무 많습니다. 잠시 후 다시 시도해주세요.",
}

// 인증 코드 발송용: 메일 발송은 비용이 크고 스팸 악용 여지가 있어 훨씬 엄격하게.
// IP당 처음 연속 3회까지 허용, 이후 30초마다 1회.
var sendCodeGroup = &limiterGroup{
	every:   30 * time.Second,
	burst:   3,
	message: "인증 코드 요청이 너무 많습니다. 잠시 후 다시 시도해주세요.",
}

// 오래 안 본 IP 항목을 주기적으로 비워 메모리 누수를 막는다.
func (g *limiterGroup) startCleanup() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			g.entries.Range(func(k, v any) bool {
				if time.Since(v.(*ipEntry).lastSeen) > 10*time.Minute {
					g.entries.Delete(k)
				}
				return true
			})
		}
	}()
}

func (g *limiterGroup) get(ip string) *rate.Limiter {
	// "이 IP의 리미터가 이미 있나?" 조회
	if v, ok := g.entries.Load(ip); ok {
		e := v.(*ipEntry) // any로 꺼낸 값을 실제 타입으로 단언
		e.lastSeen = time.Now()
		return e.limiter
	}
	// 없다 → 새로 만들어 저장
	l := rate.NewLimiter(rate.Every(g.every), g.burst)
	g.entries.Store(ip, &ipEntry{limiter: l, lastSeen: time.Now()})
	return l
}

func (g *limiterGroup) middleware() gin.HandlerFunc {
	g.cleanOnce.Do(g.startCleanup)
	return func(c *gin.Context) {
		if !g.get(c.ClientIP()).Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": g.message,
			})
			return
		}
		c.Next()
	}
}

// RateLimit은 IP 기준 분당 10회로 제한하는 Gin 미들웨어를 반환한다.
func RateLimit() gin.HandlerFunc {
	return defaultGroup.middleware()
}

// SendCodeRateLimit은 인증 코드 (재)발송을 IP당 최초 3회, 이후 30초 1회로 제한한다.
func SendCodeRateLimit() gin.HandlerFunc {
	return sendCodeGroup.middleware()
}
