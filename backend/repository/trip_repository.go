package repository

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"doh/backend/domain"
)

type tripRepository struct {
	supabaseURL     string
	supabaseAnonKey string
	httpClient      *http.Client
}

func NewTripRepository(supabaseURL, anonKey string, client *http.Client) domain.TripRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &tripRepository{
		supabaseURL:     supabaseURL,
		supabaseAnonKey: anonKey,
		httpClient:      client,
	}
}

func (r *tripRepository) GetTrips(ctx context.Context, token string) ([]domain.Trip, error) {
	url := r.supabaseURL + "/rest/v1/trips?deleted_at=is.null&select=*&order=created_at.desc"

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	r.setReadHeaders(req, token)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getTrips: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	return trips, nil
}

func (r *tripRepository) GetTrip(ctx context.Context, token, tripID string) (*domain.Trip, error) {
	url := fmt.Sprintf("%s/rest/v1/trips?id=eq.%s&deleted_at=is.null&select=*", r.supabaseURL, tripID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	r.setReadHeaders(req, token)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getTrip: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	if len(trips) == 0 {
		return nil, domain.ErrNotFound
	}
	return &trips[0], nil
}

func (r *tripRepository) UpdateTrip(ctx context.Context, token, tripID string, input domain.UpdateTripInput) (*domain.Trip, error) {
	b, err := json.Marshal(buildUpdateBody(input))
	if err != nil {
		return nil, err
	}

	url := fmt.Sprintf("%s/rest/v1/trips?id=eq.%s", r.supabaseURL, tripID)

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, url, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	r.setWriteHeaders(req, token)
	req.Header.Set("Prefer", "return=representation")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("updateTrip: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	if len(trips) == 0 {
		return nil, domain.ErrNotFound
	}
	return &trips[0], nil
}

func (r *tripRepository) DeleteTrip(ctx context.Context, token, tripID string) error {
	now := time.Now().UTC().Format(time.RFC3339)
	b, err := json.Marshal(map[string]any{"deleted_at": now})
	if err != nil {
		return err
	}

	url := fmt.Sprintf("%s/rest/v1/trips?id=eq.%s", r.supabaseURL, tripID)

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, url, bytes.NewReader(b))
	if err != nil {
		return err
	}
	r.setWriteHeaders(req, token)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, resp.Body)
	return nil
}

func (r *tripRepository) setReadHeaders(req *http.Request, token string) {
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("apikey", r.supabaseAnonKey)
}

func (r *tripRepository) setWriteHeaders(req *http.Request, token string) {
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Content-Type", "application/json")
}

func buildUpdateBody(input domain.UpdateTripInput) map[string]any {
	m := make(map[string]any)
	if input.Title != nil {
		m["title"] = *input.Title
	}
	if input.Description != nil {
		m["description"] = *input.Description
	}
	if input.Destination != nil {
		m["destination"] = *input.Destination
	}
	if input.StartDate != nil {
		m["start_date"] = *input.StartDate
	}
	if input.EndDate != nil {
		m["end_date"] = *input.EndDate
	}
	return m
}
