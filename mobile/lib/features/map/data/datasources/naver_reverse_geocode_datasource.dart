import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';

part 'naver_reverse_geocode_datasource.g.dart';

@riverpod
NaverReverseGeocodeDatasource naverReverseGeocodeDatasource(Ref ref) =>
    NaverReverseGeocodeDatasource(ref.watch(apiClientProvider));

// 좌표→주소 변환. 시크릿 보호를 위해 NCP 직접 호출 대신 Go 프록시 경유(JWT).
class NaverReverseGeocodeDatasource {
  NaverReverseGeocodeDatasource(this._dio);

  final Dio _dio;

  Future<({String? address, String? area})> reverseGeocodeDetails(
      double lat, double lng) async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/api/v1/geocode/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final List<dynamic>? results =
          (r.data as Map<String, dynamic>?)?['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        return (address: null, area: null);
      }
      final Map<String, dynamic> first = results.first as Map<String, dynamic>;
      return (address: _parseAddress(first), area: _parseArea(first));
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[ReverseGeocode] failed: $e');
        return true;
      }());
      return (address: null, area: null);
    }
  }

  Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final Response<dynamic> r = await _dio.get<dynamic>(
        '/api/v1/geocode/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      final List<dynamic>? results =
          (r.data as Map<String, dynamic>?)?['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      return _parseAddress(results.first as Map<String, dynamic>);
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[ReverseGeocode] failed: $e');
        return true;
      }());
      return null;
    }
  }

  String? _parseArea(Map<String, dynamic> result) {
    final Map<String, dynamic>? region =
        result['region'] as Map<String, dynamic>?;
    if (region == null) return null;
    String a(String key) =>
        (region[key] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final String a3 = a('area3');
    if (a3.isNotEmpty) return a3;
    final String a2 = a('area2');
    return a2.isNotEmpty ? a2 : null;
  }

  String? _parseAddress(Map<String, dynamic> result) {
    final Map<String, dynamic>? region =
        result['region'] as Map<String, dynamic>?;
    final Map<String, dynamic>? land =
        result['land'] as Map<String, dynamic>?;
    if (region == null) return null;

    String area(String key) =>
        (region[key] as Map<String, dynamic>?)?['name'] as String? ?? '';

    final List<String> parts = [
      area('area1'),
      area('area2'),
    ].where((s) => s.isNotEmpty).toList();

    final String name = result['name'] as String? ?? '';
    if (name == 'roadaddr' && land != null) {
      final String road = land['name'] as String? ?? '';
      final String num1 = land['number1'] as String? ?? '';
      final String num2 = land['number2'] as String? ?? '';
      if (road.isNotEmpty) parts.add(road);
      if (num1.isNotEmpty) {
        parts.add(num2.isNotEmpty ? '$num1-$num2' : num1);
      }
    } else {
      final String area3 = area('area3');
      if (area3.isNotEmpty) parts.add(area3);
      if (land != null) {
        final String num1 = land['number1'] as String? ?? '';
        final String num2 = land['number2'] as String? ?? '';
        if (num1.isNotEmpty) {
          parts.add(num2.isNotEmpty ? '$num1-$num2' : num1);
        }
      }
    }

    return parts.isEmpty ? null : parts.join(' ');
  }
}
