package main

import (
	"log"

	"gym-api/config"
	"gym-api/models"
	"gym-api/routes"
	"gym-api/utils"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
)

func main() {
	// 1. Connect to Database
	config.ConnectDB()

	// 2. Auto Migrate
	err := config.DB.AutoMigrate(&models.User{}, &models.Attendance{}, &models.Package{})
	if err != nil {
		log.Fatal("Migration failed: ", err)
	}

	// 3. Seed Data
	utils.SeedAdmin()

	// 3. Setup Fiber
	app := fiber.New(fiber.Config{
		BodyLimit: 100 * 1024 * 1024, // 100MB
	})
	app.Use(logger.New())
	app.Use(cors.New())

	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendString("Gym Management API is running!")
	})

	// Serve Static Files (Profile Pictures)
	app.Static("/uploads", "./uploads")

	// 4. Setup Routes
	routes.SetupRoutes(app)

	// 5. Start Server
	log.Fatal(app.Listen(":8080"))
}
