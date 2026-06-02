package repository

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"sort"
	"time"

	"doh/backend/domain"
)

var defaultCategoryOrder = map[string]int{
	"식당": 0, "카페": 1, "관광": 2, "숙소": 3, "기타": 4,
}

type categoryRepository struct {
	supabaseURL     string
	supabaseAnonKey string
	httpClient      *http.Client
}

func NewCategoryRepository(supabaseURL, anonKey string, client *http.Client) domain.CategoryRepository {
	if client == nil {
		client = &http.Client{Timeout: 10 * time.Second}
	}
	return &categoryRepository{supabaseURL: supabaseURL, supabaseAnonKey: anonKey, httpClient: client}
}

func (r *categoryRepository) GetCategories(ctx context.Context, token, tripID string) ([]domain.Category, error) {
	url := fmt.Sprintf("%s/rest/v1/categories?trip_id=eq.%s&select=id,trip_id,name,color,created_at", r.supabaseURL, tripID)

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

	b, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("getCategories: status %d", resp.StatusCode)
	}

	var categories []domain.Category
	if err := json.Unmarshal(b, &categories); err != nil {
		return nil, err
	}

	sort.SliceStable(categories, func(i, j int) bool {
		oi, okI := defaultCategoryOrder[categories[i].Name]
		oj, okJ := defaultCategoryOrder[categories[j].Name]
		if okI && okJ {
			return oi < oj
		}
		if okI {
			return true
		}
		if okJ {
			return false
		}
		return categories[i].CreatedAt.Before(categories[j].CreatedAt)
	})

	return categories, nil
}
