package config

import (
	"stream-hive/core"
)

type GatewayConfig struct {
	ServiceName                  string
	HTTPPort                     string
	Env                          string
	DatabaseServiceAddress       string
	AccessTokenExpiryHours       int
	JwtAccessTokenPrivateKeyPath string
}

func LoadGatewayConfig(serviceName string) *GatewayConfig {
	return &GatewayConfig{
		ServiceName:                  serviceName,
		HTTPPort:                     core.GetEnv(core.GATEWAY_HTTP_PORT),
		Env:                          core.GetEnv(core.APP_ENV),
		DatabaseServiceAddress:       core.GetEnv(core.DATABASE_SERVICE_ADDRESS),
		AccessTokenExpiryHours:       core.GetIntEnv(core.ACCESS_TOKEN_EXPIRY_HOURS, 8),
		JwtAccessTokenPrivateKeyPath: core.GetEnv(core.JWT_ACCESS_PRIVATE_KEY_PATH),
	}
}
