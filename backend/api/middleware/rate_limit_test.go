package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func newRateLimitRouter() http.Handler {
	r := gin.New()
	r.POST("/login", RateLimit(), func(c *gin.Context) {
		c.Status(http.StatusOK)
	})
	return r
}

func doPost(router http.Handler, ip string) int {
	req := httptest.NewRequest(http.MethodPost, "/login", nil)
	req.RemoteAddr = ip + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w.Code
}

func TestRateLimit_Exceeded(t *testing.T) {
	router := newRateLimitRouter()
	ip := "10.0.1.1"
	t.Cleanup(func() { ipLimiters.Delete(ip) })

	for i := 1; i <= 11; i++ {
		code := doPost(router, ip)
		if i <= 10 {
			if code == http.StatusTooManyRequests {
				t.Errorf("request %d: got 429, want <429", i)
			}
		} else {
			if code != http.StatusTooManyRequests {
				t.Errorf("request %d: got %d, want 429", i, code)
			}
		}
	}
}

func TestRateLimit_IndependentByIP(t *testing.T) {
	router := newRateLimitRouter()
	ip1, ip2 := "10.0.2.1", "10.0.2.2"
	t.Cleanup(func() {
		ipLimiters.Delete(ip1)
		ipLimiters.Delete(ip2)
	})

	for i := 0; i < 10; i++ {
		doPost(router, ip1)
	}

	if code := doPost(router, ip2); code == http.StatusTooManyRequests {
		t.Error("ip2 should not be rate limited by ip1 exhaustion")
	}
}
