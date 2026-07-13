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

func doPost(router http.Handler, path, ip string) int {
	req := httptest.NewRequest(http.MethodPost, path, nil)
	req.RemoteAddr = ip + ":12345"
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w.Code
}

func TestRateLimit_Exceeded(t *testing.T) {
	router := newRateLimitRouter()
	ip := "10.0.1.1"
	t.Cleanup(func() { defaultGroup.entries.Delete(ip) })

	for i := 1; i <= 11; i++ {
		code := doPost(router, "/login", ip)
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
		defaultGroup.entries.Delete(ip1)
		defaultGroup.entries.Delete(ip2)
	})

	for i := 0; i < 10; i++ {
		doPost(router, "/login", ip1)
	}

	if code := doPost(router, "/login", ip2); code == http.StatusTooManyRequests {
		t.Error("ip2 should not be rate limited by ip1 exhaustion")
	}
}

// 코드 발송 리미터: 최초 3회 허용, 4번째부터 429
func TestSendCodeRateLimit_Exceeded(t *testing.T) {
	r := gin.New()
	r.POST("/resend", SendCodeRateLimit(), func(c *gin.Context) {
		c.Status(http.StatusOK)
	})
	ip := "10.0.3.1"
	t.Cleanup(func() { sendCodeGroup.entries.Delete(ip) })

	for i := 1; i <= 4; i++ {
		code := doPost(r, "/resend", ip)
		if i <= 3 {
			if code != http.StatusOK {
				t.Errorf("request %d: got %d, want 200", i, code)
			}
		} else {
			if code != http.StatusTooManyRequests {
				t.Errorf("request %d: got %d, want 429", i, code)
			}
		}
	}
}

// 일반 리미터와 발송 리미터는 서로 소모량을 공유하지 않는다
func TestSendCodeRateLimit_IndependentFromDefault(t *testing.T) {
	r := gin.New()
	r.POST("/login", RateLimit(), func(c *gin.Context) { c.Status(http.StatusOK) })
	r.POST("/resend", SendCodeRateLimit(), func(c *gin.Context) { c.Status(http.StatusOK) })
	ip := "10.0.4.1"
	t.Cleanup(func() {
		defaultGroup.entries.Delete(ip)
		sendCodeGroup.entries.Delete(ip)
	})

	// 발송 리미터 소진 → 일반 API는 여전히 통과해야 함
	for i := 0; i < 3; i++ {
		doPost(r, "/resend", ip)
	}
	if code := doPost(r, "/resend", ip); code != http.StatusTooManyRequests {
		t.Fatalf("resend: got %d, want 429", code)
	}
	if code := doPost(r, "/login", ip); code == http.StatusTooManyRequests {
		t.Error("login should not be limited by resend exhaustion")
	}
}
