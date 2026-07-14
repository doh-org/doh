import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> loginWithKakao();
  Future<User> loginWithEmail(String email, String password);
  // 1단계: 이메일로 확인 코드 발송 요청. 아직 로그인되지 않는다.
  Future<void> requestSignupCode(String email);
  // 2단계: 확인 코드 검증 → 가입 세션 토큰 반환(메모리 보관, 아직 로그인 아님).
  Future<String> verifySignup(String email, String code);
  // 3단계: 가입 세션으로 비번·닉네임 설정 → 세션 저장 후 로그인된 User 반환.
  Future<User> completeSignup(String accessToken, String password, String nickname);
  // 확인 코드 재발송.
  Future<void> resendSignup(String email);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> requestRecovery(String email);
  Future<String> verifyRecoveryCode(String email, String code);
  Future<void> resetRecoveryPassword(String accessToken, String newPassword);
  Future<User?> getCurrentUser();
  Future<User> getMe();
}
