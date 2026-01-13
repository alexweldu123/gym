package controllers

import (
	"fmt"
	"time"

	"gym-api/config"
	"gym-api/models"
	"gym-api/utils"

	"github.com/gofiber/fiber/v2"
)

type RegisterInput struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type LoginInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func Register(c *fiber.Ctx) error {
	// 1. Parse Form Data (Multipart)
	name := c.FormValue("name")
	email := c.FormValue("email")
	password := c.FormValue("password")
	packageIDStr := c.FormValue("package_id")

	if name == "" || email == "" || password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Name, email, and password are required"})
	}

	// 2. Handle File Upload
	var profilePicPath string
	file, err := c.FormFile("profile_picture")
	if err == nil {
		// Save file to ./uploads directory
		// Generate unique filename to avoid collisions
		filename := fmt.Sprintf("%d_%s", time.Now().Unix(), file.Filename)
		path := fmt.Sprintf("./uploads/%s", filename)

		if err := c.SaveFile(file, path); err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to save profile picture"})
		}
		// Store relative path for frontend access
		profilePicPath = "/uploads/" + filename
	}

	// 3. Hash Password
	hash, err := utils.HashPassword(password)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not hash password"})
	}

	// 4. Create User Object
	user := models.User{
		Name:           name,
		Email:          email,
		PasswordHash:   hash,
		Role:           models.RoleMember, // Default to Member
		ProfilePicture: profilePicPath,
	}

	// 5. Handle Package Assignment (if selected)
	if packageIDStr != "" {
		var pkg models.Package
		if err := config.DB.First(&pkg, "id = ?", packageIDStr).Error; err == nil {
			// Package found, assume subscription starts now
			now := time.Now()
			endDate := now.AddDate(0, 0, pkg.DurationDays)

			user.PackageID = &pkg.ID
			user.SubStartDate = &now
			user.SubEndDate = &endDate
			user.MembershipStatus = "active"
		}
	}

	// 5b. Handle Manual Sub End Date (Override)
	subEndDateStr := c.FormValue("sub_end_date")
	if subEndDateStr != "" {
		layout := "2006-01-02"
		if parsedDate, err := time.Parse(layout, subEndDateStr); err == nil {
			now := time.Now()
			user.SubStartDate = &now
			user.SubEndDate = &parsedDate
			user.MembershipStatus = "active"
		}
	}

	// 6. Save User to DB
	if result := config.DB.Create(&user); result.Error != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "User already exists or invalid data"})
	}

	return c.JSON(fiber.Map{"message": "User registered successfully", "user": user})
}

func Login(c *fiber.Ctx) error {
	var input LoginInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	var user models.User
	if result := config.DB.Where("email = ?", input.Email).First(&user); result.Error != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
	}

	if !utils.CheckPasswordHash(input.Password, user.PasswordHash) {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Invalid credentials"})
	}

	if !user.IsActive {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "User is deactivated"})
	}

	// Check for active subscription
	if user.Role == models.RoleMember && user.SubEndDate != nil {
		if time.Now().After(*user.SubEndDate) {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{"error": "Subscription expired"})
		}
	}

	token, err := utils.GenerateToken(user.ID, string(user.Role))
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not login"})
	}

	return c.JSON(fiber.Map{
		"token": token,
		"user": fiber.Map{
			"id":                  user.ID,
			"name":                user.Name,
			"email":               user.Email,
			"role":                user.Role,
			"membership_status":   user.MembershipStatus,
			"assigned_trainer_id": user.AssignedTrainerID,
			"profile_picture":     user.ProfilePicture,
			// "package": user.Package, // Include if we preloaded it, currently we don't in Login.
		},
	})
}

// ChangePasswordInput struct
type ChangePasswordInput struct {
	OldPassword string `json:"old_password"`
	NewPassword string `json:"new_password"`
}

// ChangePassword Controller
// ChangePassword Controller
func ChangePassword(c *fiber.Ctx) error {
	// 1. Get User ID from Context (set by middleware)
	var uid uint
	switch v := c.Locals("user_id").(type) {
	case uint:
		uid = v
	case float64:
		uid = uint(v)
	case int:
		uid = uint(v)
	default:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	// 2. Parse Input
	var input ChangePasswordInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	if len(input.NewPassword) < 6 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "New password must be at least 6 characters"})
	}

	// 3. Find User
	var user models.User
	if err := config.DB.First(&user, uid).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}

	// 4. Verify Old Password
	if !utils.CheckPasswordHash(input.OldPassword, user.PasswordHash) {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Incorrect old password"})
	}

	// 5. Hash New Password
	newHash, err := utils.HashPassword(input.NewPassword)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not hash new password"})
	}

	// 6. Update User
	user.PasswordHash = newHash
	config.DB.Save(&user)

	return c.JSON(fiber.Map{"message": "Password updated successfully"})
}

// Me Controller - Fetch Current User Profile
func Me(c *fiber.Ctx) error {
	// 1. Get User ID from Context
	var uid uint
	switch v := c.Locals("user_id").(type) {
	case uint:
		uid = v
	case float64:
		uid = uint(v)
	case int:
		uid = uint(v)
	default:
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	// 2. Find User (Preload necessary relations if needed)
	var user models.User
	if err := config.DB.First(&user, uid).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "User not found"})
	}

	// 3. Return User Data (matching Login response structure)
	return c.JSON(fiber.Map{
		"user": fiber.Map{
			"id":                  user.ID,
			"name":                user.Name,
			"email":               user.Email,
			"role":                user.Role,
			"membership_status":   user.MembershipStatus,
			"assigned_trainer_id": user.AssignedTrainerID,
			"profile_picture":     user.ProfilePicture,
		},
	})
}
