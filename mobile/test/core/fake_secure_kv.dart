import 'package:doh/core/storage/secure_kv.dart';

// 인메모리 fake. 테스트마다 새로 만들어 상태 격리.
class FakeSecureKv implements SecureKv {
  final Map<String, String> store = {};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> deleteAll() async => store.clear();
}
