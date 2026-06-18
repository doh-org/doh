import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_stop.freezed.dart';

/// 구간 이동수단. 백엔드 transport_to_next 값과 1:1.
enum TransportMode { car, foot, publictransit, bicycle }

/// Day stop 목록 정렬 기준.
enum RouteSort { visitTime, order }

extension RouteSortQuery on RouteSort {
  String get query => this == RouteSort.visitTime ? 'visit_time' : 'order';
}

/// 특정 Day의 stop 한 건 = marker_days 한 행.
/// 구간(이동수단·거리·시간)은 다음 stop까지(`_toNext`); 마지막 stop은 null.
@freezed
abstract class RouteStop with _$RouteStop {
  const factory RouteStop({
    required String markerId,
    required String name,
    required double latitude,
    required double longitude,
    String? categoryId,
    required int order,
    String? visitTime, // "HH:MM:SS" 또는 null
    TransportMode? transportToNext, // null = 미설정
    double? distanceToNext,
    int? durationToNext,
  }) = _RouteStop;
}
