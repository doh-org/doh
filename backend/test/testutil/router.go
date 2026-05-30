package testutil

import (
	"net/http"
	"testing"

	"github.com/gin-gonic/gin"

	"doh/backend/api/controller"
	"doh/backend/api/middleware"
	"doh/backend/internal/auth"
	"doh/backend/repository"
	"doh/backend/usecase"
)

func init() {
	gin.SetMode(gin.TestMode)
}

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
	markers.GET("", mc.GetMarkers)
	markers.GET("/:markerId", mc.GetMarker)
	markers.POST("/add", mc.CreateMarker)
	markers.PATCH("/:markerId", mc.UpdateMarker)
	markers.DELETE("/:markerId", mc.DeleteMarker)

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
