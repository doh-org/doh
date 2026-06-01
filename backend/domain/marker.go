package domain

import (
	"context"
	"encoding/json"
	"time"
)

type Marker struct {
	ID         string         `json:"id"`
	TripID     string         `json:"trip_id"`
	CategoryID *string        `json:"category_id,omitempty"`
	CreatedBy  *string        `json:"created_by,omitempty"`
	Name       string         `json:"name"`
	Latitude   float64        `json:"latitude"`
	Longitude  float64        `json:"longitude"`
	Address    *string        `json:"address,omitempty"`
	Memo       *string        `json:"memo,omitempty"`
	Source     string         `json:"source"`
	Detail     map[string]any `json:"detail"`
	VisitTime  *string        `json:"visit_time,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
}

type CreateMarkerInput struct {
	Name       string         `json:"name"`
	Latitude   float64        `json:"latitude"`
	Longitude  float64        `json:"longitude"`
	Source     string         `json:"source"`
	CategoryID *string        `json:"category_id"`
	Address    *string        `json:"address"`
	Detail     map[string]any `json:"detail"`
	VisitTime  *string        `json:"visit_time"`
}

// UpdateMarkerInput — nil 필드는 변경 없음. CategoryID/VisitTime은 RawMessage로 null(해제)과 omit(무변경) 구분.
type UpdateMarkerInput struct {
	Name       *string         `json:"name"`
	Latitude   *float64        `json:"latitude"`
	Longitude  *float64        `json:"longitude"`
	CategoryID json.RawMessage `json:"category_id"`
	Address    *string         `json:"address"`
	VisitTime  json.RawMessage `json:"visit_time"`
}

var ValidSources = map[string]bool{
	"search": true, "longpress": true, "share": true,
}

type MarkerRepository interface {
	CreateMarker(ctx context.Context, token, tripID, userID string, input CreateMarkerInput) (*Marker, error)
	GetMarkers(ctx context.Context, token, tripID string, q, categoryID *string) ([]Marker, error)
	GetMarker(ctx context.Context, token, tripID, markerID string) (*Marker, error)
	UpdateMarker(ctx context.Context, token, tripID, markerID string, input UpdateMarkerInput) (*Marker, error)
	DeleteMarker(ctx context.Context, token, tripID, markerID string) error
}

type MarkerUsecase interface {
	CreateMarker(ctx context.Context, token, tripID, userID string, input CreateMarkerInput) (*Marker, error)
	GetMarkers(ctx context.Context, token, tripID string, q, categoryID *string) ([]Marker, error)
	GetMarker(ctx context.Context, token, tripID, markerID string) (*Marker, error)
	UpdateMarker(ctx context.Context, token, tripID, markerID string, input UpdateMarkerInput) (*Marker, error)
	DeleteMarker(ctx context.Context, token, tripID, markerID string) error
}
