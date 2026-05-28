package domain

import (
	"context"
	"errors"
	"time"
)

var (
	ErrNotFound  = errors.New("not found")
	ErrForbidden = errors.New("forbidden")
)

type Trip struct {
	ID          string     `json:"id"`
	OwnerID     string     `json:"owner_id"`
	Title       string     `json:"title"`
	Description *string    `json:"description,omitempty"`
	Destination *string    `json:"destination,omitempty"`
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

type CreateTripInput struct {
	Title       string  `json:"title"`
	Description *string `json:"description"`
	Destination *string `json:"destination"`
	StartDate   *string `json:"start_date"`
	EndDate     *string `json:"end_date"`
}

type UpdateTripInput struct {
	Title       *string `json:"title"`
	Description *string `json:"description"`
	Destination *string `json:"destination"`
	StartDate   *string `json:"start_date"`
	EndDate     *string `json:"end_date"`
}

type TripRepository interface {
	CreateTrip(ctx context.Context, token, ownerID string, input CreateTripInput) (*Trip, error)
	GetTrips(ctx context.Context, token string) ([]Trip, error)
	GetTrip(ctx context.Context, token, tripID string) (*Trip, error)
	UpdateTrip(ctx context.Context, token, tripID string, input UpdateTripInput) (*Trip, error)
	DeleteTrip(ctx context.Context, token, tripID string) error
}

type TripUsecase interface {
	CreateTrip(ctx context.Context, userID, token string, input CreateTripInput) (*Trip, error)
	GetTrips(ctx context.Context, token string) ([]Trip, error)
	GetTrip(ctx context.Context, token, tripID string) (*Trip, error)
	UpdateTrip(ctx context.Context, userID, token, tripID string, input UpdateTripInput) (*Trip, error)
	DeleteTrip(ctx context.Context, userID, token, tripID string) error
}
