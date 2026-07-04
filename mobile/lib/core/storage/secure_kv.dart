import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 보안 저장소 얇은 인터페이스.
// FlutterSecureStorage(플랫폼 채널)를 테스트에서 fake로 교체하기 위한 seam.
abstract interface class SecureKv {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> deleteAll();
}

class FlutterSecureKv implements SecureKv {
  const FlutterSecureKv();

  // Android Keystore 기반 암호화 저장 (v9+ 기본 암호화 사용)
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
