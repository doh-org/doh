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

func NewAuthRouter(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, group *gin.RouterGroup) {
	ur := repository.NewUserRepository(env.SupabaseURL, env.SupabaseAnonKey, env.SupabaseServiceRoleKey, nil)
	au := usecase.NewAuthUsecase(ur, env.TurnstileSecretKey)
	ac := controller.NewAuthController(au)

	public := group.Group("")
	public.Use(middleware.RateLimit())
	public.POST("/signup", ac.Signup)
	public.POST("/login", ac.Login)
	public.POST("/recover", ac.Recover)

	protected := group.Group("")
	protected.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	protected.POST("/logout", ac.Logout)
	protected.GET("/me", ac.Me)
	protected.PUT("/password", ac.ChangePassword)
	protected.DELETE("/me", ac.DeleteMe)
}
