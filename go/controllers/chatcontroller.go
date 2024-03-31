package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

func CreatePrivateChat(c *fiber.Ctx) error {
	var data map[string]string
	var chat models.Chat

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	senderStdCode := data["from"]
	recipientStdCode := data["to"]
	timestamp := time.Now().Unix()

	// Check if the chat already exists in either orientation
	if err := database.DB.Where("(user1 = ? AND user2 = ?) OR (user1 = ? AND user2 = ?)", senderStdCode, recipientStdCode, recipientStdCode, senderStdCode).First(&chat).Error; err != nil {
		// If chat doesn't exist, create a new one
		chat = models.Chat{
			User1:     senderStdCode,
			User2:     recipientStdCode,
			Reveal:    false,
			CreatedAt: timestamp,
		}

		if err := database.DB.Create(&chat).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	} 

	return c.JSON(chat)
}




func RevealPrivateWithChatHeartId(c *fiber.Ctx) error {
	var data map[string]string
	var chat models.Chat
	var userTarget models.User

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	chatId := data["chat_id"]
	// senderStdCode := data["sender"]
	userTargetHeartId := data["target_heart_id"]
	userTargetStdCode := data["user_target_std_code"]

	database.DB.Where("id = ?", chatId).First(&chat)
	database.DB.Where("std_code = ?", userTargetStdCode).First(&userTarget)

	if userTarget.HeartId == userTargetHeartId {
		chat.Reveal = true
	}

	if err := database.DB.Save(&chat).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(chat)
}
