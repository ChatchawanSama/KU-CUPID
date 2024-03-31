package routes

import (
	"ku_cupid/controllers"

	"github.com/gofiber/fiber/v2"
)

func Setup(app *fiber.App) {

	app.Post("/api/login", controllers.Login)
	app.Get("/api/user", controllers.User)
	app.Post("/api/logout", controllers.Logout)
	app.Put("/api/user/:userId", controllers.UpdateUserProfile)

	app.Put("/api/location", controllers.PutLocation)
	app.Post("/api/location", controllers.GetLocation)

	app.Post("/api/love", controllers.Love)
	app.Delete("/api/love", controllers.UnLove)
	app.Post("/api/lover", controllers.GetLover)
	app.Post("/api/lover/location", controllers.LoverLocation)

	app.Get("/api/posts/:userId", controllers.GetUserPosts)
	app.Post("/api/posts", controllers.CreatePost)
	app.Post("/api/chat", controllers.CreatePrivateChat)
	app.Post("/api/chat/reveal/heartId", controllers.RevealPrivateWithChatHeartId)
	app.Post("/api/items", controllers.GetItems)
	app.Put("/api/items/spear", controllers.UseSpear)
	app.Post("/api/messages", controllers.SendMessage)
	app.Get("/api/messages/:chatId", controllers.GetMessage)
	// app.Put("/api/posts/:postId", controllers.UpdatePost)
	app.Delete("/api/posts/:postId", controllers.DeletePost)
}
