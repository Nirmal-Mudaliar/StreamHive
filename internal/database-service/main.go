package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"stream-hive/core"
	"stream-hive/core/config"
	db "stream-hive/internal/database-service/db/generated"
	"stream-hive/internal/database-service/handlers"
	pb "stream-hive/proto/database-gen"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

type Config struct {
	*config.DatabaseConfig
}

func main() {

	// load config
	serviceName := core.DATABASE_SERVICE_NAME
	baseConfig := config.LoadDatabaseConfig(serviceName)
	dBConfig := &Config{
		DatabaseConfig: baseConfig,
	}
	fmt.Printf("DatabaseConfig: %v\n", dBConfig)

	poolConfig, err := pgxpool.ParseConfig(dBConfig.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}

	poolConfig.MaxConns = dBConfig.PoolMaxConnections // Max connections allowed to connected with the DB
	poolConfig.MinConns = dBConfig.PoolMinConnections // keep some idle connections ready
	poolConfig.MaxConnIdleTime = 30 * time.Second     // close idle connection after 30 seconds
	poolConfig.HealthCheckPeriod = 30 * time.Second   // check every 30 seconds and creates new connection based on min connections configured

	// create a new pgxpool
	pool, err := pgxpool.NewWithConfig(context.Background(), poolConfig)
	if err != nil {
		log.Printf("Unable to create connection pool: %v\n", err)
	}
	defer pool.Close()

	dbServer := &handlers.DatabaseServer{
		Pool:    pool,
		Queries: db.New(pool),
	}

	// create a grpc server
	grpcServer := grpc.NewServer(
		grpc.MaxConcurrentStreams(100),
	)

	listner, err := net.Listen(core.NETWORK, ":"+dBConfig.GRPCPort)
	if err != nil {
		log.Printf("Failed to listen: %v", err)
	}

	// TODO: Register health check service

	// register database service
	pb.RegisterDatabaseServiceServer(grpcServer, dbServer)

	// register reflection service on gRPC server
	reflection.Register(grpcServer)

	log.Printf("Database service listening on: %s\n", dBConfig.GRPCPort)

	if err := grpcServer.Serve(listner); err != nil {
		log.Printf("Failed to serve: %v", err)
	}
}
