package usecase

import (
	"context"

	"doh/backend/domain"
)

type categoryUsecase struct {
	categoryRepo domain.CategoryRepository
	tripRepo     domain.TripRepository
}

func NewCategoryUsecase(cr domain.CategoryRepository, tr domain.TripRepository) domain.CategoryUsecase {
	return &categoryUsecase{categoryRepo: cr, tripRepo: tr}
}

func (u *categoryUsecase) GetCategories(ctx context.Context, token, tripID string) ([]domain.Category, error) {
	if _, err := u.tripRepo.GetTrip(ctx, token, tripID); err != nil {
		return nil, err
	}
	return u.categoryRepo.GetCategories(ctx, token, tripID)
}
