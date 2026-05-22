package testutil

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type TestKeys struct {
	PublicKeys map[string]*ecdsa.PublicKey
	PrivateKey *ecdsa.PrivateKey
	KID        string
}

func NewTestKeys(t *testing.T) *TestKeys {
	t.Helper()
	priv, err := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	if err != nil {
		t.Fatalf("generate test key: %v", err)
	}
	kid := "test-kid"
	return &TestKeys{
		PublicKeys: map[string]*ecdsa.PublicKey{kid: &priv.PublicKey},
		PrivateKey: priv,
		KID:        kid,
	}
}

// Sign은 ES256 JWT를 생성해 반환한다.
func (k *TestKeys) Sign(subject, email, issuer string, exp time.Time) string {
	token := jwt.NewWithClaims(jwt.SigningMethodES256, jwt.MapClaims{
		"sub":   subject,
		"email": email,
		"iss":   issuer,
		"exp":   exp.Unix(),
		"iat":   time.Now().Unix(),
	})
	token.Header["kid"] = k.KID
	signed, err := token.SignedString(k.PrivateKey)
	if err != nil {
		panic(err)
	}
	return signed
}
