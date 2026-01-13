package models

import (
	"time"
)

type Role string

const (
	RoleAdmin   Role = "admin"
	RoleStaff   Role = "staff"
	RoleTrainer Role = "trainer"
	RoleMember  Role = "member"
)

type Package struct {
	ID           uint    `gorm:"primaryKey" json:"id"`
	Name         string  `json:"name"`
	DurationDays int     `json:"duration_days"` // e.g., 30, 90, 365
	Price        float64 `json:"price"`
	Description  string  `json:"description"`
}

type User struct {
	ID                uint   `gorm:"primaryKey" json:"id"`
	Name              string `json:"name"`
	Email             string `gorm:"uniqueIndex;type:varchar(191)" json:"email"`
	PasswordHash      string `json:"-"`
	ProfilePicture    string `json:"profile_picture"`
	Role              Role   `gorm:"type:varchar(20);default:'member'" json:"role"`
	IsActive          bool   `gorm:"default:true" json:"is_active"`
	AssignedTrainerID *uint  `json:"assigned_trainer_id"`
	MembershipStatus  string `gorm:"default:'active'" json:"membership_status"`

	// Package & Subscription Info
	PackageID    *uint      `json:"package_id"`
	Package      *Package   `gorm:"foreignKey:PackageID" json:"package,omitempty"`
	SubStartDate *time.Time `json:"sub_start_date"`
	SubEndDate   *time.Time `json:"sub_end_date"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Attendance struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	TrainerID uint      `json:"trainer_id"`
	Trainer   User      `gorm:"foreignKey:TrainerID" json:"trainer"`
	ScannedBy uint      `json:"scanned_by"` // Admin who scanned
	Admin     User      `gorm:"foreignKey:ScannedBy" json:"admin"`
	ScanTime  time.Time `json:"scan_time"`
	Date      time.Time `gorm:"type:date" json:"date"` // stored as YYYY-MM-DD
}
