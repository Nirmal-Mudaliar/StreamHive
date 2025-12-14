package auth_dto

type GetUserByIdAPIRequest struct {
	UserId int64 `json:"user_id"`
}

type InsertUserApiRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	FullName string `json:"full_name"`
}

type SignUpDataResponse struct {
	UserId       int64  `json:"user_id"`
	Email        string `json:"email"`
	FullName     string `json:"full_name"`
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}
