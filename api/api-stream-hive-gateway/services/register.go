package services

import "github.com/gin-gonic/gin"

type RouteRegister interface {
	RegisterRoutes(r *gin.Engine)
}
