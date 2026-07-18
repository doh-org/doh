package route

import (
	"crypto/ecdsa"

	"github.com/gin-gonic/gin"

	"doh/backend/api/controller"
	"doh/backend/api/middleware"
	"doh/backend/bootstrap"
	"doh/backend/internal/kakao"
	"doh/backend/internal/naver"
)

// NewNaverRouter는 네이버 API 프록시 라우트를 등록한다.
// 공개(무인증) + IP rate limit — 반환값이 공개 장소 데이터뿐이라 인증 불필요,
// 남용은 rate limit으로 억제.
func NewNaverRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, v1 *gin.RouterGroup) {
	client := naver.NewClient(
		env.NaverSearchClientID, env.NaverSearchSecret,
		env.NcpMapClientID, env.NcpMapSecret, nil,
	)
	nc := controller.NewNaverController(client)
	// 통합 장소 검색: 네이버+카카오 병렬 호출 후 정규화·병합
	pc := controller.NewPlaceController(client, kakao.NewLocalClient(env.KakaoRestAPIKey, nil))

	g := v1.Group("")
	g.Use(middleware.RateLimit())
	g.GET("/places/search", pc.SearchPlaces)
	g.GET("/places/resolve", nc.ResolvePlace) // 공유 링크 → 장소
	g.GET("/geocode/reverse", nc.ReverseGeocode)
}
