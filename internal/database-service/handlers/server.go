package handlers

import (
	db "stream-hive/internal/database-service/db/generated"
	pb "stream-hive/proto/database-gen"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DatabaseServer struct {
	pb.UnimplementedDatabaseServiceServer
	Queries *db.Queries
	Pool    *pgxpool.Pool
}
