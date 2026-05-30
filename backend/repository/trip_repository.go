package repository

import (
	"bytes"
	"context"
	crand "crypto/rand"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
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

func (r *tripRepository) CreateTrip(ctx context.Context, token string, ownerID string, input domain.CreateTripInput) (*domain.Trip, error) {
	id, err := newUUID()
	if err != nil {
		return nil, fmt.Errorf("createTrip: generate id: %w", err)
	}
	body := map[string]any{"id": id, "owner_id": ownerID, "title": input.Title}
	if input.Description != nil {
		body["description"] = *input.Description
	}
	if input.Destination != nil {
		body["destination"] = *input.Destination
	}
	if input.StartDate != nil {
		body["start_date"] = *input.StartDate
	}
	if input.EndDate != nil {
		body["end_date"] = *input.EndDate
	}

	b, err := json.Marshal(body)
	if err != nil {
		return nil, err
	}

	url := r.supabaseURL + "/rest/v1/trips"
	slog.Info("[trip] repo.CreateTrip: request", "url", url, "body", string(b))

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	r.setWriteHeaders(req, token)
	req.Header.Set("Prefer", "return=minimal")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		slog.Error("[trip] repo.CreateTrip: http error", "err", err)
		return nil, err
	}
	defer resp.Body.Close()
	io.Copy(io.Discard, resp.Body)

	slog.Info("[trip] repo.CreateTrip: response", "status", resp.StatusCode, "id", id)
	if resp.StatusCode != http.StatusCreated {
		return nil, fmt.Errorf("createTrip: status %d", resp.StatusCode)
	}

	slog.Info("[trip] repo.CreateTrip: insert ok, fetching trip", "id", id)
	return r.GetTrip(ctx, token, id)
}

func (r *tripRepository) GetTrips(ctx context.Context, token string) ([]domain.Trip, error) {
	url := r.supabaseURL + "/rest/v1/trips?deleted_at=is.null&select=*&order=created_at.desc"
	slog.Info("[trip] repo.GetTrips: request", "url", url)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	r.setReadHeaders(req, token)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		slog.Error("[trip] repo.GetTrips: http error", "err", err)
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		slog.Error("[trip] repo.GetTrips: unexpected status", "status", resp.StatusCode, "body", string(body))
		return nil, fmt.Errorf("getTrips: status %d", resp.StatusCode)
	}
	slog.Info("[trip] repo.GetTrips: response ok", "status", resp.StatusCode)

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	return trips, nil
}

func (r *tripRepository) GetTrip(ctx context.Context, token, tripID string) (*domain.Trip, error) {
	url := fmt.Sprintf("%s/rest/v1/trips?id=eq.%s&deleted_at=is.null&select=*", r.supabaseURL, tripID)
	slog.Info("[trip] repo.GetTrip: request", "tripID", tripID)

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, err
	}
	r.setReadHeaders(req, token)

	resp, err := r.httpClient.Do(req)
	if err != nil {
		slog.Error("[trip] repo.GetTrip: http error", "err", err)
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		slog.Error("[trip] repo.GetTrip: unexpected status", "status", resp.StatusCode, "body", string(body))
		return nil, fmt.Errorf("getTrip: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	if len(trips) == 0 {
		slog.Warn("[trip] repo.GetTrip: not found", "tripID", tripID)
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
	slog.Info("[trip] repo.UpdateTrip: request", "url", url)

	req, err := http.NewRequestWithContext(ctx, http.MethodPatch, url, bytes.NewReader(b))
	if err != nil {
		return nil, err
	}
	r.setWriteHeaders(req, token)
	req.Header.Set("Prefer", "return=representation")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		slog.Error("[trip] repo.UpdateTrip: http error", "err", err)
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 64*1024))
	if err != nil {
		return nil, err
	}
	slog.Info("[trip] repo.UpdateTrip: response", "status", resp.StatusCode, "body", string(body))
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("updateTrip: status %d", resp.StatusCode)
	}

	var trips []domain.Trip
	if err := json.Unmarshal(body, &trips); err != nil {
		return nil, err
	}
	if len(trips) == 0 {
		slog.Warn("[trip] repo.UpdateTrip: 0 rows affected", "tripID", tripID)
		return nil, domain.ErrNotFound
	}
	slog.Info("[trip] repo.UpdateTrip: success", "tripID", tripID)
	return &trips[0], nil
}

func (r *tripRepository) DeleteTrip(ctx context.Context, token, tripID string) error {
	url := fmt.Sprintf("%s/rest/v1/trips?id=eq.%s", r.supabaseURL, tripID)
	slog.Info("[trip] repo.DeleteTrip: request", "url", url)

	req, err := http.NewRequestWithContext(ctx, http.MethodDelete, url, nil)
	if err != nil {
		return err
	}
	r.setWriteHeaders(req, token)
	req.Header.Set("Prefer", "return=minimal")

	resp, err := r.httpClient.Do(req)
	if err != nil {
		slog.Error("[trip] repo.DeleteTrip: http error", "err", err)
		return err
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(io.LimitReader(resp.Body, 4*1024))
	slog.Info("[trip] repo.DeleteTrip: response", "status", resp.StatusCode, "body", string(respBody))
	if resp.StatusCode != http.StatusNoContent {
		slog.Error("[trip] repo.DeleteTrip: unexpected status",
			"status", resp.StatusCode,
			"tripID", tripID,
			"body", string(respBody),
		)
		return fmt.Errorf("deleteTrip: status %d", resp.StatusCode)
	}
	slog.Info("[trip] repo.DeleteTrip: success", "tripID", tripID)
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

func newUUID() (string, error) {
	var b [16]byte
	if _, err := crand.Read(b[:]); err != nil {
		return "", err
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:]), nil
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
