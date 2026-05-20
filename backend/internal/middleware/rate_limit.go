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

var (
	ipLimiters sync.Map
	cleanOnce  sync.Once
)

func startCleanup() {
	go func() {
		ticker := time.NewTicker(5 * time.Minute)
		defer ticker.Stop()
		for range ticker.C {
			ipLimiters.Range(func(k, v any) bool {
				if time.Since(v.(*ipEntry).lastSeen) > 10*time.Minute {
					ipLimiters.Delete(k)
				}
				return true
			})
		}
	}()
}

func getLimiter(ip string) *rate.Limiter {
	if v, ok := ipLimiters.Load(ip); ok {
		e := v.(*ipEntry)
		e.lastSeen = time.Now()
		return e.limiter
	}
	// 분당 10회: 토큰 버킷 10, 6초마다 1개 보충
	l := rate.NewLimiter(rate.Every(6*time.Second), 10)
	ipLimiters.Store(ip, &ipEntry{limiter: l, lastSeen: time.Now()})
	return l
}

// RateLimit은 IP 기준 분당 10회로 제한하는 Gin 미들웨어를 반환한다.
func RateLimit() gin.HandlerFunc {
	cleanOnce.Do(startCleanup)
	return func(c *gin.Context) {
		if !getLimiter(c.ClientIP()).Allow() {
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{
				"error": "요청이 너무 많습니다. 잠시 후 다시 시도해주세요.",
			})
			return
		}
		c.Next()
	}
}
