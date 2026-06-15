package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
)

// fetchVisitDays는 markerIDs의 방문 day를 조회한다.
// day는 marker_days.route_id → routes.day_index 조인으로 파생(직접 저장 안 함).
func (r *markerRepository) fetchVisitDays(ctx context.Context, token string, markerIDs []string) (map[string][]int, error) {
	result := make(map[string][]int, len(markerIDs))
	for _, id := range markerIDs {
		result[id] = []int{}
	}
	if len(markerIDs) == 0 {
		return result, nil
	}

	params := url.Values{}
	params.Set("marker_id", "in.("+strings.Join(markerIDs, ",")+")")
	params.Set("select", "marker_id,routes(day_index)")

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/marker_days?"+params.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(io.LimitReader(resp.Body, 256*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetchVisitDays: status %d", resp.StatusCode)
	}

	var rows []struct {
		MarkerID string `json:"marker_id"`
		Route    struct {
			DayIndex int `json:"day_index"`
		} `json:"routes"`
	}
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	for _, row := range rows {
		result[row.MarkerID] = append(result[row.MarkerID], row.Route.DayIndex)
	}
	for id := range result {
		sort.Ints(result[id])
	}
	return result, nil
}

// setMarkerDays는 마커의 day 배정을 days로 맞춘다(diff/upsert).
// 유지되는 day의 stop은 보존(순서·구간 캐시 유실 방지), 빠진 day는 삭제, 새 day는 max(order)+1로 삽입.
func (r *markerRepository) setMarkerDays(ctx context.Context, token, tripID, markerID, userID string, days []int) error {
	desired := make(map[string]bool, len(days))
	for _, day := range days {
		routeID, err := r.routeForDay(ctx, token, tripID, userID, day)
		if err != nil {
			return err
		}
		desired[routeID] = true
	}

	existing, err := r.existingMarkerDays(ctx, token, markerID)
	if err != nil {
		return err
	}
	have := make(map[string]bool, len(existing))
	for _, e := range existing {
		have[e.RouteID] = true
		if !desired[e.RouteID] {
			if err := r.deleteMarkerDayByID(ctx, token, e.ID); err != nil {
				return err
			}
		}
	}

	for routeID := range desired {
		if have[routeID] {
			continue
		}
		order, err := r.maxRouteOrder(ctx, token, routeID)
		if err != nil {
			return err
		}
		if err := r.insertMarkerDay(ctx, token, markerID, routeID, order+1); err != nil {
			return err
		}
	}
	return nil
}

// routeForDay는 (tripID, day)의 route id를 반환한다. 없으면 lazy 생성.
func (r *markerRepository) routeForDay(ctx context.Context, token, tripID, userID string, day int) (string, error) {
	id, err := r.findRouteID(ctx, token, tripID, day)
	if err != nil {
		return "", err
	}
	if id != "" {
		return id, nil
	}

	newID, err := newUUID()
	if err != nil {
		return "", err
	}
	body := map[string]any{"id": newID, "trip_id": tripID, "day_index": day, "title": "기본 경로"}
	if userID != "" {
		body["created_by"] = userID // RLS routes_insert_member: created_by = auth.uid()
	}
	resp, err := r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/routes", body, token, "return=minimal")
	if err != nil {
		return "", err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	switch resp.StatusCode {
	case http.StatusCreated, http.StatusNoContent:
		return newID, nil
	case http.StatusConflict: // 동시 생성 경합 → 기존 route 재조회
		return r.findRouteID(ctx, token, tripID, day)
	default:
		return "", fmt.Errorf("routeForDay: status %d body %s", resp.StatusCode, b)
	}
}

func (r *markerRepository) findRouteID(ctx context.Context, token, tripID string, day int) (string, error) {
	q := url.Values{}
	q.Set("trip_id", "eq."+tripID)
	q.Set("day_index", "eq."+strconv.Itoa(day))
	q.Set("select", "id")
	q.Set("limit", "1")

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/routes?"+q.Encode(), nil, token, "")
	if err != nil {
		return "", err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	resp.Body.Close()
	if err != nil {
		return "", err
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("findRouteID: status %d", resp.StatusCode)
	}
	var routes []struct {
		ID string `json:"id"`
	}
	if err := json.Unmarshal(b, &routes); err != nil {
		return "", err
	}
	if len(routes) == 0 {
		return "", nil
	}
	return routes[0].ID, nil
}

type markerDayRef struct {
	ID      string `json:"id"`
	RouteID string `json:"route_id"`
}

func (r *markerRepository) existingMarkerDays(ctx context.Context, token, markerID string) ([]markerDayRef, error) {
	q := url.Values{}
	q.Set("marker_id", "eq."+markerID)
	q.Set("select", "id,route_id")

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/marker_days?"+q.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	resp.Body.Close()
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("existingMarkerDays: status %d", resp.StatusCode)
	}
	var rows []markerDayRef
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	return rows, nil
}

func (r *markerRepository) maxRouteOrder(ctx context.Context, token, routeID string) (int, error) {
	q := url.Values{}
	q.Set("route_id", "eq."+routeID)
	q.Set("select", "order")

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/marker_days?"+q.Encode(), nil, token, "")
	if err != nil {
		return 0, err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	resp.Body.Close()
	if err != nil {
		return 0, err
	}
	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("maxRouteOrder: status %d", resp.StatusCode)
	}
	var rows []struct {
		Order int `json:"order"`
	}
	if err := json.Unmarshal(b, &rows); err != nil {
		return 0, err
	}
	max := 0
	for _, row := range rows {
		if row.Order > max {
			max = row.Order
		}
	}
	return max, nil
}

func (r *markerRepository) insertMarkerDay(ctx context.Context, token, markerID, routeID string, order int) error {
	body := map[string]any{"marker_id": markerID, "route_id": routeID, "order": order}
	resp, err := r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/marker_days", body, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("insertMarkerDay: status %d body %s", resp.StatusCode, b)
	}
	return nil
}

func (r *markerRepository) deleteMarkerDayByID(ctx context.Context, token, id string) error {
	delURL := fmt.Sprintf("%s/rest/v1/marker_days?id=eq.%s", r.supabaseURL, id)
	resp, err := r.restReq(ctx, http.MethodDelete, delURL, nil, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("deleteMarkerDay: status %d body %s", resp.StatusCode, b)
	}
	return nil
}
