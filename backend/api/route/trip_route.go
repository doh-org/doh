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

func NewTripRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, group *gin.RouterGroup) {
	tr := repository.NewTripRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	tu := usecase.NewTripUsecase(tr)
	tc := controller.NewTripController(tu)

	protected := group.Group("")
	protected.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	protected.GET("", tc.GetTrips)
	protected.GET("/:tripId", tc.GetTrip)
	protected.PATCH("/:tripId", tc.UpdateTrip)
	protected.DELETE("/:tripId", tc.DeleteTrip)
}
