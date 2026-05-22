package testutil

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"

	"doh/backend/internal/auth"
	"doh/backend/internal/middleware"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// NewTestRouter는 실제 미들웨어·핸들러를 연결한 테스트용 Gin 라우터를 반환한다.
// supabaseURL에 FakeSupabase.Server.URL을, client에 FakeSupabase.Server.Client()를 전달한다.
func NewTestRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	svc := auth.NewServiceWithClient(supabaseURL, "fake-anon-key", "fake-key", client)
	h := auth.NewHandler(svc)

	r := gin.New()
	v1 := r.Group("/api/v1")
	authGroup := v1.Group("/auth")

	public := authGroup.Group("")
	public.Use(middleware.RateLimit())
	public.POST("/signup", h.Signup)
	public.POST("/login", h.Login)

	protected := authGroup.Group("")
	protected.Use(middleware.Auth(keys.PublicKeys, supabaseURL, "fake-anon-key", client))
	protected.POST("/logout", h.Logout)
	protected.GET("/me", h.Me)

	return r
}
