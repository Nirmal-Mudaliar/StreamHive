package config

import "stream-hive/core"

type GatewayConfig struct {
	ServiceName            string
	HTTPPort               string
	Env                    string
	DatabaseServiceAddress string
}

func LoadGatewayConfig(serviceName string) *GatewayConfig {
	return &GatewayConfig{
		ServiceName:            serviceName,
		HTTPPort:               core.GetEnv(core.GATEWAY_HTTP_PORT),
		Env:                    core.GetEnv(core.APP_ENV),
		DatabaseServiceAddress: core.GetEnv(core.DATABASE_SERVICE_ADDRESS),
	}
}
