package api_health

import (
	"net/http"
	s "stream-hive/api/api-stream-hive-gateway/services"

	"github.com/gin-gonic/gin"
)

type HealthCheckHandler struct {
}

func NewHealthCheckHandler() s.RouteRegister {
	return &HealthCheckHandler{}
}

func (h *HealthCheckHandler) RegisterRoutes(r *gin.Engine) {
	r.GET("/api/v1/health-check", h.HealthCheck)
}

func (h *HealthCheckHandler) HealthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "healthy",
	})
}
