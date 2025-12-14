package core

// common const
const (
	APP_ENV                            = "APP_ENV"
	PRODUCTION                         = "production"
	DEVELOPMENT                        = "development"
	STAGING                            = "staging"
	GRPC_PORT                          = "GRPC_PORT"
	DATABASE_URL                       = "DATABASE_URL"
	NETWORK                            = "tcp"
	DATABASE_SERVICE_ADDRESS           = "DATABASE_SERVICE_ADDRESS"
	ACCESS_TOKEN_EXPIRY_HOURS          = "ACCESS_TOKEN_EXPIRY_HOURS"
	JWT_ACCESS_TOKEN_PRIVATE_KEY_PATH  = "JWT_ACCESS_TOKEN_PRIVATE_KEY_PATH"
	REFRESH_TOKEN_EXPIRY_HOURS         = "REFRESH_TOKEN_EXPIRY_HOURS"
	JWT_REFRESH_TOKEN_PRIVATE_KEY_PATH = "JWT_REFRESH_TOKEN_PRIVATE_KEY_PATH"
)

// api-stream-hive-gateway const
const (
	STREAM_HIVE_GATEWAY_NAME = "api-stream-hive-gateway"
	GATEWAY_HTTP_PORT        = "HTTP_PORT"
)

// databse-service const
const (
	DATABASE_SERVICE_NAME = "database-service"
	POOL_MAX_CONNECTIONS  = "POOL_MAX_CONNECTIONS"
	POOL_MIN_CONNECTIONS  = "POOL_MIN_CONNECTIONS"
)
