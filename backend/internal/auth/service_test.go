package auth_test

import (
	"context"
	"testing"

	"doh/backend/internal/auth"
	"doh/backend/testutil"
)

func setupService(t *testing.T) (*auth.Service, *testutil.FakeSupabase) {
	t.Helper()
	fs := testutil.NewFakeSupabase(t)
	ft := testutil.NewFakeTurnstile(t)

	old := *auth.ExportedTurnstileURL
	*auth.ExportedTurnstileURL = ft.URL
	t.Cleanup(func() { *auth.ExportedTurnstileURL = old })

	svc := auth.NewServiceWithClient(fs.Server.URL, "fake-anon-key", "fake-key", fs.Server.Client())
	return svc, fs
}

func TestService_Signup_Success(t *testing.T) {
	svc, _ := setupService(t)
	resp, err := svc.Signup(context.Background(), auth.SignupRequest{
		Email: "test@example.com", Password: "Test1234!", Nickname: "테스터", CaptchaToken: "test",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.AccessToken == "" {
		t.Error("expected access_token")
	}
	if resp.User.Email != "test@example.com" {
		t.Errorf("email=%q want test@example.com", resp.User.Email)
	}
}

func TestService_Signup_DuplicateEmail(t *testing.T) {
	svc, fs := setupService(t)
	fs.SignupError = "user_already_exists"
	_, err := svc.Signup(context.Background(), auth.SignupRequest{
		Email: "test@example.com", Password: "Test1234!", Nickname: "테스터", CaptchaToken: "test",
	})
	if err != auth.ErrEmailExists {
		t.Errorf("err=%v want ErrEmailExists", err)
	}
}

func TestService_Signup_MissingCaptcha(t *testing.T) {
	svc, _ := setupService(t)
	_, err := svc.Signup(context.Background(), auth.SignupRequest{
		Email: "a@b.com", Password: "Test1234!", Nickname: "테스터",
	})
	if _, ok := err.(*auth.ValidationError); !ok {
		t.Errorf("expected *auth.ValidationError, got %T: %v", err, err)
	}
}

func TestService_Login_Success(t *testing.T) {
	svc, _ := setupService(t)
	resp, err := svc.Login(context.Background(), auth.LoginRequest{
		Email: "test@example.com", Password: "Test1234!", CaptchaToken: "test",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if resp.AccessToken == "" {
		t.Error("expected access_token")
	}
}

func TestService_Login_WrongPassword(t *testing.T) {
	svc, fs := setupService(t)
	fs.LoginError = true
	_, err := svc.Login(context.Background(), auth.LoginRequest{
		Email: "test@example.com", Password: "Wrong1234!", CaptchaToken: "test",
	})
	if err != auth.ErrAuthFailed {
		t.Errorf("err=%v want ErrAuthFailed", err)
	}
}

func TestService_Me(t *testing.T) {
	svc, _ := setupService(t)
	user, err := svc.Me(context.Background(), "fake-user-id", "test@example.com", "fake-token")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if user.Email != "test@example.com" {
		t.Errorf("email=%q want test@example.com", user.Email)
	}
}
