package controllers

import (
	"strconv"
	"time"

	"gym-api/config"
	"gym-api/models"

	"github.com/gofiber/fiber/v2"
)

func GetAllMembers(c *fiber.Ctx) error {
	var members []models.User
	config.DB.Preload("Package").Where("role = ?", models.RoleMember).Find(&members)
	return c.JSON(fiber.Map{"data": members})
}

func GetMemberById(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var member models.User
	if result := config.DB.Preload("Package").First(&member, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	return c.JSON(fiber.Map{"data": member})
}

type AssignTrainerInput struct {
	MemberID  uint `json:"member_id"`
	TrainerID uint `json:"trainer_id"`
}

func AssignTrainer(c *fiber.Ctx) error {
	var input AssignTrainerInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	var member models.User
	if result := config.DB.First(&member, input.MemberID); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	var trainer models.User
	if result := config.DB.First(&trainer, input.TrainerID); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Trainer not found"})
	}

	if trainer.Role != models.RoleTrainer {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Assigned user must be a trainer"})
	}

	member.AssignedTrainerID = &input.TrainerID
	config.DB.Save(&member)

	return c.JSON(fiber.Map{"message": "Trainer assigned successfully"})
}

func ToggleMemberStatus(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var member models.User
	if result := config.DB.First(&member, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	if member.MembershipStatus == "active" {
		member.MembershipStatus = "inactive"
	} else {
		member.MembershipStatus = "active"
	}
	config.DB.Save(&member)

	return c.JSON(fiber.Map{"message": "Member status updated", "status": member.MembershipStatus})
}

func UpdateMember(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	var input struct {
		Name             string  `json:"name"`
		Email            string  `json:"email"`
		PackageID        *uint   `json:"package_id"`
		MembershipStatus *string `json:"membership_status"`
	}
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	var member models.User
	// Preload package for current context
	if result := config.DB.First(&member, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	member.Name = input.Name
	member.Email = input.Email

	// Update Status if provided
	if input.MembershipStatus != nil && *input.MembershipStatus != "" {
		member.MembershipStatus = *input.MembershipStatus
	}

	// Update Package if provided (and different)
	if input.PackageID != nil {
		if member.PackageID == nil || *member.PackageID != *input.PackageID {
			// Logic to update package and dates
			var pkg models.Package
			if err := config.DB.First(&pkg, *input.PackageID).Error; err == nil {
				// Reset subscription dates based on new package
				now := time.Now()
				endDate := now.AddDate(0, 0, pkg.DurationDays)
				member.PackageID = &pkg.ID
				member.SubStartDate = &now
				member.SubEndDate = &endDate
				// Ensure active if assigning a package
				if member.MembershipStatus != "active" {
					member.MembershipStatus = "active"
				}
			}
		} else {
			// Same package, maybe just want to update ID reference?
			// Logic above handles "different or nil", if same, we can assume NO-OP on dates
			// typically we wouldn't reach here unless we want to reset dates?
			// Let's assume sending the same ID does NOT reset dates unless checking a flag.
			// For simplicity: sending package_id always updates it. If matches, we can skip date reset OR forced reset.
			// Let's adopt behavior: Providing package_id updates the package.
			// If user selects same package, maybe they want to RENEW?
			// Standard Edit behavior: changing fields.
			// For now, if I switch plan, I get new dates.
		}
	}

	config.DB.Save(&member)

	return c.JSON(fiber.Map{"message": "Member updated", "data": member})
}

func DeleteMember(c *fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.Atoi(idStr)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid ID"})
	}

	if result := config.DB.Delete(&models.User{}, id); result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to delete member"})
	}

	return c.JSON(fiber.Map{"message": "Member deleted"})
}
