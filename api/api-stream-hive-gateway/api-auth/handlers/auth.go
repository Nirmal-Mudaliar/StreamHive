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
	secured.POST("login", h.LoginIn)
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
			Message: "Unexpected error occurred while creating access token: " + err.Error(),
		})
		return
	}

	refreshToken, err := core.CreateRefreshToken(
		user,
		time.Now().Add(time.Hour*time.Duration(h.config.RefreshTokenExpiryHours)),
		h.config.JWTRefreshTokenPrivateKeyPath,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while creating refresh token: " + err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, dto.APIResponse{
		Success: true,
		Data: auth_dto.AuthDataResponse{
			UserId:       user.Id,
			Email:        user.Email,
			FullName:     user.FullName,
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
		},
	})
}

func (h *AuthHandler) LoginIn(c *gin.Context) {
	ctx, cancel := context.WithTimeout(c.Request.Context(), 15*time.Second)
	defer cancel()

	var loginInApiRequest auth_dto.LoginInApiRequest
	if err := c.ShouldBindJSON(&loginInApiRequest); err != nil {
		c.JSON(http.StatusBadRequest, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while getting JSON request: " + err.Error(),
		})
		return
	}

	// TODO: Add validation for request body

	user, err := h.userManager.GetUserByEmail(ctx, loginInApiRequest.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while getting user: " + err.Error(),
		})
		return
	}

	if user == nil {
		c.JSON(http.StatusUnauthorized, dto.APIResponse{
			Success: false,
			Message: "Invalid credentials",
		})
		return
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(loginInApiRequest.Password))
	if err != nil {
		c.JSON(http.StatusUnauthorized, dto.APIResponse{
			Success: false,
			Message: "Invalid credentials",
		})
		return
	}

	// Generate tokens
	accessToken, err := core.CreateAccessToken(
		user,
		time.Now().Add(time.Hour*time.Duration(h.config.AccessTokenExpiryHours)),
		h.config.JwtAccessTokenPrivateKeyPath,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while creating access token: " + err.Error(),
		})
		return
	}

	refreshToken, err := core.CreateRefreshToken(
		user,
		time.Now().Add(time.Hour*time.Duration(h.config.RefreshTokenExpiryHours)),
		h.config.JWTRefreshTokenPrivateKeyPath,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, dto.APIResponse{
			Success: false,
			Message: "Unexpected error occurred while creating refresh token: " + err.Error(),
		})
		return
	}
	c.JSON(http.StatusOK, dto.APIResponse{
		Success: true,
		Data: auth_dto.AuthDataResponse{
			UserId:       user.Id,
			Email:        user.Email,
			FullName:     user.FullName,
			AccessToken:  accessToken,
			RefreshToken: refreshToken,
		},
	})
}
