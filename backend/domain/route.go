package domain

import (
	"context"
	"encoding/json"
)

// RouteStop = 그날의 stop(marker_days 한 행) + 마커 표시 정보.
// 구간(이동수단·거리·시간)은 다음 stop까지를 의미(_to_next). 마지막 stop은 NULL.
type RouteStop struct {
	MarkerID        string   `json:"marker_id"`
	Name            string   `json:"name"`
	Latitude        float64  `json:"latitude"`
	Longitude       float64  `json:"longitude"`
	CategoryID      *string  `json:"category_id,omitempty"`
	Order           int      `json:"order"`
	VisitTime       *string  `json:"visit_time"`        // "HH:MM:SS" 또는 null. 도착 시각(시각만).
	TransportToNext *string  `json:"transport_to_next"` // car|foot|publictransit|bicycle 또는 null
	DistanceToNext  *float64 `json:"distance_to_next"`  // Directions API 캐시
	DurationToNext  *int     `json:"duration_to_next"`  // API 캐시(초)
}

// UpdateStopInput — stop 부분 수정. RawMessage로 미제공/null/값 3상태 구분.
type UpdateStopInput struct {
	VisitTime       json.RawMessage `json:"visit_time"`
	TransportToNext json.RawMessage `json:"transport_to_next"`
}

// StopPatch — usecase가 검증·정규화한 결과. repository가 그대로 반영.
type StopPatch struct {
	SetVisitTime bool
	VisitTime    *string // nil = NULL로 해제
	SetTransport bool
	Transport    *string // nil = NULL로 해제. 설정 시 distance/duration 캐시 무효화.
}

// ReorderInput — Day 내 마커 순서(새 순서대로 marker_id 배열).
type ReorderInput struct {
	MarkerIDs []string `json:"marker_ids"`
}

// ValidTransportModes — 구간 이동수단 허용값.
var ValidTransportModes = map[string]bool{
	"car": true, "foot": true, "publictransit": true, "bicycle": true,
}

// StopSort — Day stop 정렬 기준.
type StopSort string

const (
	SortByVisitTime StopSort = "visit_time" // 방문시간 asc(미정 하단), 동률 order. 기본값.
	SortByOrder     StopSort = "order"      // order asc(수동 순서).
)

type RouteRepository interface {
	GetDayStops(ctx context.Context, token, tripID string, day int, sort StopSort) ([]RouteStop, error)
	UpdateStop(ctx context.Context, token, tripID string, day int, markerID string, patch StopPatch) error
	ReorderDay(ctx context.Context, token, tripID string, day int, markerIDs []string, clearTransport map[string]bool) error
}

type RouteUsecase interface {
	UpdateStop(ctx context.Context, token, tripID string, day int, markerID string, input UpdateStopInput) (*RouteStop, error)
	ReorderDay(ctx context.Context, token, tripID string, day int, markerIDs []string) (int, error)
}
