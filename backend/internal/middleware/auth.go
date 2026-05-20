package middleware

import (
	"crypto/ecdsa"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const UserIDKey = "user_id"

// Auth validates a Supabase ES256 JWT. Verifies alg, exp, iss.
// On success, injects user_id into the Gin context.
func Auth(keys map[string]*ecdsa.PublicKey, supabaseURL, supabaseAnonKey string, client *http.Client) gin.HandlerFunc {
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	expectedIssuer := supabaseURL + "/auth/v1"
	parser := jwt.NewParser(
		jwt.WithValidMethods([]string{"ES256"}),
		jwt.WithExpirationRequired(),
		jwt.WithIssuedAt(),
	)

	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if !strings.HasPrefix(header, "Bearer ") {
			slog.Warn("missing or invalid authorization header")
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
			return
		}
		tokenStr := strings.TrimPrefix(header, "Bearer ")

		token, err := parser.ParseWithClaims(
			tokenStr,
			&jwt.RegisteredClaims{},
			func(t *jwt.Token) (any, error) {
				kid, _ := t.Header["kid"].(string)
				pub, ok := keys[kid]
				if !ok {
					return nil, fmt.Errorf("unknown kid: %q", kid)
				}
				return pub, nil
			},
		)
		if err != nil || !token.Valid {
			slog.Warn("jwt parse failed", "err", err)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
			return
		}

		claims, ok := token.Claims.(*jwt.RegisteredClaims)
		if !ok || claims.Subject == "" {
			slog.Warn("jwt claims invalid: empty subject")
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
			return
		}

		if claims.Issuer != expectedIssuer {
			slog.Warn("jwt issuer mismatch", "got", claims.Issuer, "want", expectedIssuer)
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
			return
		}

		c.Set(UserIDKey, claims.Subject)
		c.Next()
	}
}
