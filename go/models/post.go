package models

import "time"

type Post struct {
	ID        uint      `json:"post_id"`
	UserID    uint      `json:"user_id"`
	Caption   string    `json:"caption"`
	ImagePath string    `json:"image_path"`
	CreatedAt time.Time `json:"created_at"`
}
