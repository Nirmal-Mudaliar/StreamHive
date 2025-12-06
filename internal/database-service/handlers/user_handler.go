package handlers

import (
	"context"
	"database/sql"
	"errors"
	pb "stream-hive/proto/database-gen"
)

func (s *DatabaseServer) GetUserById(ctx context.Context, req *pb.GetUserByIdRequest) (*pb.User, error) {
	user, err := s.Queries.GetUserById(ctx, req.Id)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		print("Error occured while getting user by id: " + err.Error())
		return nil, err
	}
	return &pb.User{
		Id:                user.ID,
		Email:             user.Email,
		PasswordHash:      user.PasswordHash,
		FullName:          user.FullName.String,
		ProfilePictureUrl: user.ProfilePictureUrl.String,
	}, nil
}
