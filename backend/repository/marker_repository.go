package repository

import (
	"bytes"
	"context"
	crand "crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"time"

	"doh/backend/domain"
)

const markerViewCols = "id,trip_id,category_id,created_by,name,latitude,longitude,address,memo,source,detail,created_at"

type markerRepository struct {
	supabaseURL     string
	supabaseAnonKey string
	httpClient      *http.Client
}

func NewMarkerRepository(supabaseURL, anonKey string, client *http.Client) domain.MarkerRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &markerRepository{supabaseURL: supabaseURL, supabaseAnonKey: anonKey, httpClient: client}
}

type markerRow struct {
	ID         string         `json:"id"`
	TripID     string         `json:"trip_id"`
	CategoryID *string        `json:"category_id"`
	CreatedBy  *string        `json:"created_by"`
	Name       string         `json:"name"`
	Latitude   float64        `json:"latitude"`
	Longitude  float64        `json:"longitude"`
	Address    *string        `json:"address"`
	Memo       *string        `json:"memo"`
	Source     string         `json:"source"`
	Detail     map[string]any `json:"detail"`
	CreatedAt  time.Time      `json:"created_at"`
	Waypoints  []struct {
		Order int `json:"order"`
	} `json:"route_waypoints"`
}

func (row markerRow) toDomain() domain.Marker {
	return domain.Marker{
		ID: row.ID, TripID: row.TripID, CategoryID: row.CategoryID, CreatedBy: row.CreatedBy,
		Name: row.Name, Latitude: row.Latitude, Longitude: row.Longitude,
		Address: row.Address, Memo: row.Memo, Source: row.Source,
		Detail: row.Detail, VisitDays: []int{}, CreatedAt: row.CreatedAt,
	}
}

func (r *markerRepository) restReq(ctx context.Context, method, rawURL string, body map[string]any, token, prefer string) (*http.Response, error) {
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

// fetchVisitDays는 markerIDs에 해당하는 marker_days를 일괄 조회한다.
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
	params.Set("order", "day_index.asc")

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
	return result, nil
}

// setMarkerDays는 마커의 marker_days를 전부 삭제 후 days로 재삽입한다.
func (r *markerRepository) setMarkerDays(ctx context.Context, token, markerID string, days []int) error {
	delURL := fmt.Sprintf("%s/rest/v1/marker_days?marker_id=eq.%s", r.supabaseURL, markerID)
	resp, err := r.restReq(ctx, http.MethodDelete, delURL, nil, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("deleteMarkerDays: status %d body %s", resp.StatusCode, b)
	}

	for _, day := range days {
		body := map[string]any{"marker_id": markerID, "day_index": day}
		resp, err := r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/marker_days", body, token, "return=minimal")
		if err != nil {
			return err
		}
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		resp.Body.Close()
		if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent {
			return fmt.Errorf("insertMarkerDay: status %d body %s", resp.StatusCode, b)
		}
	}
	return nil
}

func (r *markerRepository) GetMarkers(ctx context.Context, token, tripID string, q, categoryID *string) ([]domain.Marker, error) {
	params := url.Values{}
	params.Set("select", markerViewCols+",route_waypoints(order)")
	params.Set("trip_id", "eq."+tripID)
	params.Set("deleted_at", "is.null")
	if q != nil {
		params.Set("name", "ilike.*"+*q+"*")
	}
	if categoryID != nil {
		if *categoryID == "null" {
			params.Set("category_id", "is.null")
		} else {
			params.Set("category_id", "eq."+*categoryID)
		}
	}

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/markers_view?"+params.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getMarkers: status %d", resp.StatusCode)
	}

	var rows []markerRow
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}

	sort.SliceStable(rows, func(i, j int) bool {
		oi, oj := math.MaxInt, math.MaxInt
		if len(rows[i].Waypoints) > 0 {
			oi = rows[i].Waypoints[0].Order
		}
		if len(rows[j].Waypoints) > 0 {
			oj = rows[j].Waypoints[0].Order
		}
		if oi != oj {
			return oi < oj
		}
		return rows[i].CreatedAt.Before(rows[j].CreatedAt)
	})

	markers := make([]domain.Marker, len(rows))
	for i, row := range rows {
		markers[i] = row.toDomain()
	}

	if len(markers) > 0 {
		ids := make([]string, len(markers))
		for i, m := range markers {
			ids[i] = m.ID
		}
		daysMap, err := r.fetchVisitDays(ctx, token, ids)
		if err != nil {
			return nil, err
		}
		for i := range markers {
			markers[i].VisitDays = daysMap[markers[i].ID]
		}
	}
	return markers, nil
}

func (r *markerRepository) GetMarker(ctx context.Context, token, tripID, markerID string) (*domain.Marker, error) {
	params := url.Values{}
	params.Set("select", markerViewCols)
	params.Set("id", "eq."+markerID)
	params.Set("trip_id", "eq."+tripID)
	params.Set("deleted_at", "is.null")

	resp, err := r.restReq(ctx, http.MethodGet, r.supabaseURL+"/rest/v1/markers_view?"+params.Encode(), nil, token, "")
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getMarker: status %d", resp.StatusCode)
	}

	var rows []markerRow
	if err := json.Unmarshal(b, &rows); err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return nil, domain.ErrNotFound
	}
	m := rows[0].toDomain()

	daysMap, err := r.fetchVisitDays(ctx, token, []string{markerID})
	if err != nil {
		return nil, err
	}
	m.VisitDays = daysMap[markerID]
	return &m, nil
}

