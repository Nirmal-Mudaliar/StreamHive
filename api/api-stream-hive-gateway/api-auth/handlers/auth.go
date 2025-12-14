package api_auth

import (
	"context"
	"net/http"
	auth_dto "stream-hive/api/api-stream-hive-gateway/api-auth/dto"
	s "stream-hive/api/api-stream-hive-gateway/services"
	"stream-hive/api/domain"
	"stream-hive/api/dto"
	"stream-hive/core"
	"stream-hive/core/config"
	"time"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	config      *config.GatewayConfig
	userManager *domain.UserManager
}

func NewAuthHandler(
	config *config.GatewayConfig,
	userManager *domain.UserManager,
) s.RouteRegister {
	return &AuthHandler{
		config:      config,
		userManager: userManager,
	}
}

func (h *AuthHandler) RegisterRoutes(r *gin.Engine) {
	secured := r.Group("/api/v1/auth")
	secured.POST("sign-up", h.SignUp)
}

func (h *AuthHandler) SignUp(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
	defer cancel()

	if err := ctx.Err(); err != nil {
		print("Error occured while creating the context", err.Error())
	}

	var insertUserApiRequest auth_dto.InsertUserApiRequest
	if err := c.ShouldBindJSON(&insertUserApiRequest); err != nil {
		c.JSON(http.StatusBadRequest, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while getting JSON request",
		})
		return
	}

	// TODO: Add validation for the request body

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(insertUserApiRequest.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while hashing password",
		})
		return
	}

	user, err := h.userManager.InsertUser(
		ctx,
		insertUserApiRequest.Email,
		string(passwordHash),
		insertUserApiRequest.FullName,
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while inserting user: " + err.Error(),
		})
		return
	}

	accessToken, err := core.CreateAccessToken(
		user,
		time.Now().Add(time.Hour*time.Duration(h.config.AccessTokenExpiryHours)),
		h.config.JwtAccessTokenPrivateKeyPath,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while creating access token" + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, dto.APIResponse{
		Success: true,
		Data: auth_dto.SignUpDataResponse{
			UserId:      user.Id,
			Email:       user.Email,
			FullName:    user.FullName,
			AccessToken: accessToken,
		},
	})

	//print("Sign Up function called")
	//ctx := context.WithoutCancel(c.Request.Context())
	//if err := ctx.Err(); err != nil {
	//	print("Failed to get context: ", err.Error())
	//	c.JSON(http.StatusBadRequest, dto.APIResponse{
	//		Success: false,
	//		Message: err.Error(),
	//	})
	//	return
	//}
	//var reqBody auth_dto.GetUserByIdAPIRequest
	//if err := c.ShouldBindJSON(&reqBody); err != nil {
	//	c.JSON(http.StatusBadRequest, dto.APIResponse{
	//		Success: false,
	//		Message: err.Error(),
	//	})
	//	return
	//}
	//user, err := h.userManager.GetUserById(ctx, reqBody.UserId)
	//if err != nil {
	//	c.JSON(http.StatusBadRequest, dto.APIResponse{
	//		Success: false,
	//		Message: err.Error(),
	//	})
	//}
	//c.JSON(http.StatusOK, dto.APIResponse{
	//	Success: true,
	//	Data:    user,
	//})

}
