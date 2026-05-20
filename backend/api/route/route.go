package route

import (
	"crypto/ecdsa"

	"github.com/gin-gonic/gin"

	"doh/backend/bootstrap"
)

func Setup(env *bootstrap.Env, keys map[string]*ecdsa.PublicKey, r *gin.Engine) {
	v1 := r.Group("/api/v1")
	NewAuthRouter(env, keys, v1.Group("/auth"))
}
