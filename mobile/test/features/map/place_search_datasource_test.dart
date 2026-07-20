import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/data/datasources/place_search_datasource.dart';
import 'package:doh/features/map/domain/entities/place.dart';

// 실제 네트워크 대신 요청을 가로채 고정 응답을 돌려주는 Dio.
// 보낸 쿼리 파라미터를 캡처해 계약(q·x·y·zoom)을 검증한다.
Dio _fakeDio(Map<String, dynamic> responseData, void Function(RequestOptions) onRequest) {
  final Dio dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
      onRequest(options);
      handler.resolve(Response<Map<String, dynamic>>(
        requestOptions: options,
        data: responseData,
        statusCode: 200,
      ));
    },
  ));
  return dio;
}

void main() {
  test('q·x·y·zoom 쿼리 전달, places 키 파싱', () async {
    RequestOptions? captured;
    final Dio dio = _fakeDio({
      'places': [
        {
          'provider': 'kakao',
          'title': 'A',
          'category': '음식점>카페',
          'address': '지번',
          'roadAddress': '도로명',
          'telephone': '',
          'link': '',
          'mapx': 127.0,
          'mapy': 37.0,
        }
      ]
    }, (RequestOptions o) => captured = o);

    final List<Place> results = await PlaceSearchDatasource(dio)
        .search('카페', x: '127.0', y: '37.0', zoom: 13.5);

    expect(captured!.path, '/api/v1/places/search');
    expect(captured!.queryParameters, {
      'q': '카페',
      'x': '127.0',
      'y': '37.0',
      'zoom': '13.5',
    });
    expect(results, hasLength(1));
    expect(results.first.title, 'A');
    expect(results.first.longitude, 127.0);
  });

  test('zoom null이면 쿼리에 미포함', () async {
    RequestOptions? captured;
    final Dio dio = _fakeDio({'places': []}, (RequestOptions o) => captured = o);

    await PlaceSearchDatasource(dio).search('역', x: '1', y: '2');

    expect(captured!.queryParameters, {'q': '역', 'x': '1', 'y': '2'});
  });

  test('좌표 없으면 q만 전송, 빈 응답은 빈 리스트', () async {
    RequestOptions? captured;
    final Dio dio = _fakeDio(<String, dynamic>{}, (RequestOptions o) => captured = o);

    final List<Place> results = await PlaceSearchDatasource(dio).search('역');

    expect(captured!.queryParameters, {'q': '역'});
    expect(results, isEmpty);
  });
}
