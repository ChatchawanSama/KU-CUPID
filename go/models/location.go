package models

type Location struct {
	Id uint `json:"id"`
	StdCode     string    `json:"std_code" gorm:"primaryKey"`
	Latitude  float64    `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Timestamp int64 `json:"timestamp"`
}
