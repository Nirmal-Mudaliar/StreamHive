package core

import (
	"crypto/rsa"
	"os"
	"strconv"
	database_gen "stream-hive/proto/database-gen"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type ClaimUser struct {
	UserId            string `json:"user_id"`
	Email             string `json:"email"`
	ProfilePictureUrl string `json:"profile_picture_url"`
}

func CreateAccessToken(user *database_gen.User, expiry time.Time, privateKeyPath string) (string, error) {
	claimUser := ClaimUser{
		UserId:            strconv.FormatInt(user.Id, 10),
		Email:             user.Email,
		ProfilePictureUrl: user.ProfilePictureUrl,
	}
	return SignJWT(claimUser, expiry, privateKeyPath)
}

func SignJWT(claimUser ClaimUser, expiry time.Time, keyPath string) (string, error) {
	privateKey, err := loadPrivateKey(keyPath)
	if err != nil {
		print("Error loading private key: " + err.Error())
		return "", err
	}
	claims := jwt.MapClaims{
		"exp":  expiry.Unix(),
		"iat":  time.Now().Unix(),
		"iss":  "stream-hive",
		"user": claimUser,
	}
	jwtToken := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	return jwtToken.SignedString(privateKey)
}

func CreateRefreshToken(user *database_gen.User, expiry time.Time, privateKeyPath string) (string, error) {
	claimUser := ClaimUser{
		UserId:            strconv.FormatInt(user.Id, 10),
		Email:             user.Email,
		ProfilePictureUrl: user.ProfilePictureUrl,
	}
	return signJWTRefreshToken(claimUser, expiry, privateKeyPath)
}

func signJWTRefreshToken(claimUser ClaimUser, expiry time.Time, privateKeyPath string) (string, error) {
	privateKey, err := loadPrivateKey(privateKeyPath)
	if err != nil {
		print("Error loading private key: " + err.Error())
		return "", err
	}
	claims := jwt.MapClaims{
		"exp":  expiry.Unix(),
		"iat":  time.Now().Unix(),
		"iss":  "stream-hive",
		"user": claimUser,
		"type": "refresh_token",
	}
	jwtToken := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
	return jwtToken.SignedString(privateKey)
}

func loadPrivateKey(keyPath string) (*rsa.PrivateKey, error) {
	bytes, err := os.ReadFile(keyPath)
	if err != nil {
		print("Error reading private key: " + err.Error())
		return nil, err
	}
	privateKey, err := jwt.ParseRSAPrivateKeyFromPEM(bytes)
	if err != nil {
		print("Error loading private key", err.Error())
		return nil, err
	}
	return privateKey, nil
}
