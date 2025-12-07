package domain

import (
	"context"
	database_gen "stream-hive/proto/database-gen"
)

type UserManager struct {
	DatabaseClient database_gen.DatabaseServiceClient
}

func NewUserManager(DatabaseClient database_gen.DatabaseServiceClient) *UserManager {
	return &UserManager{
		DatabaseClient: DatabaseClient,
	}
}

func (um *UserManager) GetUserById(ctx context.Context, userId int64) (*database_gen.User, error) {
	user, err := um.DatabaseClient.GetUserById(
		ctx,
		&database_gen.GetUserByIdRequest{
			Id: userId,
		},
	)

	if err != nil {
		return nil, err
	}
	return user, nil
}
