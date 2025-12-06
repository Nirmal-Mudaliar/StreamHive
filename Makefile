# Build Params
# Define directories and output locations for builds
BUILD_DIRS := $(shell find api -type f -name "main.go" -exec dirname {} \;)
BUILD_OUTPUT := bin

# Define all services and gateways
SERVICES = database-service
GATEWAYS = api-stream-hive-gateway

# Docker image prefix
IMAGE_PREFIX = stream-hive

# Default Go build flags
GO_BUILD_FLAGS = -ldflags="-s -w"

# Generate SQLC files
sqlc-gen:
	@cd internal/database-service && sqlc generate

# Clean and tidy Go modules
tidy: clean
	go mod tidy

# ----CLEANUP-----
.PHONY: clean
clean:
	@echo "Cleaning up built binaries"
	@rm -rf bin/*

generate-proto:
	@echo "Generating gRPC protobuf files..."
	@protoc --go_out=. --go-grpc_out=. proto/*/*.proto
	@protoc --go_out=. --go-grpc_out=. proto/*/*/*.proto

.PHONY: build
build: tidy sqlc-gen build-gateways build-services

# Build API Gateways
build-gateways:
	@for dir in $(BUILD_DIRS); do \
		APP_NAME=$$(basename $$dir); \
		OUTPUT="$(BUILD_OUTPUT)/$$APP_NAME"; \
		echo "Building $$dir -> $$OUTPUT"; \
		env GOOS=linux CGO_ENABLED=0 go build $(GO_BUILD_FLAGS) -o $$OUTPUT ./$$dir; \
	done

# Build internal services
build-services:
	@for service in $(SERVICES); do \
  		echo "Building $$service..."; \
  		cd internal/$$service && env GOOS=linux CGO_ENABLED=0 go build $(GO_BUILD_FLAGS) -o ../../bin/$$service . || exit 1; \
  		cd - >/dev/null; \
	done

# up: stops docker-compose (if running), builds all projects and starts docker compose
up: generate-proto build
	@echo "Stopping docker images (if running...)"
	docker-compose down
	docker image prune -f
	@echo "Building (when required) and starting docker images"
	docker-compose up --build -d
	@echo "Docker images built and started!"