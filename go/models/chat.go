package models

type Chat struct {
	Id        uint   `json:"id"`
	User1     string `json:"user1"`
	User2     string `json:"user2"`
	Reveal    bool   `json:"reveal"`
	CreatedAt int64  `json:"created_at"` // unix timestamp
}
