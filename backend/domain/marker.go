package domain

import "time"

type Marker struct {
	ID         string     `json:"id"`
	TripID     string     `json:"trip_id"`
	CategoryID *string    `json:"category_id,omitempty"`
	CreatedBy  *string    `json:"created_by,omitempty"`
	Name       string     `json:"name"`
	Latitude   float64    `json:"latitude"`
	Longitude  float64    `json:"longitude"`
	Address    *string    `json:"address,omitempty"`
	Memo       *string    `json:"memo,omitempty"`
	Source     string     `json:"source"`
	VisitTime  *time.Time `json:"visit_time,omitempty"`
	DeletedAt  *time.Time `json:"deleted_at,omitempty"`
	CreatedAt  time.Time  `json:"created_at"`
}

type MarkerPhoto struct {
	ID          string    `json:"id"`
	MarkerID    string    `json:"marker_id"`
	StoragePath string    `json:"storage_path"`
	OrderIndex  int       `json:"order_index"`
	CreatedAt   time.Time `json:"created_at"`
}

type MarkerRepository interface{}

type MarkerUsecase interface{}
