import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doh/core/storage/token_storage.dart';
import 'package:doh/features/auth/domain/entities/user.dart';

import 'fake_secure_kv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  User user() => User(
        id: 'u1',
        email: 'a@b.com',
        nickname: '테스터',
        createdAt: DateTime(2026, 1, 1),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save → getAccessToken/getRefreshToken/getUser 왕복', () async {
    final TokenStorage storage = TokenStorage(FakeSecureKv());
    await storage.save('acc-1', 'ref-1', user());

    expect(await storage.getAccessToken(), 'acc-1');
    expect(await storage.getRefreshToken(), 'ref-1');
    expect((await storage.getUser())!.nickname, '테스터');
  });

  test('saveTokens는 토큰만 교체(rotation)', () async {
    final TokenStorage storage = TokenStorage(FakeSecureKv());
    await storage.save('acc-1', 'ref-1', user());
    await storage.saveTokens('acc-2', 'ref-2');

    expect(await storage.getAccessToken(), 'acc-2');
    expect(await storage.getRefreshToken(), 'ref-2');
    expect((await storage.getUser())!.id, 'u1'); // 유저 정보 유지
  });

  test('clear 후 전부 null', () async {
    final TokenStorage storage = TokenStorage(FakeSecureKv());
    await storage.save('acc-1', 'ref-1', user());
    await storage.clear();

    expect(await storage.getAccessToken(), isNull);
    expect(await storage.getRefreshToken(), isNull);
    expect(await storage.getUser(), isNull);
  });

  test('구버전 prefs 평문 토큰 → secure로 1회 이전 후 prefs 제거', () async {
    SharedPreferences.setMockInitialValues({
      'access_token': 'legacy-acc',
      'refresh_token': 'legacy-ref',
      'user_id': 'u1',
      'user_email': 'a@b.com',
      'user_nickname': '테스터',
      'user_created_at': '2026-01-01T00:00:00.000',
    });
    final FakeSecureKv kv = FakeSecureKv();
    final TokenStorage storage = TokenStorage(kv);

    expect(await storage.getAccessToken(), 'legacy-acc'); // 이전됨
    expect(await storage.getRefreshToken(), 'legacy-ref');
    expect(kv.store['access_token'], 'legacy-acc');

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('access_token'), isNull); // 평문 흔적 제거
  });
}
