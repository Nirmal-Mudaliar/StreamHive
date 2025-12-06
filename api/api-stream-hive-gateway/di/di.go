package di

import (
	api_auth "stream-hive/api/api-stream-hive-gateway/api-auth/handlers"
	api_health "stream-hive/api/api-stream-hive-gateway/api-health/handlers"
	s "stream-hive/api/api-stream-hive-gateway/services"
	c "stream-hive/core/config"
	database_gen "stream-hive/proto/database-gen"

	"go.uber.org/dig"
)

const (
	g_handlers = "handlers"
)

type Params struct {
	dig.In

	Config  *c.GatewayConfig
	Handler []s.RouteRegister `group:"handlers"`
}

func BuildContainer(serviceName string) *dig.Container {
	container := dig.New()
	container.Provide(func() *c.GatewayConfig {
		return c.LoadGatewayConfig(serviceName)
	})
	container.Provide(func(cfg *c.GatewayConfig) database_gen.DatabaseServiceClient {
		return newDatabaseClient(cfg.DatabaseServiceAddress)
	})

	// Register handlers
	container.Provide(api_health.NewHealthCheckHandler, dig.Group(g_handlers), dig.As(new(s.RouteRegister)))
	container.Provide(api_auth.NewAuthHandler, dig.Group(g_handlers), dig.As(new(s.RouteRegister)))
	return container
}
