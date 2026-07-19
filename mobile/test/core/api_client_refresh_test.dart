import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:doh/core/errors/app_exception.dart';
import 'package:doh/core/network/api_client.dart';
import 'package:doh/core/storage/token_storage.dart';
import 'package:doh/features/auth/domain/entities/user.dart';
import 'package:doh/features/auth/presentation/providers/auth_provider.dart';

import 'fake_secure_kv.dart';

// 로컬 fake API 서버: /test는 새 access만 통과, /refresh는 rt-1만 성공.
class _FakeApi {
  _FakeApi(this.server) {
    server.listen(_handle);
  }
  final HttpServer server;
  int refreshCalls = 0;

  static const String validAccess = 'new-access';
  static const String validRefresh = 'rt-1';

  String get baseUrl => 'http://127.0.0.1:${server.port}';

  Future<void> _handle(HttpRequest req) async {
    if (req.uri.path == '/api/v1/auth/refresh') {
      refreshCalls++;
      final String body = await utf8.decoder.bind(req).join();
      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;
      if (data['refresh_token'] == validRefresh) {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'access_token': validAccess,
            'refresh_token': 'rt-2', // rotation
            'user': {'id': 'u1'},
          }));
      } else {
        req.response
          ..statusCode = 401
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'error': '재로그인이 필요합니다.'}));
      }
      await req.response.close();
      return;
    }

    // 보호 리소스: 새 access만 200
    final String auth = req.headers.value('authorization') ?? '';
    if (auth == 'Bearer $validAccess') {
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true}));
    } else {
      req.response
        ..statusCode = 401
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': '로그인이 필요합니다.'}));
    }
    await req.response.close();
  }
}

void main() {
  // 주의: TestWidgetsFlutterBinding을 초기화하면 모든 HTTP가 400으로 mocking -> 로컬 fake 서버 테스트가 불가능 -> 이 파일은 바인딩 없이 실행
  late _FakeApi api;
  late TokenStorage storage;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    api = _FakeApi(await HttpServer.bind(InternetAddress.loopbackIPv4, 0));
    storage = TokenStorage(FakeSecureKv());
    container = ProviderContainer(overrides: [
      apiBaseUrlProvider.overrideWithValue(api.baseUrl),
      tokenStorageProvider.overrideWithValue(storage),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await api.server.close(force: true);
  });

  Future<void> seedSession({String refresh = _FakeApi.validRefresh}) =>
      storage.save(
        'expired-access',
        refresh,
        User(
          id: 'u1',
          email: 'a@b.com',
          nickname: '테스터',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

  test('401 → refresh → 원요청 자동 재시도 성공', () async {
    await seedSession();
    final Dio dio = container.read(apiClientProvider);

    final Response<dynamic> res = await dio.get<dynamic>('/api/v1/test');

    expect(res.statusCode, 200);
    expect(api.refreshCalls, 1);
    expect(await storage.getAccessToken(), _FakeApi.validAccess);
    expect(await storage.getRefreshToken(), 'rt-2'); // rotation 반영
  });

  test('refresh 실패(만료) → 세션 clear + AuthException', () async {
    await seedSession(refresh: 'rotated-away');
    final Dio dio = container.read(apiClientProvider);

    try {
      await dio.get<dynamic>('/api/v1/test');
      fail('expected DioException');
    } on DioException catch (e) {
      expect(e.error, isA<AuthException>());
    }
    expect(await storage.getAccessToken(), isNull); // 세션 정리됨
    // 라우터 redirect용 상태도 해제
    expect(container.read(authNotifierProvider).valueOrNull, isNull);
  });

  test('동시 401 여러 건 → refresh는 1회만(rotation 보호)', () async {
    await seedSession();
    final Dio dio = container.read(apiClientProvider);

    final List<Response<dynamic>> results = await Future.wait([
      dio.get<dynamic>('/api/v1/test'),
      dio.get<dynamic>('/api/v1/test'),
      dio.get<dynamic>('/api/v1/test'),
    ]);

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(api.refreshCalls, 1); // 두 번째부터는 갱신된 토큰으로 즉시 재시도
  });
}
