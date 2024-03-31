package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"time"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

func Love(c *fiber.Ctx) error {
	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	user_std_code := data["user_std_code"]
	lover_user_std_code := data["lover_user_std_code"]
	timestamp := time.Now().Unix()

	Lover := models.Lover{
		UserStdCode:      user_std_code,
		LoverUserStdCode: lover_user_std_code,
		CreatedAt:        timestamp,
	}

	database.DB.Create(&Lover)

	database.DB.Model(&models.User{}).Where("std_code = ?", lover_user_std_code).Update("lover_count", gorm.Expr("lover_count + ?", 1))

	return c.JSON(Lover)
}

func UnLove(c *fiber.Ctx) error {

	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	user_std_code := data["user_std_code"]
	lover_user_std_code := data["lover_user_std_code"]

	result := database.DB.Delete(&models.Lover{}, "user_std_code = ? AND lover_user_std_code = ?", user_std_code, lover_user_std_code)

	if result.Error != nil {
		return c.Status(500).JSON(fiber.Map{
			"error":   result.Error,
			"message": "Failed to unfollow",
		})
	}

	database.DB.Model(&models.User{}).Where("std_code = ?", lover_user_std_code).Update("lover_count", gorm.Expr("lover_count - ?", 1))

	return c.JSON(fiber.Map{
		"message": "Unfollow success",
	})
}

func GetLover(c *fiber.Ctx) error {
	var data map[string]string

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	user_std_code := data["user_std_code"]

	var lovers []models.Lover
	var lover_follower []models.Lover

	database.DB.Where("user_std_code = ?", user_std_code).Find(&lovers)

	database.DB.Where("lover_user_std_code = ?", user_std_code).Find(&lover_follower)

	all_lover := append(lovers, lover_follower...)

	return c.JSON(all_lover)
}

func removeDuplicates(slice []models.Location) []models.Location {
	// Create a map to store unique elements
	seen := make(map[models.Location]bool)
	result := []models.Location{}

	// Loop through the slice, adding elements to the map if they haven't been seen before
	for _, val := range slice {
		if _, ok := seen[val]; !ok {
			seen[val] = true
			result = append(result, val)
		}
	}
	return result
}

func LoverLocation(c *fiber.Ctx) error {
	var data map[string]string

	var lovers []models.Lover
	var lover_follower []models.Lover

	if err := c.BodyParser(&data); err != nil {
		return err
	}

	database.DB.Where("user_std_code = ?", data["user_std_code"]).Find(&lovers)

	database.DB.Where("lover_user_std_code = ?", data["user_std_code"]).Find(&lover_follower)

	all_lover := append(lovers, lover_follower...)

	var lovers_location []models.Location

	for i := 0; i < len(all_lover); i++ {
		var location models.Location
		if all_lover[i].LoverUserStdCode != data["user_std_code"] {
			database.DB.Where("std_code = ?", all_lover[i].LoverUserStdCode).Find(&location)
			lovers_location = append(lovers_location, location)
		}
	}

	for i := 0; i < len(all_lover); i++ {
		var location models.Location
		if all_lover[i].UserStdCode != data["user_std_code"] {
			database.DB.Where("std_code = ?", all_lover[i].UserStdCode).Find(&location)
			lovers_location = append(lovers_location, location)
		}
	}

	lovers_location = removeDuplicates(lovers_location)

	return c.JSON(lovers_location)
}
