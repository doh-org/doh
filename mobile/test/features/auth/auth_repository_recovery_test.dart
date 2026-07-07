import 'package:dio/dio.dart';
import 'package:doh/core/errors/app_exception.dart';
import 'package:doh/core/storage/token_storage.dart';
import 'package:doh/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:doh/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/fake_secure_kv.dart';

/// recover / verifyRecovery 인자만 캡처하는 가짜 datasource (Dio 미사용).
/// throwError를 지정하면 해당 에러를 DioException에 담아 던진다.
class _FakeDatasource extends AuthRemoteDatasource {
  _FakeDatasource() : super(Dio());

  Object? throwError;
  String? lastRecoverEmail;
  (String, String, String)? lastVerifyArgs;

  DioException _wrap(Object error) => DioException(
        requestOptions: RequestOptions(path: '/'),
        error: error,
      );

  @override
  Future<void> recover(String email) async {
    if (throwError != null) throw _wrap(throwError!);
    lastRecoverEmail = email;
  }

  @override
  Future<void> verifyRecovery(
      String email, String code, String newPassword) async {
    if (throwError != null) throw _wrap(throwError!);
    lastVerifyArgs = (email, code, newPassword);
  }
}

void main() {
  late _FakeDatasource ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = _FakeDatasource();
    repo = AuthRepositoryImpl(ds, TokenStorage(FakeSecureKv()));
  });

  group('requestRecovery', () {
    test('이메일을 datasource로 전달', () async {
      await repo.requestRecovery('a@b.com');
      expect(ds.lastRecoverEmail, 'a@b.com');
    });

    test('서버 AppException은 그대로 던짐', () async {
      ds.throwError = const ValidationException('이메일 형식 오류');
      await expectLater(
        repo.requestRecovery('bad'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('그 외 Dio 에러는 NetworkException으로 변환', () async {
      ds.throwError = 'socket error';
      await expectLater(
        repo.requestRecovery('a@b.com'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('verifyRecovery', () {
    test('이메일·코드·새 비밀번호를 datasource로 전달', () async {
      await repo.verifyRecovery('a@b.com', '123456', 'NewPass123');
      expect(ds.lastVerifyArgs, ('a@b.com', '123456', 'NewPass123'));
    });

    test('코드 불일치 등 서버 AppException은 그대로 던짐', () async {
      ds.throwError = const ValidationException('코드가 올바르지 않습니다');
      await expectLater(
        repo.verifyRecovery('a@b.com', '000000', 'NewPass123'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('그 외 Dio 에러는 NetworkException으로 변환', () async {
      ds.throwError = 'socket error';
      await expectLater(
        repo.verifyRecovery('a@b.com', '123456', 'NewPass123'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
