import 'package:doh/features/markers/domain/entities/marker.dart';
import 'package:doh/features/markers/presentation/providers/marker_provider.dart';
import 'package:doh/features/routes/data/repositories/route_repository_impl.dart';
import 'package:doh/features/routes/domain/entities/route_stop.dart';
import 'package:doh/features/routes/domain/repositories/route_repository.dart';
import 'package:doh/features/routes/presentation/providers/route_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// getDayStops 호출 횟수를 세는 가짜 저장소. 서버 대신 stops를 그대로 돌려준다.
class _CountingRouteRepository implements RouteRepository {
  int calls = 0;
  List<RouteStop> stops = <RouteStop>[];

  @override
  Future<List<RouteStop>> getDayStops(
    String tripId,
    int day, {
    required RouteSort sort,
  }) async {
    calls++; // 재조회가 실제로 일어났는지 판정하는 기준
    return stops;
  }

  // 이 테스트가 쓰지 않는 쓰기 API — 호출되면 바로 드러나게 던진다.
  @override
  Future<RouteStop> updateStop(
    String tripId,
    int day,
    String markerId, {
    String? visitTime,
    bool clearVisitTime = false,
    TransportMode? transport,
    bool clearTransport = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> reorder(String tripId, int day, List<String> markerIds) =>
      throw UnimplementedError();
}

void main() {
  const String tripId = 't1';
  const int day = 1;

  test('마커 목록이 무효화되면 dayStops도 다시 조회한다', () async {
    final _CountingRouteRepository repo = _CountingRouteRepository();
    // 장소 추가 전/후를 흉내내기 위해 override 안에서 읽는 가변 목록
    List<TripMarker> markers = <TripMarker>[];

    final ProviderContainer container = ProviderContainer(overrides: [
      routeRepositoryProvider.overrideWithValue(repo),
      markerEntitiesProvider(tripId).overrideWith((ref) async => markers),
    ]);
    addTearDown(container.dispose);

    final provider = dayStopsProvider(tripId, day, RouteSort.order);
    // 경로 편집 시트가 화면에 떠 있는 상황 — 구독자가 있어야 autoDispose가 안 돈다
    final ProviderSubscription<AsyncValue<List<RouteStop>>> sub =
        container.listen(provider, (_, __) {});
    addTearDown(sub.close);

    await container.read(provider.future);
    expect(repo.calls, 1);

    // 장소 저장 경로가 하는 일 그대로: 마커 목록만 무효화
    // (marker_detail_sheet.dart:101, place_add_sheet.dart:73 등)
    markers = <TripMarker>[
      TripMarker(
        id: 'm1',
        tripId: tripId,
        name: '새 장소',
        latitude: 37.5,
        longitude: 127.0,
        source: MarkerSource.search,
        detail: const <String, dynamic>{},
        visitDays: const <int>[day],
        createdAt: DateTime(2026),
      ),
    ];
    repo.stops = <RouteStop>[
      const RouteStop(
        markerId: 'm1',
        name: '새 장소',
        latitude: 37.5,
        longitude: 127.0,
        order: 0,
      ),
    ];
    container.invalidate(markerEntitiesProvider(tripId));

    final List<RouteStop> stops = await container.read(provider.future);
    expect(repo.calls, 2,
        reason: '마커 변경을 구독하지 않으면 캐시된 경로 목록이 그대로 남는다');
    expect(stops.single.markerId, 'm1');
  });
}
