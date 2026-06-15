package repository

import (
	"bytes"
	"context"
	crand "crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
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

func (r *markerRepository) GetMarkers(ctx context.Context, token, tripID string, q, categoryID *string) ([]domain.Marker, error) {
	params := url.Values{}
	params.Set("select", markerViewCols)
	params.Set("trip_id", "eq."+tripID)
	params.Set("deleted_at", "is.null")
	params.Set("order", "created_at.asc")
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

	// 마커는 day 미배정 상태로 생성된다(미정 탭). 날짜 지정 시에만 stop 생성.
	if len(input.VisitDays) > 0 {
		if err := r.setMarkerDays(ctx, token, tripID, markerID, userID, input.VisitDays); err != nil {
			return nil, err
		}
	}

	return r.GetMarker(ctx, token, tripID, markerID)
}

func (r *markerRepository) UpdateMarker(ctx context.Context, token, tripID, markerID, userID string, input domain.UpdateMarkerInput) (*domain.Marker, error) {
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
		if err := r.setMarkerDays(ctx, token, tripID, markerID, userID, *input.VisitDays); err != nil {
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
