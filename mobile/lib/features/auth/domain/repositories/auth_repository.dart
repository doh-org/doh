import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User> loginWithKakao();
  Future<void> logout();
  Future<User?> getCurrentUser();
}
