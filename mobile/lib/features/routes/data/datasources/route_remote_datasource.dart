import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:doh/core/network/api_client.dart';
import '../models/route_stop_model.dart';

part 'route_remote_datasource.g.dart';

@riverpod
RouteRemoteDatasource routeRemoteDatasource(Ref ref) =>
    RouteRemoteDatasource(ref.watch(apiClientProvider));

/// Day stop API. 백엔드 marker_days 기반.
class RouteRemoteDatasource {
  const RouteRemoteDatasource(this._dio);
  final Dio _dio;

  /// GET /markers/:dayIndex — 정수 dayIndex = 그 Day stop 목록.
  Future<List<RouteStopModel>> getDayStops(
    String tripId,
    int day, {
    required String sort,
  }) async {
    final r = await _dio.get(
      '/api/v1/trips/$tripId/markers/$day',
      queryParameters: {'sort': sort},
    );
    return (r.data as List)
        .map((e) => RouteStopModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /days/:dayIndex/markers/:markerId — 방문시각·이동수단 부분 수정.
  Future<RouteStopModel> updateStop(
    String tripId,
    int day,
    String markerId,
    Map<String, dynamic> body,
  ) async {
    final r = await _dio.patch(
      '/api/v1/trips/$tripId/days/$day/markers/$markerId',
      data: body,
    );
    return RouteStopModel.fromJson(r.data as Map<String, dynamic>);
  }

  /// PATCH /days/:dayIndex/reorder — 순서대로 marker_id 배열 전달.
  Future<int> reorder(String tripId, int day, List<String> markerIds) async {
    final r = await _dio.patch(
      '/api/v1/trips/$tripId/days/$day/reorder',
      data: {'marker_ids': markerIds},
    );
    return (r.data as Map<String, dynamic>)['reordered'] as int;
  }
}
