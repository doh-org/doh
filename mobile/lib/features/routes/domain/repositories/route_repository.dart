import '../entities/route_stop.dart';

abstract interface class RouteRepository {
  /// 선택 Day의 stop 목록.
  Future<List<RouteStop>> getDayStops(
    String tripId,
    int day, {
    required RouteSort sort,
  });

  /// stop 부분 수정. 3상태: 미전달=유지 / clear=해제(null) / 값=설정.
  Future<RouteStop> updateStop(
    String tripId,
    int day,
    String markerId, {
    String? visitTime,
    bool clearVisitTime,
    TransportMode? transport,
    bool clearTransport,
  });

  /// Day 내 마커 순서 변경. 반환=재인덱싱된 개수.
  Future<int> reorder(String tripId, int day, List<String> markerIds);
}
