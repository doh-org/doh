package domain

import "time"

type Route struct {
	ID            string    `json:"id"`
	TripID        string    `json:"trip_id"`
	CreatedBy     *string   `json:"created_by,omitempty"`
	Title         string    `json:"title"`
	Description   *string   `json:"description,omitempty"`
	TransportMode string    `json:"transport_mode"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type RouteWaypoint struct {
	ID       string `json:"id"`
	RouteID  string `json:"route_id"`
	MarkerID string `json:"marker_id"`
	Order    int    `json:"order"`
}

type RouteRepository interface{}

type RouteUsecase interface{}
