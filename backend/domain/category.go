package domain

import (
	"context"
	"time"
)

type Category struct {
	ID        string    `json:"id"`
	TripID    string    `json:"trip_id"`
	Name      string    `json:"name"`
	Color     string    `json:"color"`
	CreatedAt time.Time `json:"created_at"`
}

type CategoryRepository interface {
	GetCategories(ctx context.Context, token, tripID string) ([]Category, error)
}

type CategoryUsecase interface {
	GetCategories(ctx context.Context, token, tripID string) ([]Category, error)
}
