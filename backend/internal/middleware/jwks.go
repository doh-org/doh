package middleware

import (
	"context"
	"crypto/ecdsa"
	"crypto/elliptic"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"math/big"
	"net/http"
	"time"
)

type jwksResponse struct {
	Keys []jwkKey `json:"keys"`
}

type jwkKey struct {
	Kty string `json:"kty"`
	Crv string `json:"crv"`
	Kid string `json:"kid"`
	X   string `json:"x"`
	Y   string `json:"y"`
}

// FetchPublicKeys fetches EC P-256 public keys from a JWKS endpoint.
// Returns a map of kid → *ecdsa.PublicKey.
func FetchPublicKeys(ctx context.Context, jwksURL string) (map[string]*ecdsa.PublicKey, error) {
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, jwksURL, nil)
	if err != nil {
		return nil, fmt.Errorf("jwks: build request: %w", err)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("jwks: fetch: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024))
	if err != nil {
		return nil, fmt.Errorf("jwks: read body: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("jwks: unexpected status %d", resp.StatusCode)
	}

	var set jwksResponse
	if err := json.Unmarshal(body, &set); err != nil {
		return nil, fmt.Errorf("jwks: parse: %w", err)
	}

	keys := make(map[string]*ecdsa.PublicKey)
	for _, k := range set.Keys {
		if k.Kty != "EC" || k.Crv != "P-256" {
			continue
		}
		pub, err := decodeECPublicKey(k)
		if err != nil {
			return nil, fmt.Errorf("jwks: decode key %q: %w", k.Kid, err)
		}
		keys[k.Kid] = pub
	}

	if len(keys) == 0 {
		return nil, fmt.Errorf("jwks: no EC P-256 keys found at %s", jwksURL)
	}
	return keys, nil
}

func decodeECPublicKey(k jwkKey) (*ecdsa.PublicKey, error) {
	xBytes, err := base64.RawURLEncoding.DecodeString(k.X)
	if err != nil {
		return nil, fmt.Errorf("decode x: %w", err)
	}
	yBytes, err := base64.RawURLEncoding.DecodeString(k.Y)
	if err != nil {
		return nil, fmt.Errorf("decode y: %w", err)
	}
	return &ecdsa.PublicKey{
		Curve: elliptic.P256(),
		X:     new(big.Int).SetBytes(xBytes),
		Y:     new(big.Int).SetBytes(yBytes),
	}, nil
}
