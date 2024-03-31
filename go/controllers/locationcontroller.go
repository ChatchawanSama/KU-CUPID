package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"strconv"
	"time"

	"github.com/gofiber/fiber/v2"
)

func PutLocation(c *fiber.Ctx) error {
	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	stdCode := data["std_code"]
	latitude := data["latitude"]
	longitude := data["longitude"]
	timestamp := time.Now().Unix()

	latitudeFloat, err := strconv.ParseFloat(latitude, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid latitude"})
	}

	longitudeFloat, err := strconv.ParseFloat(longitude, 64)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid longitude"})
	}

	location := models.Location{
		StdCode:     stdCode,
		Latitude:  latitudeFloat,
		Longitude: longitudeFloat,
		Timestamp: timestamp,
	}

	if err := database.DB.Save(&location).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": err.Error()})
	}

	return c.JSON(location)
}

func GetLocation(c *fiber.Ctx) error {
	var data map[string]string

	var location models.Location

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	database.DB.Where("std_code = ?", data["std_code"]).First(&location)

	return c.JSON(location)
}


