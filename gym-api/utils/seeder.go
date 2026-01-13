package utils

import (
	"gym-api/config"
	"gym-api/models"
	"log"
	"time"
)

func SeedAdmin() {
	var count int64
	config.DB.Model(&models.User{}).Where("role = ?", "admin").Count(&count)

	if count == 0 {
		hashedPassword, _ := HashPassword("admin123")
		admin := models.User{
			Name:         "Super Admin",
			Email:        "admin@gmail.com",
			PasswordHash: hashedPassword,
			Role:         models.RoleAdmin, // Ensures role is admin
		}

		if err := config.DB.Create(&admin).Error; err != nil {
			log.Println("Failed to seed admin:", err)
		} else {
			log.Println("Admin account seeded: admin@gmail.com / admin123")
		}
	} else {
		log.Println("Admin seed skipped (already exists)")
	}

	// Seed Staff
	var staffCount int64
	config.DB.Model(&models.User{}).Where("email = ?", "staff@gmail.com").Count(&staffCount)
	if staffCount == 0 {
		hashedPassword, _ := HashPassword("staff123")
		staff := models.User{
			Name:         "Default Staff",
			Email:        "staff@gmail.com",
			PasswordHash: hashedPassword,
			Role:         models.RoleStaff,
		}
		if err := config.DB.Create(&staff).Error; err != nil {
			log.Println("Failed to seed staff:", err)
		} else {
			log.Println("Staff account seeded: staff@gmail.com / staff123")
		}
	}

	// Seed Member and Attendance (for testing)
	var memberCount int64
	config.DB.Model(&models.User{}).Where("role = ?", models.RoleMember).Count(&memberCount)
	if memberCount == 0 {
		hashedPassword, _ := HashPassword("member123")
		pkgPrice := 50.0

		// Create Package first or use embedded if supported, but let's be safe and just create it implicitly or explicitly.
		// Since PackageID is a pointer, we can create the package separately and assign ID, or rely on GORM association.
		// Let's create a package first.
		pkg := models.Package{
			Name:         "Gold Plan",
			DurationDays: 30,
			Price:        pkgPrice,
			Description:  "Premium access",
		}
		config.DB.Create(&pkg)

		member := models.User{
			Name:             "John Doe",
			Email:            "john@example.com",
			PasswordHash:     hashedPassword,
			Role:             models.RoleMember,
			MembershipStatus: "active",
			PackageID:        &pkg.ID,
		}

		if err := config.DB.Create(&member).Error; err != nil {
			log.Println("Failed to seed member:", err)
		} else {
			log.Println("Member seeded: john@example.com")

			// Seed Attendance for this member
			var admin models.User
			config.DB.Where("email = ?", "admin@gmail.com").First(&admin)

			// Create last 3 days of logs
			for i := 0; i < 3; i++ {
				scanTime := time.Now().AddDate(0, 0, -i)
				log := models.Attendance{
					TrainerID: member.ID, // User ID
					ScannedBy: admin.ID,
					ScanTime:  scanTime,
					Date:      scanTime, // GORM handles time.Time to date type usually
				}
				config.DB.Create(&log)
			}
			log.Println("Seeded 3 attendance logs for John Doe")
		}
	}
}
