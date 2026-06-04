import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../storage/token_storage.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final tokenStorage = ref.read(tokenStorageProvider);
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        final message =
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
          case 422:
            appException = const CaptchaException();
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

        handler.reject(DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          error: appException,
        ));
      },
    ),
  );

  return dio;
}
