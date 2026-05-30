package auth

import (
	"strings"
	"testing"
)

func TestValidateEmail(t *testing.T) {
	cases := []struct {
		name    string
		email   string
		wantErr bool
	}{
		{"valid", "test@example.com", false},
		{"valid 2-char TLD .io", "user@example.io", false},
		{"valid 6-char TLD .travel", "user@example.travel", false},
		{"no @", "notanemail", true},
		{"empty local part", "@example.com", true},
		{"no dot in domain", "user@localhost", true},
		{"1-char TLD", "user@example.c", true},
		{"multiple @", "a@b@c.com", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := validateEmail(tc.email)
			if (err != nil) != tc.wantErr {
				t.Errorf("validateEmail(%q) err=%v wantErr=%v", tc.email, err, tc.wantErr)
			}
		})
	}
}

func TestValidatePassword(t *testing.T) {
	cases := []struct {
		name     string
		password string
		wantErr  bool
		errMsg   string
	}{
		{"valid", "Test1234!", false, ""},
		{"too short", "Ab1", true, "비밀번호는 8자 이상이어야 합니다."},
		{"no uppercase", "test1234", true, "비밀번호에 대문자가 포함되어야 합니다."},
		{"no lowercase", "TEST1234", true, "비밀번호에 소문자가 포함되어야 합니다."},
		{"no digit", "TestPass", true, "비밀번호에 숫자가 포함되어야 합니다."},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := validatePassword(tc.password)
			if (err != nil) != tc.wantErr {
				t.Errorf("validatePassword(%q) err=%v wantErr=%v", tc.password, err, tc.wantErr)
			}
			if tc.wantErr && err != nil {
				ve, ok := err.(*ValidationError)
				if !ok {
					t.Errorf("expected *ValidationError, got %T", err)
				} else if ve.Message != tc.errMsg {
					t.Errorf("message=%q want=%q", ve.Message, tc.errMsg)
				}
			}
		})
	}
}

func TestValidateNickname(t *testing.T) {
	cases := []struct {
		name     string
		nickname string
		wantErr  bool
	}{
		{"valid", "테스터", false},
		{"empty", "", true},
		{"50 chars", strings.Repeat("가", 50), false},
		{"51 chars", strings.Repeat("가", 51), true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := validateNickname(tc.nickname)
			if (err != nil) != tc.wantErr {
				t.Errorf("validateNickname(%q) err=%v wantErr=%v", tc.nickname, err, tc.wantErr)
			}
		})
	}
}

func TestSanitizeNickname(t *testing.T) {
	cases := []struct {
		input string
		want  string
	}{
		{"테스터", "테스터"},
		{"<script>", "script"},
		{"a&b", "ab"},
		{`"quoted"`, "quoted"},
		{"  spaces  ", "spaces"},
	}
	for _, tc := range cases {
		t.Run(tc.input, func(t *testing.T) {
			got := sanitizeNickname(tc.input)
			if got != tc.want {
				t.Errorf("sanitizeNickname(%q)=%q want=%q", tc.input, got, tc.want)
			}
		})
	}
}
