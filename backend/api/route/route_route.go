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

func NewRouteRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, tripsGroup *gin.RouterGroup) {
	rr := repository.NewRouteRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	tr := repository.NewTripRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	ru := usecase.NewRouteUsecase(rr, tr)
	rc := controller.NewRouteController(ru)

	days := tripsGroup.Group("/:tripId/days")
	days.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	days.GET("/:dayIndex/markers", rc.GetDayStops)
	days.PATCH("/:dayIndex/markers/:markerId", rc.UpdateStop)
	days.PATCH("/:dayIndex/reorder", rc.ReorderDay)
}
