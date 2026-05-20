package domain

import "time"

type Trip struct {
	ID          string     `json:"id"`
	OwnerID     string     `json:"owner_id"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	StartDate   *string    `json:"start_date,omitempty"`
	EndDate     *string    `json:"end_date,omitempty"`
	DeletedAt   *time.Time `json:"deleted_at,omitempty"`
	CreatedAt   time.Time  `json:"created_at"`
}

type TripMember struct {
	ID     string `json:"id"`
	TripID string `json:"trip_id"`
	UserID string `json:"user_id"`
	Role   string `json:"role"`
}

type TripInvitation struct {
	ID        string `json:"id"`
	TripID    string `json:"trip_id"`
	Email     string `json:"email"`
	Status    string `json:"status"`
	ExpiredAt string `json:"expired_at"`
}

type TripRepository interface{}

type TripUsecase interface{}
