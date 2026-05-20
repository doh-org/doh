package domain

type DirectionRequest struct {
	Origin      LatLng `json:"origin"`
	Destination LatLng `json:"destination"`
	Mode        string `json:"mode"` // car, foot, publictransit, bicycle
}

type LatLng struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

type DirectionResponse struct {
	Routes []DirectionRoute `json:"routes"`
}

type DirectionRoute struct {
	Distance int      `json:"distance"` // meters
	Duration int      `json:"duration"` // seconds
	Points   []LatLng `json:"points"`
}
