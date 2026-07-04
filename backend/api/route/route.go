package route

import (
	"crypto/ecdsa"

	"github.com/gin-gonic/gin"

	"doh/backend/bootstrap"
)

func Setup(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, r *gin.Engine) {
	v1 := r.Group("/api/v1")
	NewAuthRouter(env, keys, v1.Group("/auth"))
	tripsGroup := v1.Group("/trips")
	NewTripRouter(env, keys, tripsGroup)
	NewCategoryRouter(env, keys, tripsGroup)
	NewMarkerRouter(env, keys, tripsGroup)
	NewRouteRouter(env, keys, tripsGroup)
	NewNaverRouter(env, keys, v1) // /places/search, /geocode/reverse 프록시
}
