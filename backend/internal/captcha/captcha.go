package captcha

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

// Endpoint는 Turnstile 검증 URL. 테스트에서 fake로 교체 가능한 seam.
var Endpoint = "https://challenges.cloudflare.com/turnstile/v0/siteverify"
var client   = &http.Client{Timeout: 5 * time.Second}

type response struct {
	Success    bool     `json:"success"`
	ErrorCodes []string `json:"error-codes"`
}

func Verify(secretKey, token string) error {
	form := url.Values{}
	form.Set("secret", secretKey)
	form.Set("response", token)

	resp, err := client.PostForm(Endpoint, form)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if err != nil {
		return err
	}

	var result response
	if err := json.Unmarshal(body, &result); err != nil {
		return err
	}

	if !result.Success {
		return fmt.Errorf("captcha verification failed: %v", result.ErrorCodes)
	}
	return nil
}
