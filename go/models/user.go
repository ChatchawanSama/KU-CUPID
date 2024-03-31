package models

type User struct {
	Id         uint   `json:"id"`
	StdCode    string `json:"std_code"`
	FirstName  string `json:"first_name"`
	MiddleName string `json:"middle_name"`
	LastName   string `json:"last_name"`
	HeartId    string `json:"heart_id" gorm:"unique"`
	LoverCount int    `json:"lover_count"`
	Bio        string `json:"bio"`
	IsActive   bool   `json:"is_active"`
	LastActive int64  `json:"last_active"`
	ImagePath  string `json:"image_path"`
}
