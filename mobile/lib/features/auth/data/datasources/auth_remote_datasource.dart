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

  // 비밀번호 재설정 코드 메일 발송 요청.
  // 사용자 열거 방지로 이메일 존재 여부와 무관하게 항상 200이 온다.
  Future<void> recover(String email) async {
    await _dio.post(
      '/api/v1/auth/recover',
      data: {'email': email},
    );
  }

  // 메일의 6자리 코드 검증 + 새 비밀번호 설정 (비밀번호 분실 플로우 전용).
  // 성공 시 204, 코드 불일치·만료·정책 위반은 400으로 온다.
  Future<void> verifyRecovery(
    String email,
    String code,
    String newPassword,
  ) async {
    await _dio.post(
      '/api/v1/auth/verify-recovery',
      data: {
        'email': email,
        'code': code,
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
