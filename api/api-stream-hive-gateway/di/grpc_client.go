package di

import (
	"log"
	database_gen "stream-hive/proto/database-gen"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func newDatabaseClient(databaseAddress string) database_gen.DatabaseServiceClient {
	conn, err := grpc.NewClient(
		databaseAddress,
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		log.Fatalf("Failed to connect to database gRPC server: ", err.Error())
	}
	log.Println("Connected to database gRPC server at: ", databaseAddress)
	log.Println("Connection State: ", conn.GetState())
	client := database_gen.NewDatabaseServiceClient(conn)
	return client
}
