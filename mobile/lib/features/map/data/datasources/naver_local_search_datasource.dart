import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/naver_place.dart';

part 'naver_local_search_datasource.g.dart';

@riverpod
NaverLocalSearchDatasource naverLocalSearchDatasource(Ref ref) =>
    NaverLocalSearchDatasource(ref.watch(apiClientProvider));

// 장소 검색. 시크릿 보호를 위해 네이버 직접 호출 대신 Go 프록시 경유(JWT).
class NaverLocalSearchDatasource {
  NaverLocalSearchDatasource(this._dio);

  final Dio _dio;

  Future<List<NaverPlace>> search(String query, {String? coordinate}) async {
    final Map<String, dynamic> params = {'q': query};
    if (coordinate != null) params['coordinate'] = coordinate;
    final r = await _dio.get(
      '/api/v1/places/search',
      queryParameters: params,
    );
    final items = (r.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .map((e) => NaverPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
