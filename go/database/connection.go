package database

import (
	"ku_cupid/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"

	"fmt"
)

var DB *gorm.DB

func Connect(host, port, username, password string) {

	connectionString := fmt.Sprintf("%s:%s@tcp(%s:%s)/kucupiddb", username, password, host, port)
	connection, err := gorm.Open(mysql.Open(connectionString), &gorm.Config{})

	if err != nil {
		panic("failed to connect database")
	}

	DB = connection

	if err := connection.AutoMigrate(
		&models.User{}, 
		&models.Location{}, 
		&models.Lover{}, 
		&models.Message{}, 
		&models.Post{},
		&models.Chat{},
		&models.Item{},
		); err != nil {
		panic("failed to auto-migrate models: " + err.Error())
	}
}
