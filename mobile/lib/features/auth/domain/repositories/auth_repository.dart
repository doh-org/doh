import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  Future<User> signUp(String email, String password, String nickname);
  Future<void> logout();
  Future<User?> getCurrentUser();
}
