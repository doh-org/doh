package repository

import (
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
	return &tripRepository{supabaseURL: supabaseURL, supabaseAnonKey: anonKey, httpClient: client}
}

func (r *tripRepository) GetTrip(ctx context.Context, token, tripID string) (*domain.Trip, error) {
	url := fmt.Sprintf(
		"%s/rest/v1/trips?id=eq.%s&deleted_at=is.null&select=id,owner_id,title,description,start_date,end_date,created_at",
		r.supabaseURL, tripID,
	)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("apikey", r.supabaseAnonKey)
	req.Header.Set("Accept", "application/json")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	b, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
		return nil, domain.ErrNotFound
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getTrip: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(b, &trips); err != nil {
		return nil, err
	}
	if len(trips) == 0 {
		return nil, domain.ErrNotFound
	}
	return &trips[0], nil
}
