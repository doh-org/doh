import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/place.dart';

part 'place_search_datasource.g.dart';

@riverpod
PlaceSearchDatasource placeSearchDatasource(Ref ref) =>
    PlaceSearchDatasource(ref.watch(apiClientProvider));

// 통합 장소 검색(네이버+카카오 병합). 시크릿 보호를 위해 Go 프록시 경유(JWT).
class PlaceSearchDatasource {
  PlaceSearchDatasource(this._dio);

  final Dio _dio;

  // x=경도, y=위도 — 쌍으로만 전달. zoom(0~21)은 카카오 radius·size 티어 결정.
  Future<List<Place>> search(
    String query, {
    String? x,
    String? y,
    double? zoom,
  }) async {
    final Map<String, dynamic> params = {'q': query};
    if (x != null && y != null) {
      params['x'] = x;
      params['y'] = y;
    }
    if (zoom != null) params['zoom'] = zoom.toString();
    final r = await _dio.get(
      '/api/v1/places/search',
      queryParameters: params,
    );
    final List<dynamic> places =
        (r.data as Map<String, dynamic>)['places'] as List? ?? [];
    return places
        .map((e) => Place.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
