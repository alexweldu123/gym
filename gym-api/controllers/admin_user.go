package controllers

import (
	"strconv"

	"gym-api/config"
	"gym-api/models"
	"gym-api/utils"

	"github.com/gofiber/fiber/v2"
)

type CreateUserInput struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"` // staff, trainer
}

func CreateUser(c *fiber.Ctx) error {
	var input CreateUserInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	if input.Role != string(models.RoleStaff) && input.Role != string(models.RoleTrainer) {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid role. Only staff or trainer allowed."})
	}

	hash, err := utils.HashPassword(input.Password)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not hash password"})
	}

	user := models.User{
		Name:         input.Name,
		Email:        input.Email,
		PasswordHash: hash,
		Role:         models.Role(input.Role),
		IsActive:     true,
	}

	if result := config.DB.Create(&user); result.Error != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "User already exists or invalid data"})
	}

	return c.JSON(fiber.Map{"message": "User created successfully", "user": user})
}

func GetUsersByRole(c *fiber.Ctx) error {
	role := c.Query("role")
	if role == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Role query param required"})
	}

	var users []models.User
	config.DB.Where("role = ?", role).Find(&users)
	return c.JSON(fiber.Map{"data": users})
}

func UpdateUser(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Name  string `json:"name"`
		Email string `json:"email"`
		Role  string `json:"role"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	var user models.User
	if result := config.DB.First(&user, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}

	user.Name = input.Name
	user.Email = input.Email
	if input.Role != "" {
		user.Role = models.Role(input.Role)
	}
	config.DB.Save(&user)

	return c.JSON(fiber.Map{"message": "User updated", "data": user})
}

func DeleteUser(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	if result := config.DB.Delete(&models.User{}, id); result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete user"})
	}

	return c.JSON(fiber.Map{"message": "User deleted"})
}

func ToggleUserStatus(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var user models.User
	if result := config.DB.First(&user, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}

	user.IsActive = !user.IsActive
	config.DB.Save(&user)

	return c.JSON(fiber.Map{"message": "User status updated", "is_active": user.IsActive})
}
