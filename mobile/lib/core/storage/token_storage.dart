import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/entities/user.dart';

part 'token_storage.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => const TokenStorage();

class TokenStorage {
  const TokenStorage();

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userEmailKey = 'user_email';
  static const _userNicknameKey = 'user_nickname';
  static const _userCreatedAtKey = 'user_created_at';

  Future<void> save(
    String accessToken,
    String refreshToken,
    User user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setString(_userIdKey, user.id);
    await prefs.setString(_userEmailKey, user.email);
    await prefs.setString(_userNicknameKey, user.nickname);
    await prefs.setString(_userCreatedAtKey, user.createdAt.toIso8601String());
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_userIdKey);
    final email = prefs.getString(_userEmailKey);
    final nickname = prefs.getString(_userNicknameKey);
    final createdAtStr = prefs.getString(_userCreatedAtKey);
    if (id == null || email == null || nickname == null || createdAtStr == null) {
      return null;
    }
    return User(
      id: id,
      email: email,
      nickname: nickname,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNicknameKey);
    await prefs.remove(_userCreatedAtKey);
  }
}
