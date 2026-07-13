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
	au := usecase.NewAuthUsecase(ur)
	ac := controller.NewAuthController(au)

	public := group.Group("")
	public.Use(middleware.RateLimit())
	public.POST("/signup", ac.Signup)              // 1단계: 확인 코드 발송
	public.POST("/verify-signup", ac.VerifySignup) // 2단계: 코드 검증(브루트포스 방지 rate limit 포함)
	public.POST("/complete-signup", ac.CompleteSignup) // 3단계: 비번·닉네임 설정 + 자동 로그인
	// 코드 (재)발송은 메일 발송 비용·스팸 방지로 더 엄격한 발송 전용 rate limit 추가
	public.POST("/resend-signup", middleware.SendCodeRateLimit(), ac.ResendSignup) // 확인 코드 재발송
	public.POST("/login", ac.Login)
	public.POST("/recover", middleware.SendCodeRateLimit(), ac.Recover) // 재설정 코드 발송·재발송
	public.POST("/verify-recovery-code", ac.VerifyRecoveryCode) // 코드 브루트포스 방지 rate limit 포함
	public.POST("/recovery-password", ac.RecoveryPassword)
	public.POST("/refresh", ac.Refresh)

	protected := group.Group("")
	protected.Use(middleware.Auth(keys, env.SupabaseURL, env.SupabaseAnonKey, nil))
	protected.POST("/logout", ac.Logout)
	protected.GET("/me", ac.Me)
	// 재인증(현재 비번 확인)이 로그인 API를 타므로 브루트포스 방지 rate limit 적용
	protected.PUT("/password", middleware.RateLimit(), ac.ChangePassword)
	protected.DELETE("/me", ac.DeleteMe)
}
