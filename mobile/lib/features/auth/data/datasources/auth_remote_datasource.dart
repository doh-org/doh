import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

part 'auth_remote_datasource.g.dart';

@riverpod
AuthRemoteDatasource authRemoteDatasource(Ref ref) =>
    AuthRemoteDatasource(ref.watch(apiClientProvider));

class AuthRemoteDatasource {
  const AuthRemoteDatasource(this._dio);
  final Dio _dio;

  Future<AuthResponseModel> loginWithEmail(
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      '/api/v1/auth/login',
      data: {
        'email': email,
        'password': password,
        'captcha_token': 'test',
      },
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthResponseModel> signUp(
    String email,
    String password,
    String nickname,
  ) async {
    final response = await _dio.post(
      '/api/v1/auth/signup',
      data: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'captcha_token': 'test',
      },
    );
    return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _dio.post('/api/v1/auth/logout');
  }

  // 회원 탈퇴. 백엔드가 소유 trip 선삭제 후 계정을 영구 삭제한다.
  Future<void> deleteMe() async {
    await _dio.delete('/api/v1/auth/me');
  }

  // 비밀번호 변경. 백엔드가 현재 비밀번호 재인증 후 변경한다.
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _dio.put(
      '/api/v1/auth/password',
      data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  Future<UserResponseModel> getMe() async {
    final response = await _dio.get('/api/v1/auth/me');
    return UserResponseModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> loginWithKakao() {
    throw UnimplementedError('카카오 로그인 미구현');
  }
}
