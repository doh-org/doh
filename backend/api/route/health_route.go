package route

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// 배포 검증·모니터링용 liveness 엔드포인트.
// DB나 외부 API를 부르지 않는다 — 업스트림 장애로 머신이 재시작되는 걸 막기 위함.
func NewHealthRouter(r gin.IRoutes) {
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
}
