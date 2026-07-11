import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

part 'api_client.g.dart';

const String _refreshPath = '/api/v1/auth/refresh';

// 테스트에서 로컬 fake 서버로 교체 가능한 seam
final Provider<String> apiBaseUrlProvider =
    Provider<String>((_) => AppConfig.apiBaseUrl);

@riverpod
Dio apiClient(Ref ref) {
  final TokenStorage tokenStorage = ref.read(tokenStorageProvider);
  final String baseUrl = ref.read(apiBaseUrlProvider);
  final Dio dio = Dio(BaseOptions(baseUrl: baseUrl));
  // 재발급·재시도 전용 클라이언트: 인터셉터 없음 → 재귀 401 방지
  final Dio bareDio = Dio(BaseOptions(baseUrl: baseUrl));

  // QueuedInterceptorsWrapper: 동시 401 처리를 직렬화해
  // refresh rotation(일회용 토큰)이 경쟁으로 깨지는 것을 방지
  dio.interceptors.add(
    QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        final String? token = await tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final int? statusCode = error.response?.statusCode;

        // access 만료(401) → refresh로 재발급 후 원요청 재시도
        if (statusCode == 401 &&
            error.requestOptions.path != _refreshPath) {
          final Response<dynamic>? retried =
              await _tryRefreshAndRetry(ref, tokenStorage, bareDio, error);
          if (retried != null) {
            handler.resolve(retried);
            return;
          }
        }

        handler.reject(_mapError(error));
      },
    ),
  );

  return dio;
}

// 401 요청을 재발급 후 재시도한다. 성공 시 응답, 실패 시 null(호출부가 reject).
Future<Response<dynamic>?> _tryRefreshAndRetry(
  Ref ref,
  TokenStorage storage,
  Dio bareDio,
  DioException error,
) async {
  // 앞선 요청이 이미 재발급했다면(저장된 토큰 ≠ 실패 요청의 토큰) 재발급 생략
  final String used = (error.requestOptions.headers['Authorization'] as String?)
          ?.replaceFirst('Bearer ', '') ??
      '';
  String? access = await storage.getAccessToken();

  if (access == null || access == used) {
    final String? refresh = await storage.getRefreshToken();
    if (refresh == null) return null; // 세션 없음 → 그대로 401

    try {
      final Response<dynamic> res = await bareDio.post<dynamic>(
        _refreshPath,
        data: {'refresh_token': refresh},
      );
      final Map<String, dynamic> body = res.data as Map<String, dynamic>;
      access = body['access_token'] as String;
      // rotation: 새 refresh를 반드시 교체 저장
      await storage.saveTokens(access, body['refresh_token'] as String);
    } catch (_) {
      // refresh 만료·무효 → 세션 정리 + 로그인으로 (라우터 redirect)
      await storage.clear();
      ref.read(authNotifierProvider.notifier).sessionExpired();
      return null;
    }
  }

  try {
    final RequestOptions opts = error.requestOptions;
    opts.headers['Authorization'] = 'Bearer $access';
    return await bareDio.fetch<dynamic>(opts); // 원요청 1회 재시도
  } on DioException {
    return null; // 재시도도 실패 → 원래 에러 매핑으로
  }
}

// Dio 에러 → 도메인 AppException 매핑
DioException _mapError(DioException error) {
  final int? statusCode = error.response?.statusCode;
  final dynamic data = error.response?.data;
  final String? message =
      data is Map<String, dynamic> ? data['error'] as String? : null;

  final AppException appException;
  switch (statusCode) {
    case 400:
      appException = ValidationException(message ?? '입력을 확인해주세요.');
    case 401:
      appException = const AuthException();
    case 404:
      appException = const NotFoundException();
    case 409:
      appException = const ConflictException();
    case 429:
      // rate limit 초과 → 서버 안내 문구 그대로 (재전송 제한 등)
      appException = RateLimitException(message ?? '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.');
    default:
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionTimeout) {
        appException = const NetworkException();
      } else {
        appException = const ServerException();
      }
  }

  return DioException(
    requestOptions: error.requestOptions,
    response: error.response,
    error: appException,
  );
}
