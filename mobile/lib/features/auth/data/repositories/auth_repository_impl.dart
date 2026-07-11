import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

part 'auth_repository_impl.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepositoryImpl(
      ref.watch(authRemoteDatasourceProvider),
      ref.watch(tokenStorageProvider),
    );

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._datasource, this._tokenStorage);
  final AuthRemoteDatasource _datasource;
  final TokenStorage _tokenStorage;

  @override
  Future<User> loginWithKakao() async {
    final model = await _datasource.loginWithKakao();
    return model.toEntity();
  }

  @override
  Future<User> loginWithEmail(String email, String password) async {
    try {
      final response = await _datasource.loginWithEmail(email, password);
      final user = response.user.toEntity();
      await _tokenStorage.save(response.accessToken, response.refreshToken, user);
      return user;
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 1단계: 확인 코드 발송 요청. 로그인 전 플로우라 토큰 저장소는 건드리지 않는다.
  @override
  Future<void> requestSignupCode(String email) async {
    try {
      await _datasource.requestSignupCode(email);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 2단계: 코드 검증 → 가입 세션 토큰 반환(메모리 보관, 저장 안 함).
  @override
  Future<String> verifySignup(String email, String code) async {
    try {
      return await _datasource.verifySignup(email, code);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 3단계: 비번·닉네임 설정 → 세션 저장 후 로그인된 User 반환(로그인과 동일 처리).
  @override
  Future<User> completeSignup(
      String accessToken, String password, String nickname) async {
    try {
      final response =
          await _datasource.completeSignup(accessToken, password, nickname);
      final user = response.user.toEntity();
      await _tokenStorage.save(response.accessToken, response.refreshToken, user);
      return user;
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 확인 코드 재발송. 로그인 전 플로우.
  @override
  Future<void> resendSignup(String email) async {
    try {
      await _datasource.resendSignup(email);
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _datasource.logout();
    } catch (_) {}
    await _tokenStorage.clear();
  }

  // 탈퇴는 logout과 달리 서버 삭제가 성공해야만 세션을 지운다.
  // (실패를 삼키면 계정이 남은 채 로그아웃돼 사용자가 탈퇴로 오인)
  @override
  Future<void> deleteAccount() async {
    try {
      await _datasource.deleteMe();
    } on DioException catch (e) {
      final Object? error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
    await _tokenStorage.clear();
  }

  // 비밀번호 변경. 실패 시 서버 메시지(현재 비번 불일치 등)를 AppException으로 전달.
  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _datasource.changePassword(currentPassword, newPassword);
    } on DioException catch (e) {
      final Object? error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 비밀번호 재설정 코드 메일 발송. 로그인 전 플로우라 토큰 저장소는 건드리지 않는다.
  @override
  Future<void> requestRecovery(String email) async {
    try {
      await _datasource.recover(email);
    } on DioException catch (e) {
      final Object? error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // 코드 즉시 검증 → recovery 세션 토큰. 실패 시 서버 메시지(코드 불일치 등) 전달.
  @override
  Future<String> verifyRecoveryCode(String email, String code) async {
    try {
      return await _datasource.verifyRecoveryCode(email, code);
    } on DioException catch (e) {
      final Object? error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  // recovery 세션으로 새 비밀번호 설정. 실패 시 서버 메시지(세션 만료·정책 위반 등) 전달.
  @override
  Future<void> resetRecoveryPassword(
      String accessToken, String newPassword) async {
    try {
      await _datasource.resetRecoveryPassword(accessToken, newPassword);
    } on DioException catch (e) {
      final Object? error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }

  @override
  Future<User?> getCurrentUser() => _tokenStorage.getUser();

  @override
  Future<User> getMe() async {
    try {
      final model = await _datasource.getMe();
      final user = model.toEntity();
      await _tokenStorage.updateUser(user);
      return user;
    } on DioException catch (e) {
      final error = e.error;
      if (error is AppException) throw error;
      throw const NetworkException();
    }
  }
}
