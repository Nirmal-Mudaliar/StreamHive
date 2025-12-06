package config

import (
	"net/url"
	"stream-hive/core"
)

type DatabaseConfig struct {
	ServiceName        string
	GRPCPort           string
	DatabaseURL        string
	Env                string
	PoolMaxConnections int32
	PoolMinConnections int32
}

func LoadDatabaseConfig(serviceName string) *DatabaseConfig {
	// decodes url eg: '%40' to '@'
	dbUrl, _ := url.QueryUnescape(core.GetEnv(core.DATABASE_URL))
	return &DatabaseConfig{
		ServiceName:        serviceName,
		GRPCPort:           core.GetEnv(core.GRPC_PORT),
		DatabaseURL:        dbUrl,
		Env:                core.GetEnv(core.APP_ENV),
		PoolMaxConnections: core.GetInt32Env(core.POOL_MAX_CONNECTIONS, 30),
		PoolMinConnections: core.GetInt32Env(core.POOL_MIN_CONNECTIONS, 10),
	}
}
