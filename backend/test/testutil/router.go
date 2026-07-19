package testutil

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"

	"doh/backend/api/controller"
	"doh/backend/api/middleware"
	"doh/backend/internal/kakao"
	"doh/backend/internal/naver"
	"doh/backend/repository"
	"doh/backend/usecase"
)

func init() {
	gin.SetMode(gin.TestMode)
}

// NewTestAuthRouter: controller → usecase → repository 경로로 auth 전체 엔드포인트를 구성
func NewTestAuthRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	ur := repository.NewUserRepository(supabaseURL, "fake-anon-key", "fake-service-key", client)
	au := usecase.NewAuthUsecase(ur)
	ac := controller.NewAuthController(au)

	r := gin.New()
	authGroup := r.Group("/api/v1/auth")

	public := authGroup.Group("")
	public.Use(middleware.RateLimit())
	public.POST("/signup", ac.Signup)
	public.POST("/verify-signup", ac.VerifySignup) // 코드 브루트포스 방지 rate limit 포함
	public.POST("/complete-signup", ac.CompleteSignup)
	public.POST("/resend-signup", middleware.SendCodeRateLimit(), ac.ResendSignup) // 발송 전용 rate limit
	public.POST("/login", ac.Login)
	public.POST("/recover", middleware.SendCodeRateLimit(), ac.Recover) // 발송 전용 rate limit
	public.POST("/verify-recovery-code", ac.VerifyRecoveryCode) // 코드 브루트포스 방지 rate limit 포함
	public.POST("/recovery-password", ac.RecoveryPassword)
	public.POST("/refresh", ac.Refresh)

	protected := authGroup.Group("")
	protected.Use(middleware.Auth(keys.PublicKeys, supabaseURL, "fake-anon-key", client))
	protected.POST("/logout", ac.Logout)
	protected.GET("/me", ac.Me)
	protected.PUT("/password", middleware.RateLimit(), ac.ChangePassword) // 재인증 브루트포스 방지
	protected.DELETE("/me", ac.DeleteMe)

	return r
}

func NewTestMarkerRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	mr := repository.NewMarkerRepository(supabaseURL, "fake-anon-key", client)
	tr := repository.NewTripRepository(supabaseURL, "fake-anon-key", client)
	mu := usecase.NewMarkerUsecase(mr, tr)
	mc := controller.NewMarkerController(mu)

	r := gin.New()
	trips := r.Group("/api/v1/trips")
	trips.Use(middleware.Auth(keys.PublicKeys, supabaseURL, "fake-anon-key", client))
	markers := trips.Group("/:tripId/markers")
	markers.GET("/:markerId", mc.GetMarkers) // 정수=day 목록(day=0 미정), UUID=단건
	markers.POST("/add", mc.CreateMarker)
	markers.PATCH("/:markerId", mc.UpdateMarker)
	markers.DELETE("/:markerId", mc.DeleteMarker)

	return r
}

func NewTestRouteRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	rr := repository.NewRouteRepository(supabaseURL, "fake-anon-key", client)
	tr := repository.NewTripRepository(supabaseURL, "fake-anon-key", client)
	ru := usecase.NewRouteUsecase(rr, tr)
	rc := controller.NewRouteController(ru)

	r := gin.New()
	trips := r.Group("/api/v1/trips")
	trips.Use(middleware.Auth(keys.PublicKeys, supabaseURL, "fake-anon-key", client))
	days := trips.Group("/:tripId/days")
	days.PATCH("/:dayIndex/markers/:markerId", rc.UpdateStop)
	days.PATCH("/:dayIndex/reorder", rc.ReorderDay)

	return r
}

func NewTestTripRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	tr := repository.NewTripRepository(supabaseURL, "fake-anon-key", client)
	tu := usecase.NewTripUsecase(tr)
	tc := controller.NewTripController(tu)

	r := gin.New()
	trips := r.Group("/api/v1/trips")
	trips.Use(middleware.Auth(keys.PublicKeys, supabaseURL, "fake-anon-key", client))
	trips.POST("/add", tc.CreateTrip)
	trips.GET("", tc.GetTrips)
	trips.GET("/:tripId", tc.GetTrip)
	trips.PATCH("/:tripId", tc.UpdateTrip)
	trips.DELETE("/:tripId", tc.DeleteTrip)

	return r
}

func NewTestNaverRouter(
	t *testing.T,
	supabaseURL string,
	keys *TestKeys,
	client *http.Client,
) http.Handler {
	t.Helper()
	naverClient := naver.NewClient("fake-search-id", "fake-search-secret", "fake-ncp-id", "fake-ncp-secret", client)
	nc := controller.NewNaverController(naverClient)
	pc := controller.NewPlaceController(naverClient, kakao.NewLocalClient("fake-rest-key", client))

	r := gin.New()
	g := r.Group("/api/v1")
	// 운영과 동일: 공개(무인증) + rate limit
	g.Use(middleware.RateLimit())
	g.GET("/places/search", pc.SearchPlaces)
	g.GET("/places/resolve", nc.ResolvePlace) // 공유 링크 → 장소
	g.GET("/geocode/reverse", nc.ReverseGeocode)

	return r
}
