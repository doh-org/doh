package domain

import "time"

type Category struct {
	ID        string    `json:"id"`
	TripID    string    `json:"trip_id"`
	Name      string    `json:"name"`
	Color     string    `json:"color"`
	CreatedAt time.Time `json:"created_at"`
}

type CategoryRepository interface{}

type CategoryUsecase interface{}
