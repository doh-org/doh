import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<List<MarkerModel>> getMarkers(String tripId) async {
    final r = await _dio.get('/api/v1/trips/$tripId/markers');
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

  // categories: 백엔드 라우트 없음 → Supabase 직접
  Future<List<CategoryModel>> getCategories(String tripId) async {
    final data = await Supabase.instance.client
        .from('categories')
        .select()
        .eq('trip_id', tripId);
    return (data as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
