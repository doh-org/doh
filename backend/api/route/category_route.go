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

func NewCategoryRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, tripsGroup *gin.RouterGroup) {
	cr := repository.NewCategoryRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	tr := repository.NewTripRepository(env.SupabaseURL, env.SupabaseAnonKey, nil)
	cu := usecase.NewCategoryUsecase(cr, tr)
	cc := controller.NewCategoryController(cu)

	categories := tripsGroup.Group("/:tripId/categories")
	categories.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	categories.GET("", cc.GetCategories)
}
