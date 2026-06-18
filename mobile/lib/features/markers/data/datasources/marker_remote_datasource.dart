import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/network/api_client.dart';
import '../models/category_model.dart';
import '../models/marker_model.dart';

part 'marker_remote_datasource.g.dart';

@riverpod
MarkerRemoteDatasource markerRemoteDatasource(Ref ref) =>
    MarkerRemoteDatasource(ref.watch(apiClientProvider));

class MarkerRemoteDatasource {
  const MarkerRemoteDatasource(this._dio);
  final Dio _dio;

  /// GET /markers/:day — day=0=미정, day>=1=해당 day stop.
  Future<List<MarkerModel>> getMarkersByDay(
    String tripId,
    int day, {
    String sort = 'visit_time',
  }) async {
    final r = await _dio.get(
      '/api/v1/trips/$tripId/markers/$day',
      queryParameters: {'sort': sort},
    );
    return (r.data as List)
        .map((e) => MarkerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MarkerModel> createMarker(
      String tripId, Map<String, dynamic> body) async {
    final r =
        await _dio.post('/api/v1/trips/$tripId/markers/add', data: body);
    return MarkerModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<MarkerModel> updateMarker(
      String tripId, String markerId, Map<String, dynamic> body) async {
    final r = await _dio.patch(
        '/api/v1/trips/$tripId/markers/$markerId',
        data: body);
    return MarkerModel.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deleteMarker(String tripId, String markerId) async {
    await _dio.delete('/api/v1/trips/$tripId/markers/$markerId');
  }

  Future<List<CategoryModel>> getCategories(String tripId) async {
    final r = await _dio.get('/api/v1/trips/$tripId/categories');
    return (r.data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
