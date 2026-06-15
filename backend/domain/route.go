package domain

import "time"

// Route는 trip의 day별 경로(v0.8: day당 1행). day_index가 일차.
// transport_mode·route_waypoints는 폐기 — 순서·구간은 marker_days로 이동.
type Route struct {
	ID          string    `json:"id"`
	TripID      string    `json:"trip_id"`
	CreatedBy   *string   `json:"created_by,omitempty"`
	Title       string    `json:"title"`
	Description *string   `json:"description,omitempty"`
	DayIndex    int       `json:"day_index"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

type RouteRepository interface{}

type RouteUsecase interface{}
