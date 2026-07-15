// 비밀번호 정책. 백엔드 validatePassword(auth_usecase.go)와 같은 규칙을 유지한다.
// - 8자 이상
// - 영문 대문자·소문자·숫자 각 1개 이상
// - 허용 문자: 인쇄 가능한 ASCII(33~126) = 영문·숫자·특수문자 (한글·공백 불가)

final RegExp _allowedChars = RegExp(r'^[\x21-\x7E]+$'); // ASCII 33~126만

bool isValidPassword(String pw) =>
    pw.length >= 8 &&
    _allowedChars.hasMatch(pw) &&
    pw.contains(RegExp(r'[A-Z]')) &&
    pw.contains(RegExp(r'[a-z]')) &&
    pw.contains(RegExp(r'[0-9]'));

// 정책 위반 시 공통 안내 문구 (두 페이지에서 같은 문구 사용)
const String passwordPolicyMessage =
    '비밀번호는 8자 이상, 영문 대·소문자·숫자를 포함하고 영문·숫자·특수문자만 사용할 수 있습니다.';
