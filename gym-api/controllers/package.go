package controllers

import (
	"gym-api/config"
	"gym-api/models"
	"time"

	"github.com/gofiber/fiber/v2"
)

// -- Packages CRUD --

func GetPackages(c *fiber.Ctx) error {
	var packages []models.Package
	config.DB.Find(&packages)
	return c.JSON(fiber.Map{"data": packages})
}

func CreatePackage(c *fiber.Ctx) error {
	var input models.Package
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	if result := config.DB.Create(&input); result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not create package"})
	}

	return c.JSON(fiber.Map{"message": "Package created", "data": input})
}

func UpdatePackage(c *fiber.Ctx) error {
	id := c.Params("id")
	var pkg models.Package
	if result := config.DB.First(&pkg, id); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Package not found"})
	}

	var input models.Package
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	pkg.Name = input.Name
	pkg.DurationDays = input.DurationDays
	pkg.Price = input.Price
	pkg.Description = input.Description

	config.DB.Save(&pkg)
	return c.JSON(fiber.Map{"message": "Package updated", "data": pkg})
}

func DeletePackage(c *fiber.Ctx) error {
	id := c.Params("id")
	if result := config.DB.Delete(&models.Package{}, id); result.Error != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Could not delete package"})
	}
	return c.JSON(fiber.Map{"message": "Package deleted"})
}

// -- Subscription Logic --

type SubscribeInput struct {
	MemberID  uint `json:"member_id"`
	PackageID uint `json:"package_id"`
}

func SubscribeMember(c *fiber.Ctx) error {
	var input SubscribeInput
	if err := c.BodyParser(&input); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "Invalid input"})
	}

	// 1. Fetch Package
	var pkg models.Package
	if result := config.DB.First(&pkg, input.PackageID); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Package not found"})
	}

	// 2. Fetch Member
	var member models.User
	if result := config.DB.First(&member, input.MemberID); result.Error != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"error": "Member not found"})
	}

	// 3. Update Member Subscription
	now := time.Now()
	endDate := now.AddDate(0, 0, pkg.DurationDays)

	member.PackageID = &pkg.ID
	member.SubStartDate = &now
	member.SubEndDate = &endDate
	member.MembershipStatus = "active"

	config.DB.Save(&member)

	return c.JSON(fiber.Map{
		"message":      "Subscription updated successfully",
		"package":      pkg.Name,
		"sub_end_date": endDate.Format("2006-01-02"),
		"status":       "active",
	})
}
