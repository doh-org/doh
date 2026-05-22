package domain

type ErrorResponse struct {
	Message string `json:"error"`
}

type SuccessResponse struct {
	Data any `json:"data"`
}
