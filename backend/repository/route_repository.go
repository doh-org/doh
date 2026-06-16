package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"doh/backend/domain"
)

type routeRepository struct {
	supabaseURL     string
	supabaseAnonKey string
	httpClient      *http.Client
}

func NewRouteRepository(supabaseURL, anonKey string, client *http.Client) domain.RouteRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &routeRepository{supabaseURL: supabaseURL, supabaseAnonKey: anonKey, httpClient: client}
}

func (r *routeRepository) restReq(ctx context.Context, method, rawURL string, body any, token, prefer string) (*http.Response, error) {
	var reqBody io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reqBody = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, rawURL, reqBody)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if prefer != "" {
		req.Header.Set("Prefer", prefer)
	}
	return r.httpClient.Do(req)
}

type stopRow struct {
	MarkerID        string   `json:"marker_id"`
	Order           int      `json:"order"`
	VisitTime       *string  `json:"visit_time"`
	TransportToNext *string  `json:"transport_to_next"`
	DistanceToNext  *float64 `json:"distance_to_next"`
	DurationToNext  *int     `json:"duration_to_next"`
}

// GetDayStops는 (trip, day) stop을 sort 기준으로 반환함.
// sort=order면 order asc, 그 외(기본)는 visit_time asc(미정 하단)·order 순.
// stop 없으면 빈 목록. 마커 표시정보는 markers_view에서 하이드레이트.
func (r *routeRepository) GetDayStops(ctx context.Context, token, tripID string, day int, sort domain.StopSort) ([]domain.RouteStop, error) {
	q := url.Values{}
	q.Set("trip_id", "eq."+tripID)
	q.Set("day_index", "eq."+strconv.Itoa(day))
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
		return nil, fmt.Errorf("GetDayStops: status %d", resp.StatusCode)
	}
	var rows []stopRow
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return []domain.RouteStop{}, nil
	}

	ids := make([]string, len(rows))
	for i, row := range rows {
		ids[i] = row.MarkerID
	}
	markers, err := r.fetchMarkerInfo(ctx, token, ids)
	if err != nil {
		return nil, err
	}

	stops := make([]domain.RouteStop, 0, len(rows))
	for _, row := range rows {
		mi, ok := markers[row.MarkerID]
		if !ok {
			continue // 소프트삭제·누락 마커 제외
		}
		stops = append(stops, domain.RouteStop{
			MarkerID:        row.MarkerID,
			Name:            mi.Name,
			Latitude:        mi.Latitude,
			Longitude:       mi.Longitude,
			CategoryID:      mi.CategoryID,
			Order:           row.Order,
			VisitTime:       row.VisitTime,
			TransportToNext: row.TransportToNext,
			DistanceToNext:  row.DistanceToNext,
			DurationToNext:  row.DurationToNext,
		})
	}
	return stops, nil
}

type markerInfo struct {
	Name       string  `json:"name"`
	Latitude   float64 `json:"latitude"`
	Longitude  float64 `json:"longitude"`
	CategoryID *string `json:"category_id"`
}

func (r *routeRepository) fetchMarkerInfo(ctx context.Context, token string, ids []string) (map[string]markerInfo, error) {
	result := make(map[string]markerInfo, len(ids))
	if len(ids) == 0 {
		return result, nil
	}
	q := url.Values{}
	q.Set("id", "in.("+strings.Join(ids, ",")+")")
	q.Set("deleted_at", "is.null")
	q.Set("select", "id,name,latitude,longitude,category_id")

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
		return nil, fmt.Errorf("fetchMarkerInfo: status %d", resp.StatusCode)
	}
	var rows []struct {
		ID string `json:"id"`
		markerInfo
	}
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	for _, row := range rows {
		result[row.ID] = row.markerInfo
	}
	return result, nil
}

// UpdateStop은 (route, marker) stop의 visit_time·transport_to_next를 반영.
// transport 설정 시 distance/duration 캐시를 무효화(NULL).
func (r *routeRepository) UpdateStop(ctx context.Context, token, tripID string, day int, markerID string, patch domain.StopPatch) error {
	body := map[string]any{}
	if patch.SetVisitTime {
		body["visit_time"] = patch.VisitTime
	}
	if patch.SetTransport {
		body["transport_to_next"] = patch.Transport
		body["distance_to_next"] = nil
		body["duration_to_next"] = nil
	}
	if len(body) == 0 {
		return nil
	}

	q := url.Values{}
	q.Set("trip_id", "eq."+tripID)
	q.Set("day_index", "eq."+strconv.Itoa(day))
	q.Set("marker_id", "eq."+markerID)

	resp, err := r.restReq(ctx, http.MethodPatch, r.supabaseURL+"/rest/v1/marker_days?"+q.Encode(), body, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusForbidden {
		return domain.ErrNotFound
	}
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("UpdateStop: status %d body %s", resp.StatusCode, b)
	}
	return nil
}

// ReorderDay는 markerIDs 순서대로 order를 1..N 재작성함(bulk upsert, 단일 트랜잭션).
// uq_md_trip_day_order DEFERRABLE 덕에 중간 중복 위반 없음. 집합 일치 검증은 usecase.
func (r *routeRepository) ReorderDay(ctx context.Context, token, tripID string, day int, markerIDs []string) error {
	idMap, err := r.markerDayIDs(ctx, token, tripID, day)
	if err != nil {
		return err
	}

	rows := make([]map[string]any, 0, len(markerIDs))
	for i, mid := range markerIDs {
		id, ok := idMap[mid]
		if !ok {
			return domain.ErrNotFound
		}
		rows = append(rows, map[string]any{
			"id": id, "marker_id": mid, "trip_id": tripID, "day_index": day, "order": i + 1,
		})
	}

	resp, err := r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/marker_days", rows, token, "resolution=merge-duplicates,return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("ReorderDay: status %d body %s", resp.StatusCode, b)
	}
	return nil
}

func (r *routeRepository) markerDayIDs(ctx context.Context, token, tripID string, day int) (map[string]string, error) {
	q := url.Values{}
	q.Set("trip_id", "eq."+tripID)
	q.Set("day_index", "eq."+strconv.Itoa(day))
	q.Set("select", "id,marker_id")

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
		return nil, fmt.Errorf("markerDayIDs: status %d", resp.StatusCode)
	}
	var rows []struct {
		ID       string `json:"id"`
		MarkerID string `json:"marker_id"`
	}
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	result := make(map[string]string, len(rows))
	for _, row := range rows {
		result[row.MarkerID] = row.ID
	}
	return result, nil
}
