package test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"

	"doh/backend/api/route"
)

// 헬스 라우터만 올린 최소 엔진 — env·JWT 키가 필요 없는 경로라 의존성 없이 검증 가능
func newHealthRouter() *gin.Engine {
	r := gin.New()
	route.NewHealthRouter(r)
	return r
}

func TestHealthReturnsOK(t *testing.T) {
	w := httptest.NewRecorder()
	newHealthRouter().ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/health", nil))

	if w.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", w.Code, http.StatusOK)
	}

	var body map[string]string
	if err := json.Unmarshal(w.Body.Bytes(), &body); err != nil {
		t.Fatalf("decode body: %v", err)
	}
	if body["status"] != "ok" {
		t.Errorf("status field = %q, want %q", body["status"], "ok")
	}
}

// 실패 경로: 헬스 라우터가 다른 경로까지 200으로 삼키면 안 된다
func TestHealthDoesNotHandleOtherPaths(t *testing.T) {
	w := httptest.NewRecorder()
	newHealthRouter().ServeHTTP(w, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	if w.Code != http.StatusNotFound {
		t.Errorf("status = %d, want %d", w.Code, http.StatusNotFound)
	}
}
