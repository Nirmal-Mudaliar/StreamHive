package di

import (
	api_health "stream-hive/api/api-stream-hive-gateway/api-health/handlers"
	s "stream-hive/api/api-stream-hive-gateway/services"
	c "stream-hive/core/config"

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

	// Register handlers
	container.Provide(api_health.NewHealthCheckHandler, dig.Group(g_handlers), dig.As(new(s.RouteRegister)))
	return container
}
