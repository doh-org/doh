package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"doh/backend/domain"
)

// GetMarkersByDay는 day의 마커 목록을 반환함. day=0=미정(미배정), day>=1=그 day stop.
func (r *markerRepository) GetMarkersByDay(ctx context.Context, token, tripID string, day int, sort domain.StopSort) ([]domain.DayMarker, error) {
	if day == 0 {
		return r.unassignedMarkers(ctx, token, tripID)
	}
	return r.dayMarkers(ctx, token, tripID, day, sort)
}

// unassignedMarkers는 day 미배정 마커를 created_at 순으로 반환함(stop 필드 nil).
func (r *markerRepository) unassignedMarkers(ctx context.Context, token, tripID string) ([]domain.DayMarker, error) {
	out := []domain.DayMarker{}
	markers, err := r.tripMarkers(ctx, token, tripID)
	if err != nil {
		return nil, err
	}
	if len(markers) == 0 {
		return out, nil
	}

	ids := make([]string, len(markers))
	for i, m := range markers {
		ids[i] = m.ID
	}
	daysMap, err := r.fetchVisitDays(ctx, token, ids)
	if err != nil {
		return nil, err
	}

	for _, m := range markers {
		if len(daysMap[m.ID]) > 0 {
			continue // 배정됨 제외
		}
		m.VisitDays = []int{}
		out = append(out, domain.DayMarker{Marker: m})
	}
	return out, nil
}

// dayMarkers는 day stop을 sort 기준으로 반환함(마커 전체필드 하이드레이트).
func (r *markerRepository) dayMarkers(ctx context.Context, token, tripID string, day int, sort domain.StopSort) ([]domain.DayMarker, error) {
	out := []domain.DayMarker{}
	routeID, err := r.findRouteID(ctx, token, tripID, day)
	if err != nil {
		return nil, err
	}
	if routeID == "" {
		return out, nil // 그 day route 없음
	}

	stops, err := r.routeStops(ctx, token, routeID, sort)
	if err != nil {
		return nil, err
	}
	if len(stops) == 0 {
		return out, nil
	}

	ids := make([]string, len(stops))
	for i, s := range stops {
		ids[i] = s.MarkerID
	}
	infoMap, err := r.markerInfoMap(ctx, token, ids)
	if err != nil {
		return nil, err
	}
	daysMap, err := r.fetchVisitDays(ctx, token, ids)
	if err != nil {
		return nil, err
	}

	for _, s := range stops {
		m, ok := infoMap[s.MarkerID]
		if !ok {
			continue // 소프트삭제·누락 마커 제외
		}
		m.VisitDays = daysMap[m.ID]
		order := s.Order
		out = append(out, domain.DayMarker{
			Marker:          m,
			Order:           &order,
			VisitTime:       s.VisitTime,
			TransportToNext: s.TransportToNext,
			DistanceToNext:  s.DistanceToNext,
			DurationToNext:  s.DurationToNext,
		})
	}
	return out, nil
}

// tripMarkers는 trip 전체 마커를 created_at 순으로 조회함(visit_days 미포함).
func (r *markerRepository) tripMarkers(ctx context.Context, token, tripID string) ([]domain.Marker, error) {
	q := url.Values{}
	q.Set("select", markerViewCols)
	q.Set("trip_id", "eq."+tripID)
	q.Set("deleted_at", "is.null")
	q.Set("order", "created_at.asc")
	return r.queryMarkers(ctx, token, q)
}

// markerInfoMap은 ids 마커 전체필드를 id→Marker로 반환함(visit_days 미포함).
func (r *markerRepository) markerInfoMap(ctx context.Context, token string, ids []string) (map[string]domain.Marker, error) {
	result := make(map[string]domain.Marker, len(ids))
	if len(ids) == 0 {
		return result, nil
	}
	q := url.Values{}
	q.Set("select", markerViewCols)
	q.Set("id", "in.("+strings.Join(ids, ",")+")")
	q.Set("deleted_at", "is.null")
	markers, err := r.queryMarkers(ctx, token, q)
	if err != nil {
		return nil, err
	}
	for _, m := range markers {
		result[m.ID] = m
	}
	return result, nil
}

// queryMarkers는 markers_view 조회를 domain.Marker로 변환함(visit_days 미포함).
func (r *markerRepository) queryMarkers(ctx context.Context, token string, q url.Values) ([]domain.Marker, error) {
	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/markers_view?"+q.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024))
	resp.Body.Close()
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("queryMarkers: status %d", resp.StatusCode)
	}
	var rows []markerRow
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	markers := make([]domain.Marker, len(rows))
	for i, row := range rows {
		markers[i] = row.toDomain()
	}
	return markers, nil
}

// routeStops는 route의 marker_days stop을 sort 기준으로 조회함.
func (r *markerRepository) routeStops(ctx context.Context, token, routeID string, sort domain.StopSort) ([]stopRow, error) {
	q := url.Values{}
	q.Set("route_id", "eq."+routeID)
	q.Set("select", "marker_id,order,visit_time,transport_to_next,distance_to_next,duration_to_next")
	if sort == domain.SortByOrder {
		q.Set("order", "order.asc")
	} else {
		q.Set("order", "visit_time.asc.nullslast,order.asc")
	}

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/marker_days?"+q.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 256*1024))
	resp.Body.Close()
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("routeStops: status %d", resp.StatusCode)
	}
	var rows []stopRow
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}
