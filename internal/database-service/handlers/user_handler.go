package handlers

import (
	"context"
	"database/sql"
	"errors"
	"stream-hive/internal/common"
	db "stream-hive/internal/database-service/db/generated"
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

func (s *DatabaseServer) InsertUser(ctx context.Context, req *pb.InsertUserRequest) (*pb.User, error) {
	user, err := s.Queries.InsertUser(ctx, db.InsertUserParams{
		Email:        req.Email,
		PasswordHash: req.PasswordHash,
		FullName:     common.ToPgText(&req.FullName),
	})
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			print("Error occurred while inserting user: " + err.Error())
			return nil, err
		}
	}
	return &pb.User{
		Id:                user.ID,
		Email:             user.Email,
		PasswordHash:      user.PasswordHash,
		FullName:          user.FullName.String,
		ProfilePictureUrl: user.ProfilePictureUrl.String,
	}, nil
}

func (s *DatabaseServer) GetUserByEmail(ctx context.Context, req *pb.GetUserByEmailRequest) (*pb.User, error) {
	user, err := s.Queries.GetUserByEmail(ctx, req.Email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		print("Error occurred while getting user by email: " + err.Error())
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
