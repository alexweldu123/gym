package controllers

import (
	"gym-api/config"
	"gym-api/models"
	"strconv"

	"github.com/gofiber/fiber/v2"
)

// GetAttendanceLogs retrieves paginated attendance records with optional date filters
func GetAttendanceLogs(c *fiber.Ctx) error {
	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "10"))
	offset := (page - 1) * limit

	startDateStr := c.Query("start_date")
	endDateStr := c.Query("end_date")
	memberID := c.Query("member_id")

	attendances := []models.Attendance{} // Initialize as empty slice to return [] instead of null
	var total int64

	db := config.DB.Model(&models.Attendance{})

	// Preload associations
	// Note: According to models.go, Attendance has 'TrainerID' and 'ScannedBy' (Admin).
	// But it doesn't explicitly link to a 'Member'.
	// Wait, let's double check models.go.
	// If Attendance is just TrainerID (which represents the Member who attended?), then we preload Trainer.
	// Actually, in gym management context, usually 'Member' attends.
	// Let's check models.go to see what 'Attendance' struct actually holds.
	// Line 47: TrainerID uint `json:"trainer_id"` -> Trainer User.
	// This seems to imply the attendance is for the Trainer? Or was 'TrainerID' misnamed and actually refers to the checked-in user?
	// In scanner_screen.dart, we send 'trainer_id' in payload, but we fetch from /members/:id.
	// It's likely 'TrainerID' in Attendance model actually stores the ID of the person attending (Member or Trainer).
	// I will preload 'Trainer' (which is a User) to get the name of the attendee.
	// And 'Admin' (ScannedBy) is the staff who scanned.

	db = db.Preload("Trainer").Preload("Admin")

	// Apply Filters
	if startDateStr != "" {
		db = db.Where("date >= ?", startDateStr)
	}
	if endDateStr != "" {
		db = db.Where("date <= ?", endDateStr)
	}
	if memberID != "" {
		db = db.Where("trainer_id = ?", memberID)
	}

	db.Count(&total)

	if err := db.Order("scan_time desc").Offset(offset).Limit(limit).Find(&attendances).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"error": "Failed to fetch attendance logs",
		})
	}

	return c.JSON(fiber.Map{
		"data":  attendances,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}
