package controllers

import (
	"time"

	"gym-api/config"
	"gym-api/models"

	"github.com/gofiber/fiber/v2"
)

type DashboardStats struct {
	TotalMembers     int64   `json:"total_members"`
	ActiveMembers    int64   `json:"active_members"`
	TotalTrainers    int64   `json:"total_trainers"`
	EstimatedRevenue float64 `json:"estimated_revenue"`
	TodayAttendance  int64   `json:"today_attendance"`
}

func GetStats(c *fiber.Ctx) error {
	var stats DashboardStats

	// 1. Counts
	config.DB.Model(&models.User{}).Where("role = ?", models.RoleMember).Count(&stats.TotalMembers)
	config.DB.Model(&models.User{}).Where("role = ? AND membership_status = ?", models.RoleMember, "active").Count(&stats.ActiveMembers)
	config.DB.Model(&models.User{}).Where("role = ?", models.RoleTrainer).Count(&stats.TotalTrainers)

	// 2. Revenue (Simplified: Sum of prices of currently active packages)
	// In a real system, you'd use a 'payments' table.
	type RevenueResult struct {
		Total float64
	}
	var rev RevenueResult
	config.DB.Table("users").
		Select("sum(packages.price) as total").
		Joins("left join packages on packages.id = users.package_id").
		Where("users.membership_status = ?", "active").
		Scan(&rev)
	stats.EstimatedRevenue = rev.Total

	// 3. Today's Attendance
	today := time.Now().Format("2006-01-02")
	config.DB.Model(&models.Attendance{}).Where("date = ?", today).Count(&stats.TodayAttendance)

	return c.JSON(fiber.Map{"data": stats})
}

type ChartData struct {
	Date  string `json:"date"`
	Count int64  `json:"count"`
}

func GetAttendanceChart(c *fiber.Ctx) error {
	// Last 7 days
	var results []ChartData

	// MySQL specific date truncation
	config.DB.Table("attendances").
		Select("DATE_FORMAT(scan_time, '%Y-%m-%d') as date, count(*) as count").
		Where("scan_time > ?", time.Now().AddDate(0, 0, -7)).
		Group("DATE_FORMAT(scan_time, '%Y-%m-%d')").
		Order("date asc").
		Scan(&results)

	return c.JSON(fiber.Map{"data": results})
}
