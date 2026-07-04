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

  @override
  Future<User> signUp(String email, String password, String nickname) async {
    try {
      final response = await _datasource.signUp(email, password, nickname);
      final user = response.user.toEntity();
      await _tokenStorage.save(response.accessToken, response.refreshToken, user);
      return user;
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
