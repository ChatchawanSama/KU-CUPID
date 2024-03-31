package models

type Message struct {
	Id        uint   `json:"id"`
	ChatId    string `json:"chat_id"`
	From      string `json:"from"`
	To        string `json:"to"`
	Contents  string `json:"contents"`
	Read bool `json:"read"`
	CreatedAt int64  `json:"created_at"`
}
