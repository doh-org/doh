import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/entities/user.dart';
import 'secure_kv.dart';

part 'token_storage.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage(const FlutterSecureKv());

// 토큰·유저 정보 저장소.
// 민감값(토큰·이메일)은 secure storage(암호화)에 보관하고,
// access 토큰은 요청마다 읽으므로 메모리에 캐시한다.
class TokenStorage {
  TokenStorage(this._kv);

  final SecureKv _kv;
  String? _accessCache; // 매 요청 비동기 읽기 방지용 캐시
  bool _migrated = false;

  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNicknameKey = 'user_nickname';
  static const String _userCreatedAtKey = 'user_created_at';

  static const List<String> _allKeys = [
    _accessKey,
    _refreshKey,
    _userIdKey,
    _userEmailKey,
    _userNicknameKey,
    _userCreatedAtKey,
  ];

  // 구버전(shared_preferences 평문 저장)에서 1회 이전.
  // secure가 비어 있고 prefs에 토큰이 남아 있으면 옮기고 prefs를 지운다.
  Future<void> _ensureMigrated() async {
    if (_migrated) return;
    _migrated = true;

    final String? already = await _kv.read(_accessKey);
    if (already != null) return; // 이미 secure에 있음 → 이전 불필요

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? legacyAccess = prefs.getString(_accessKey);
    if (legacyAccess == null) return; // 구버전 데이터 없음

    for (final String key in _allKeys) {
      final String? v = prefs.getString(key);
      if (v != null) await _kv.write(key, v);
      await prefs.remove(key); // 평문 흔적 제거
    }
  }

  Future<void> save(String accessToken, String refreshToken, User user) async {
    await _ensureMigrated();
    await saveTokens(accessToken, refreshToken);
    await updateUser(user);
  }

  // 재발급(rotation) 시 토큰만 교체
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _ensureMigrated();
    _accessCache = accessToken;
    await _kv.write(_accessKey, accessToken);
    await _kv.write(_refreshKey, refreshToken);
  }

  Future<String?> getAccessToken() async {
    if (_accessCache != null) return _accessCache;
    await _ensureMigrated();
    _accessCache = await _kv.read(_accessKey);
    return _accessCache;
  }

  Future<String?> getRefreshToken() async {
    await _ensureMigrated();
    return _kv.read(_refreshKey);
  }

  Future<User?> getUser() async {
    await _ensureMigrated();
    final String? id = await _kv.read(_userIdKey);
    final String? email = await _kv.read(_userEmailKey);
    final String? nickname = await _kv.read(_userNicknameKey);
    final String? createdAtStr = await _kv.read(_userCreatedAtKey);
    if (id == null ||
        email == null ||
        nickname == null ||
        createdAtStr == null) {
      return null;
    }
    return User(
      id: id,
      email: email,
      nickname: nickname,
      createdAt: DateTime.parse(createdAtStr),
    );
  }

  Future<void> updateUser(User user) async {
    await _ensureMigrated();
    await _kv.write(_userIdKey, user.id);
    await _kv.write(_userEmailKey, user.email);
    await _kv.write(_userNicknameKey, user.nickname);
    await _kv.write(_userCreatedAtKey, user.createdAt.toIso8601String());
  }

  Future<void> clear() async {
    _accessCache = null;
    await _kv.deleteAll();
  }
}
