// controllers/posts.go

package controllers

import (
	"ku_cupid/database"
	"ku_cupid/models"
	"net/http"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

// GetUserPosts retrieves all posts associated with a user ID
func GetUserPosts(c *fiber.Ctx) error {
	// Extract user ID from the request parameters
	userID := c.Params("userId")

	// Convert userID to uint
	uid, err := strconv.ParseUint(userID, 10, 64)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Invalid user ID"})
	}

	// Retrieve posts from the database for the specified user ID
	var posts []models.Post
	database.DB.Where("user_id = ?", uid).Find(&posts)

	// Update each post's "user_id" field with the real user ID
	for i := range posts {
		posts[i].UserID = uint(uid)
	}
	// Return posts as JSON response
	return c.JSON(posts)
}

// CreatePost endpoint
func CreatePost(c *fiber.Ctx) error {
	// Parse request body to extract post data
	var postData models.Post
	if err := c.BodyParser(&postData); err != nil {
		return err
	}

	// Check if the user with the provided ID exists
	var user models.User
	if err := database.DB.First(&user, postData.UserID).Error; err != nil {
		// If user doesn't exist, return an error
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "User not found"})
	}

	// Save the post to the database
	if err := database.DB.Create(&postData).Error; err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to create post"})
	}

	return c.JSON(postData)
}

// DeletePost deletes a post with the specified post ID
func DeletePost(c *fiber.Ctx) error {
	// Extract post ID from the request parameters
	postID := c.Params("postId")

	// Convert post ID to uint
	pid, err := strconv.ParseUint(postID, 10, 64)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"error": "Invalid post ID"})
	}

	// Delete the post from the database
	if err := database.DB.Where("id = ?", pid).Delete(&models.Post{}).Error; err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete post"})
	}

	return c.JSON(fiber.Map{"message": "Post deleted successfully"})
}
