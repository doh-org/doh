package middleware_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"

	"doh/backend/api/middleware"
	"doh/backend/test/testutil"
)

func init() {
	gin.SetMode(gin.TestMode)
}

func newAuthRouter(fs *testutil.FakeSupabase, keys *testutil.TestKeys) http.Handler {
	r := gin.New()
	r.GET("/protected",
		middleware.Auth(keys.PublicKeys, fs.Server.URL, "fake-anon-key", fs.Server.Client()),
		func(c *gin.Context) {
			c.JSON(http.StatusOK, gin.H{
				"user_id": c.GetString(middleware.UserIDKey),
				"email":   c.GetString(middleware.UserEmailKey),
			})
		},
	)
	return r
}

func doGet(router http.Handler, token string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodGet, "/protected", nil)
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	w := httptest.NewRecorder()
	router.ServeHTTP(w, req)
	return w
}

func TestAuth_ValidToken(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)
	token := keys.Sign("user-123", "test@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))

	w := doGet(newAuthRouter(fs, keys), token)
	if w.Code != http.StatusOK {
		t.Errorf("status=%d want 200, body=%s", w.Code, w.Body)
	}
}

func TestAuth_InjectsUserIDAndEmail(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)
	token := keys.Sign("user-abc", "hello@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))

	w := doGet(newAuthRouter(fs, keys), token)
	if w.Code != http.StatusOK {
		t.Fatalf("status=%d want 200", w.Code)
	}
	var body map[string]string
	json.NewDecoder(w.Body).Decode(&body)
	if body["user_id"] != "user-abc" {
		t.Errorf("user_id=%q want user-abc", body["user_id"])
	}
	if body["email"] != "hello@example.com" {
		t.Errorf("email=%q want hello@example.com", body["email"])
	}
}

func TestAuth_NoToken(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)

	w := doGet(newAuthRouter(fs, keys), "")
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestAuth_InvalidToken(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)

	w := doGet(newAuthRouter(fs, keys), "invalid.token.here")
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestAuth_ExpiredToken(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)
	token := keys.Sign("user-123", "test@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(-time.Hour))

	w := doGet(newAuthRouter(fs, keys), token)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestAuth_WrongIssuer(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	keys := testutil.NewTestKeys(t)
	token := keys.Sign("user-123", "test@example.com", "https://wrong-issuer.com/auth/v1", time.Now().Add(time.Hour))

	w := doGet(newAuthRouter(fs, keys), token)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401", w.Code)
	}
}

func TestAuth_RevokedSession(t *testing.T) {
	fs := testutil.NewFakeSupabase(t)
	fs.SessionValid = false
	keys := testutil.NewTestKeys(t)
	token := keys.Sign("user-123", "test@example.com", fs.Server.URL+"/auth/v1", time.Now().Add(time.Hour))

	w := doGet(newAuthRouter(fs, keys), token)
	if w.Code != http.StatusUnauthorized {
		t.Errorf("status=%d want 401, body=%s", w.Code, w.Body)
	}
}
