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

	group.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	group.POST("/add", tc.CreateTrip)
	group.GET("", tc.GetTrips)
	group.GET("/:tripId", tc.GetTrip)
	group.PATCH("/:tripId", tc.UpdateTrip)
	group.DELETE("/:tripId", tc.DeleteTrip)
}
