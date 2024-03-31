package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

func GetItems(c *fiber.Ctx) error {
	var data map[string]string
	var item models.Item

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	stdCode := data["std_code"]
	timestamp := time.Now().Unix()

	if err := database.DB.Where("std_code = ?", stdCode).First(&item).Error; err != nil {
		item = models.Item{
			StdCode:       stdCode,
			SpearCooldown: timestamp,
			DateTimeNow:   timestamp,
		}

		if err := database.DB.Create(&item).Error; err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
		}
	}

	database.DB.Where("std_code = ?", stdCode).First(&item)

	item.DateTimeNow = timestamp

	if err := database.DB.Save(&item).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(item)
}

func UseSpear(c *fiber.Ctx) error {
	var data map[string]string
	var item models.Item
	var chat models.Chat

	if err := c.BodyParser(&data); err != nil {
		return err
	}
	if err := c.BodyParser(&data); err != nil {
		return err
	}

	chatId := data["chat_id"]
	stdCode := data["std_code"]
	timestamp := time.Now().Unix()

	database.DB.Where("id = ?", chatId).First(&chat)

	chat.Reveal = true

	if err := database.DB.Save(&chat).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	database.DB.Where("std_code = ?", stdCode).First(&item)

	item.DateTimeNow = timestamp
	// Add 2 weeks to the current timestamp
	item.SpearCooldown = timestamp + int64(1209600)

	if err := database.DB.Save(&item).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(item)
}

// func RevealPrivateChatSpear(c *fiber.Ctx) error {
// 	var data map[string]string
// 	var chat models.Chat
// 	if err := c.BodyParser(&data); err != nil {
// 		return err
// 	}

// 	chatId := data["chat_id"]

// 	database.DB.Where("id = ?", chatId).First(&chat)

// 	chat.Reveal = true

// 	if err := database.DB.Save(&chat).Error; err != nil {
// 		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
// 	}

// 	return c.JSON(chat)
// } 
