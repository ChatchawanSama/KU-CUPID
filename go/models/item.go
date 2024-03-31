package models

type Item struct {
	Id       uint   `json:"id"`
	StdCode  string `json:"std_code" gorm:"primaryKey"`
	SpearCooldown int64  `json:"spear_cooldown"`
	DateTimeNow int64 `json:"date_time_now"`
}
