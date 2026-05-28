package route

import (
	"crypto/ecdsa"

	"github.com/gin-gonic/gin"

	"doh/backend/api/controller"
	"doh/backend/api/middleware"
	"doh/backend/bootstrap"
	"doh/backend/repository"
	"doh/backend/usecase"
)

func NewMarkerRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, tripsGroup *gin.RouterGroup) {
	mr := repository.NewMarkerRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	tr := repository.NewTripRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	mu := usecase.NewMarkerUsecase(mr, tr)
	mc := controller.NewMarkerController(mu)

	markers := tripsGroup.Group("/:tripId/markers")
	markers.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	markers.GET("", mc.GetMarkers)
	markers.GET("/:markerId", mc.GetMarker)
	markers.POST("/add", mc.CreateMarker)
	markers.PATCH("/:markerId", mc.UpdateMarker)
	markers.DELETE("/:markerId", mc.DeleteMarker)
}
