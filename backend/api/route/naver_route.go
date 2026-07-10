package route

import (
	"crypto/ecdsa"

	"github.com/gin-gonic/gin"

	"doh/backend/api/controller"
	"doh/backend/api/middleware"
	"doh/backend/bootstrap"
	"doh/backend/internal/naver"
)

// NewNaverRouter는 네이버 API 프록시 라우트를 등록한다.
// JWT 필수 + rate limit — 시크릿 보호 목적이므로 익명 호출 차단.
func NewNaverRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, v1 *gin.RouterGroup) {
	client := naver.NewClient(
		env.NaverSearchClientID, env.NaverSearchSecret,
		env.NcpMapClientID, env.NcpMapSecret, nil,
	)
	nc := controller.NewNaverController(client)

	g := v1.Group("")
	g.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	g.Use(middleware.RateLimit())
	g.GET("/places/search", nc.SearchPlaces)
	g.GET("/places/resolve", nc.ResolvePlace) // 공유 링크 → 장소
	g.GET("/geocode/reverse", nc.ReverseGeocode)
}
