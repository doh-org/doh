import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> loginWithKakao();
  Future<User> loginWithEmail(String email, String password);
  Future<User> signUp(String email, String password, String nickname);
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<User?> getCurrentUser();
  Future<User> getMe();
}
