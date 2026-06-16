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

// fetchVisitDays는 markerIDs의 방문 day를 조회함. day_index는 marker_days에 직접 저장됨.
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
	params.Set("select", "marker_id,day_index")

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
		DayIndex int    `json:"day_index"`
	}
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	for _, row := range rows {
		result[row.MarkerID] = append(result[row.MarkerID], row.DayIndex)
	}
	for id := range result {
		sort.Ints(result[id])
	}
	return result, nil
}

// setMarkerDays는 마커의 day 배정을 days로 맞춤(diff/upsert).
// 유지 day의 stop은 보존(순서·구간 캐시 유실 방지), 빠진 day는 삭제, 새 day는 max(order)+1로 삽입.
func (r *markerRepository) setMarkerDays(ctx context.Context, token, tripID, markerID string, days []int) error {
	desired := make(map[int]bool, len(days))
	for _, day := range days {
		desired[day] = true
	}

	existing, err := r.existingMarkerDays(ctx, token, markerID)
	if err != nil {
		return err
	}
	have := make(map[int]bool, len(existing))
	for _, e := range existing {
		have[e.DayIndex] = true
		if !desired[e.DayIndex] {
			if err := r.deleteMarkerDayByID(ctx, token, e.ID); err != nil {
				return err
			}
		}
	}

	for day := range desired {
		if have[day] {
			continue
		}
		order, err := r.maxDayOrder(ctx, token, tripID, day)
		if err != nil {
			return err
		}
		if err := r.insertMarkerDay(ctx, token, tripID, markerID, day, order+1); err != nil {
			return err
		}
	}
	return nil
}

type markerDayRef struct {
	ID       string `json:"id"`
	DayIndex int    `json:"day_index"`
}

func (r *markerRepository) existingMarkerDays(ctx context.Context, token, markerID string) ([]markerDayRef, error) {
	q := url.Values{}
	q.Set("marker_id", "eq."+markerID)
	q.Set("select", "id,day_index")

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

// maxDayOrder는 (trip, day)의 최대 order를 반환함. stop 없으면 0.
func (r *markerRepository) maxDayOrder(ctx context.Context, token, tripID string, day int) (int, error) {
	q := url.Values{}
	q.Set("trip_id", "eq."+tripID)
	q.Set("day_index", "eq."+strconv.Itoa(day))
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

func (r *markerRepository) insertMarkerDay(ctx context.Context, token, tripID, markerID string, day, order int) error {
	body := map[string]any{"marker_id": markerID, "trip_id": tripID, "day_index": day, "order": order}
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
