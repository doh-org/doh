import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/entities/naver_place.dart';

part 'naver_local_search_datasource.g.dart';

@riverpod
NaverLocalSearchDatasource naverLocalSearchDatasource(Ref ref) =>
    NaverLocalSearchDatasource();

class NaverLocalSearchDatasource {
  NaverLocalSearchDatasource() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://openapi.naver.com',
      headers: {
        'X-Naver-Client-Id': AppConfig.naverSearchClientId,
        'X-Naver-Client-Secret': AppConfig.naverSearchClientSecret,
      },
    ));
  }

  late final Dio _dio;

  Future<List<NaverPlace>> search(String query) async {
    final r = await _dio.get(
      '/v1/search/local.json',
      queryParameters: {'query': query, 'display': 15},
    );
    final items = (r.data as Map<String, dynamic>)['items'] as List? ?? [];
    return items
        .map((e) => NaverPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