func (r *markerRepository) CreateMarker(ctx context.Context, token, tripID, userID string, input domain.CreateMarkerInput) (*domain.Marker, error) {
	detail := input.Detail
	if detail == nil {
		detail = map[string]any{}
	}
	body := map[string]any{
		"trip_id":    tripID,
		"created_by": userID,
		"name":       input.Name,
		"location":   fmt.Sprintf("POINT(%f %f)", input.Longitude, input.Latitude),
		"source":     input.Source,
		"detail":     detail,
	}
	if input.CategoryID != nil {
		body["category_id"] = *input.CategoryID
	}
	if input.Address != nil {
		body["address"] = *input.Address
	}

	markerID, err := newUUID()
	if err != nil {
		return nil, err
	}
	body["id"] = markerID

	resp, err := r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/markers", body, token, "return=minimal")
	if err != nil {
		return nil, err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent {
		return nil, fmt.Errorf("createMarker: status %d body %s", resp.StatusCode, b)
	}

	if err := r.addWaypoint(ctx, token, tripID, markerID); err != nil {
		return nil, err
	}

	if len(input.VisitDays) > 0 {
		if err := r.setMarkerDays(ctx, token, markerID, input.VisitDays); err != nil {
			return nil, err
		}
	}

	return r.GetMarker(ctx, token, tripID, markerID)
}

func (r *markerRepository) addWaypoint(ctx context.Context, token, tripID, markerID string) error {
	routeURL := fmt.Sprintf("%s/rest/v1/routes?trip_id=eq.%s&select=id&limit=1", r.supabaseURL, tripID)
	resp, err := r.restReq(ctx, http.MethodGet, routeURL, nil, token, "")
	if err != nil {
		return err
	}
	b, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	resp.Body.Close()
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("getRoute: status %d", resp.StatusCode)
	}
	var routes []struct{ ID string `json:"id"` }
	if err := json.Unmarshal(b, &routes); err != nil {
		return err
	}
	if len(routes) == 0 {
		return fmt.Errorf("no route for trip %s", tripID)
	}
	routeID := routes[0].ID

	wpURL := fmt.Sprintf("%s/rest/v1/route_waypoints?route_id=eq.%s&select=order&order=order.desc&limit=1", r.supabaseURL, routeID)
	resp, err = r.restReq(ctx, http.MethodGet, wpURL, nil, token, "")
	if err != nil {
		return err
	}
	b, err = io.ReadAll(io.LimitReader(resp.Body, 4096))
	resp.Body.Close()
	if err != nil {
		return err
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("getWaypoints: status %d", resp.StatusCode)
	}
	var wps []struct{ Order int `json:"order"` }
	if err := json.Unmarshal(b, &wps); err != nil {
		return err
	}
	nextOrder := 0
	if len(wps) > 0 {
		nextOrder = wps[0].Order + 1
	}

	wpBody := map[string]any{"route_id": routeID, "marker_id": markerID, "order": nextOrder}
	resp, err = r.restReq(ctx, http.MethodPost, r.supabaseURL+"/rest/v1/route_waypoints", wpBody, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ = io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode != http.StatusCreated && resp.StatusCode != http.StatusNoContent {
		return fmt.Errorf("insertWaypoint: status %d body %s", resp.StatusCode, b)
	}
	return nil
}

func (r *markerRepository) UpdateMarker(ctx context.Context, token, tripID, markerID string, input domain.UpdateMarkerInput) (*domain.Marker, error) {
	body := map[string]any{}
	if input.Name != nil {
		body["name"] = *input.Name
	}
	if input.Latitude != nil && input.Longitude != nil {
		body["location"] = fmt.Sprintf("POINT(%f %f)", *input.Longitude, *input.Latitude)
	}
	if len(input.CategoryID) > 0 {
		if string(input.CategoryID) == "null" {
			body["category_id"] = nil
		} else {
			var catID string
			if err := json.Unmarshal(input.CategoryID, &catID); err == nil {
				body["category_id"] = catID
			}
		}
	}
	if input.Address != nil {
		body["address"] = *input.Address
	}

	if len(body) == 0 && input.VisitDays == nil {
		return r.GetMarker(ctx, token, tripID, markerID)
	}

	if len(body) > 0 {
		params := url.Values{}
		params.Set("id", "eq."+markerID)
		params.Set("trip_id", "eq."+tripID)

		resp, err := r.restReq(ctx, http.MethodPatch, r.supabaseURL+"/rest/v1/markers?"+params.Encode(), body, token, "return=minimal")
		if err != nil {
			return nil, err
		}
		b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		resp.Body.Close()
		if resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusForbidden {
			return nil, domain.ErrNotFound
		}
		if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
			return nil, fmt.Errorf("updateMarker: status %d body %s", resp.StatusCode, b)
		}
	}

	if input.VisitDays != nil {
		if err := r.setMarkerDays(ctx, token, markerID, *input.VisitDays); err != nil {
			return nil, err
		}
	}

	return r.GetMarker(ctx, token, tripID, markerID)
}

func (r *markerRepository) DeleteMarker(ctx context.Context, token, tripID, markerID string) error {
	params := url.Values{}
	params.Set("id", "eq."+markerID)
	params.Set("trip_id", "eq."+tripID)

	resp, err := r.restReq(ctx, http.MethodDelete, r.supabaseURL+"/rest/v1/markers?"+params.Encode(), nil, token, "return=minimal")
	if err != nil {
		return err
	}
	b, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
	resp.Body.Close()
	if resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusForbidden {
		return domain.ErrNotFound
	}
	if resp.StatusCode != http.StatusNoContent && resp.StatusCode != http.StatusOK {
		return fmt.Errorf("deleteMarker: status %d body %s", resp.StatusCode, b)
	}
	return nil
}

func newUUID() (string, error) {
	b := make([]byte, 16)
	if _, err := io.ReadFull(crand.Reader, b); err != nil {
		return "", err
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16]), nil
}
