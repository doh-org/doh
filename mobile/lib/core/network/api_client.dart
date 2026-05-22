import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          options.headers['Authorization'] = 'Bearer ${session.accessToken}';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        switch (error.response?.statusCode) {
          case 401:
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: const UnauthorizedException(),
            ));
          case 404:
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: const NotFoundException(),
            ));
          default:
            handler.reject(DioException(
              requestOptions: error.requestOptions,
              error: const ServerException(),
            ));
        }
      },
    ),
  );

  return dio;
}
