package models

type Lover struct {
	Id uint `json:"id"`
	UserStdCode string      `json:"user_std_code"`
	LoverUserStdCode  string     `json:"lover_user_std_code"`
	CreatedAt int64 `json:"created_at"`
}