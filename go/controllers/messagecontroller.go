package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"sort"
	"time"

	"github.com/gofiber/fiber/v2"
)

func SendMessage(c *fiber.Ctx) error {
	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	chatId := data["chat_id"]
	senderStdCode := data["from"]
	recipientStdCode := data["to"]
	contents := data["contents"]
	timestamp := time.Now().Unix()

	message := models.Message{
		ChatId:    chatId,
		From:      senderStdCode,
		To:        recipientStdCode,
		Read: false,
		Contents:  contents,
		CreatedAt: timestamp,
	}

	if err := database.DB.Create(&message).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(message)
}

func GetMessage(c *fiber.Ctx) error {
	chatId := c.Params("chatId")

	var messages []models.Message

	if err := database.DB.Where("chat_id = ?", chatId).Find(&messages).Error; err != nil {
		return err
	}

	sort.Slice(messages, func(i, j int) bool {
		return messages[i].CreatedAt > messages[j].CreatedAt
	})
	
	return c.JSON(messages)
}
