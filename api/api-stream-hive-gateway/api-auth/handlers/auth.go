package api_auth

import (
	"context"
	"net/http"
	auth_dto "stream-hive/api/api-stream-hive-gateway/api-auth/dto"
	s "stream-hive/api/api-stream-hive-gateway/services"
	"stream-hive/api/dto"
	"stream-hive/core/config"
	pb "stream-hive/proto/database-gen"

	"github.com/gin-gonic/gin"
)

type AuthHandler struct {
	config         *config.GatewayConfig
	DatabaseClient pb.DatabaseServiceClient
}

func NewAuthHandler(
	config *config.GatewayConfig,
	databaseClient pb.DatabaseServiceClient,
) s.RouteRegister {
	return &AuthHandler{
		config:         config,
		DatabaseClient: databaseClient,
	}
}

func (h *AuthHandler) RegisterRoutes(r *gin.Engine) {
	secured := r.Group("/api/v1/auth")
	secured.GET("sign-up", h.SignUp)
}

func (h *AuthHandler) SignUp(c *gin.Context) {
	print("Sign Up function called")
	ctx := context.WithoutCancel(c.Request.Context())
	if err := ctx.Err(); err != nil {
		print("Failed to get context: ", err.Error())
		c.JSON(http.StatusBadRequest, dto.APIResponse{
			Success: false,
			Message: err.Error(),
		})
		return
	}
	var reqBody auth_dto.GetUserByIdAPIRequest
	if err := c.ShouldBindJSON(&reqBody); err != nil {
		c.JSON(http.StatusBadRequest, dto.APIResponse{
			Success: false,
			Message: err.Error(),
		})
		return
	}
	req := &pb.GetUserByIdRequest{
		Id: reqBody.UserId,
	}
	user, err := h.DatabaseClient.GetUserById(ctx, req)
	if err != nil {
		c.JSON(http.StatusBadRequest, dto.APIResponse{
			Success: false,
			Message: err.Error(),
		})
	}
	c.JSON(http.StatusOK, dto.APIResponse{
		Success: true,
		Data:    user,
	})

}
