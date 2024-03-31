package main

import (
	"fmt"
	"ku_cupid/database"
	"ku_cupid/routes"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"

	"os"

	"github.com/joho/godotenv"
)

func main() {
    godotenv.Load()

    host := os.Getenv("DB_HOSTNAME")
    port := os.Getenv("DB_PORT")
    username := os.Getenv("DB_USERNAME")
    password := os.Getenv("DB_PASSWORD")

    database.Connect(host, port, username, password)

    app := fiber.New()

    app.Use(cors.New(cors.Config{
        AllowOrigins:     "*",
        AllowCredentials: true,
    }))

	currentTimestamp := time.Now()

	// Print the timestamp in a default format
	fmt.Println("Current Timestamp:", currentTimestamp)

    routes.Setup(app)

    app.Listen(":8000")
}




