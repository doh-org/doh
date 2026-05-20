package middleware

import (
	"crypto/ecdsa"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const (
	UserIDKey    = "user_id"
	UserEmailKey = "user_email"
)

type supabaseClaims struct {
	jwt.RegisteredClaims
	Email string `json:"email"`
}

// Auth validates a Supabase ES256 JWT, then verifies the session is still
// active via the Supabase Auth server. Injects user_id and user_email into context.
func Auth(keys map[string]*ecdsa.PublicKey, supabaseURL, supabaseAnonKey string, client *http.Client) gin.HandlerFunc {
	if client == nil {
		client = &http.Client{Timeout: 5 * time.Second}
	}
	expectedIssuer := supabaseURL + "/auth/v1"
	userURL := supabaseURL + "/auth/v1/user"
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
			&supabaseClaims{},
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

		claims, ok := token.Claims.(*supabaseClaims)
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

		if !checkSupabaseSession(c, client, userURL, supabaseAnonKey, tokenStr) {
			return
		}

		c.Set(UserIDKey, claims.Subject)
		c.Set(UserEmailKey, claims.Email)
		c.Next()
	}
}

// checkSupabaseSession calls GET /auth/v1/user to verify the session is still
// active on Supabase's side. Returns false and aborts the context on failure.
func checkSupabaseSession(c *gin.Context, client *http.Client, userURL, anonKey, tokenStr string) bool {
	req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, userURL, nil)
	if err != nil {
		slog.Error("auth: build supabase request failed", "err", err)
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
		return false
	}
	req.Header.Set("Authorization", "Bearer "+tokenStr)
	req.Header.Set("apikey", anonKey)

	resp, err := client.Do(req)
	if err != nil {
		slog.Error("auth: supabase session check failed", "err", err)
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "인증이 필요합니다."})
		return false
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)

	if resp.StatusCode != http.StatusOK {
		slog.Warn("auth: supabase session invalid", "status", resp.StatusCode)
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "로그인이 필요합니다."})
		return false
	}
	return true
}
