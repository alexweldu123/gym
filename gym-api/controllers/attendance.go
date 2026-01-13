package controllers

import (
	"strconv"
	"time"

	"gym-api/config"
	"gym-api/models"

	"github.com/gofiber/fiber/v2"
)

type ScanQRInput struct {
	TrainerID uint  `json:"trainer_id"`
	Timestamp int64 `json:"timestamp"`
	// Signature string `json:"signature"` // TODO: Add signature validation
}

func ScanQR(c *fiber.Ctx) error {
	var input ScanQRInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	// 1. Validate Timestamp (ensure it's not too old, e.g., < 1 minute)
	now := time.Now().Unix()
	if now-input.Timestamp > 60 || now-input.Timestamp < -5 { // 60s leniency, 5s clock skew
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "QR code expired"})
	}

	// 2. Get Admin ID from context
	adminID, ok := c.Locals("user_id").(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	// 3. Verify Trainer exists
	var trainer models.User
	if result := config.DB.First(&trainer, input.TrainerID); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Trainer not found"})
	}
	if trainer.Role != models.RoleTrainer && trainer.Role != models.RoleMember {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "User is not a trainer or member"})
	}

	// 4. Check if already scanned today (optional business rule)
	var count int64
	today := time.Now().Format("2006-01-02")
	config.DB.Model(&models.Attendance{}).Where("trainer_id = ? AND date = ?", input.TrainerID, today).Count(&count)
	if count > 0 {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{"error": "Attendance already marked for today"})
	}

	// 5. Create Attendance Record
	attendance := models.Attendance{
		TrainerID: input.TrainerID,
		ScannedBy: adminID,
		ScanTime:  time.Now(),
		Date:      time.Now(),
	}

	if result := config.DB.Create(&attendance); result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not mark attendance"})
	}

	return c.JSON(fiber.Map{"message": "Attendance marked successfully", "data": attendance})
}

func GetHistory(c *fiber.Ctx) error {
	userID, ok := c.Locals("user_id").(uint)
	if !ok {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"error": "Unauthorized"})
	}

	var history []models.Attendance
	config.DB.Where("trainer_id = ?", userID).Order("scan_time desc").Find(&history)

	return c.JSON(fiber.Map{"data": history})
}

func GetReports(c *fiber.Ctx) error {
	// Optional: Filter by date range query params
	var reports []models.Attendance

	// Preload Trainer and Admin info
	config.DB.Preload("Trainer").Preload("Admin").Order("scan_time desc").Find(&reports)

	return c.JSON(fiber.Map{"data": reports})
}

func GetAllTrainers(c *fiber.Ctx) error {
	var trainers []models.User
	config.DB.Where("role = ?", models.RoleTrainer).Find(&trainers)
	return c.JSON(fiber.Map{"data": trainers})
}

func ToggleTrainerStatus(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var trainer models.User
	if result := config.DB.First(&trainer, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Trainer not found"})
	}

	trainer.IsActive = !trainer.IsActive
	config.DB.Save(&trainer)

	return c.JSON(fiber.Map{"message": "Trainer status updated", "is_active": trainer.IsActive})
}
