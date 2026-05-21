package auth

// handler_test.go(package auth_test)에서 turnstileURL을 교체할 수 있도록 포인터 노출.
var ExportedTurnstileURL = &turnstileURL
