package routes

import (
	"gym-api/controllers"
	"gym-api/middleware"

	"github.com/gofiber/fiber/v2"
)

func SetupRoutes(app *fiber.App) {
	api := app.Group("/api")
	auth := api.Group("/auth")

	auth.Post("/register", controllers.Register)
	auth.Post("/login", controllers.Login)
	// Protected Auth Routes (Requires Middleware for Context)
	auth.Post("/change-password", middleware.Protected(), controllers.ChangePassword)
	auth.Get("/me", middleware.Protected(), controllers.Me)

	// Protected Routes
	api.Use(middleware.Protected())

	// Trainer Routes
	api.Get("/history", controllers.GetHistory)

	// Admin Routes (Strict Admin Only)
	admin := api.Group("/admin", middleware.AdminOnly())
	admin.Get("/reports", controllers.GetReports)
	admin.Get("/trainers", controllers.GetAllTrainers)
	admin.Post("/trainers/:id/toggle", controllers.ToggleTrainerStatus)
	admin.Put("/members/:id", controllers.UpdateMember) // Only admin can edit/delete for now
	admin.Delete("/members/:id", controllers.DeleteMember)
	// Staff & Admin Routes (Shared Management)
	management := api.Group("/management", middleware.AdminOrStaffOnly())
	management.Post("/scan", controllers.ScanQR)
	management.Get("/members", controllers.GetAllMembers)     // Staff needs to see members
	management.Get("/members/:id", controllers.GetMemberById) // Fetch single member for scan verification
	management.Post("/members/assign", controllers.AssignTrainer)
	management.Post("/members/subscribe", controllers.SubscribeMember)
	management.Get("/packages", controllers.GetPackages)                   // Staff needs to see packages for reference
	management.Post("/members/:id/toggle", controllers.ToggleMemberStatus) // Allow staff to toggle member status
	management.Get("/attendance", controllers.GetAttendanceLogs)           // Shared Attendance View

	// Admin User Routes (Staff & Trainers)
	admin.Post("/users", controllers.CreateUser)
	admin.Get("/users", controllers.GetUsersByRole)
	admin.Put("/users/:id", controllers.UpdateUser)
	admin.Delete("/users/:id", controllers.DeleteUser)
	admin.Post("/users/:id/toggle", controllers.ToggleUserStatus)

	// Admin Package Routes
	admin.Post("/packages", controllers.CreatePackage)
	admin.Put("/packages/:id", controllers.UpdatePackage)
	admin.Delete("/packages/:id", controllers.DeletePackage)

	// Admin Analytics
	admin.Get("/stats", controllers.GetStats)
	admin.Get("/attendance/chart", controllers.GetAttendanceChart)
}
