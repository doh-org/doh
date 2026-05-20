package auth

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

var turnstileURL    = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
var turnstileClient = &http.Client{Timeout: 5 * time.Second}

type turnstileResponse struct {
	Success    bool     `json:"success"`
	ErrorCodes []string `json:"error-codes"`
}

// verifyCaptcha는 Cloudflare Turnstile 토큰을 검증한다.
// 토큰은 Cloudflare 측에서 1회용으로 관리되므로 별도 idempotency_key 불필요.
func verifyCaptcha(secretKey, token string) error {
	form := url.Values{}
	form.Set("secret", secretKey)
	form.Set("response", token)

	resp, err := turnstileClient.PostForm(turnstileURL, form)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return err
	}

	var result turnstileResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return err
	}

	if !result.Success {
		return fmt.Errorf("captcha verification failed: %v", result.ErrorCodes)
	}
	return nil
}
