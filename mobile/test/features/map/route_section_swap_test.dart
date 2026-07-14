import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/route_section.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';

// 테스트용 마커 생성 헬퍼
TripMarker _marker({required String id, required String name}) => TripMarker(
      id: id,
      tripId: 'trip-1',
      name: name,
      latitude: 37.5,
      longitude: 127.0,
      source: MarkerSource.search,
      detail: const {},
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('swapRoutePoints', () {
    // 회귀: 출발지가 현위치(null)일 때 목적지에 마커 id가 되채워지던 버그
    test('출발지 현위치 ↔ 목적지 마커 → 목적지가 현위치가 된다', () {
      final swapped =
          swapRoutePoints(departureId: null, destinationId: 'marker-a');
      expect(swapped.departureId, 'marker-a');
      expect(swapped.destinationId, isNull); // 현위치
    });

    test('마커 ↔ 마커 → 서로 교환', () {
      final swapped =
          swapRoutePoints(departureId: 'marker-a', destinationId: 'marker-b');
      expect(swapped.departureId, 'marker-b');
      expect(swapped.destinationId, 'marker-a');
    });

    test('목적지 현위치 → 다시 스왑하면 출발지 현위치로 복귀', () {
      final swapped =
          swapRoutePoints(departureId: 'marker-a', destinationId: null);
      expect(swapped.departureId, isNull); // 현위치
      expect(swapped.destinationId, 'marker-a');
    });
  });

  group('resolveRoutePointName', () {
    final TripMarker temp = _marker(id: 'temp-1', name: '임시 장소');
    final List<TripMarker> saved = [
      _marker(id: 'marker-a', name: '저장된 장소'),
    ];

    // 회귀: 미저장 임시 마커가 목적지일 때 '알 수 없음'으로 뜨던 버그
    test('임시 마커(allMarkers에 없음) → 현재 마커 이름', () {
      final String name = resolveRoutePointName(
          id: 'temp-1', currentMarker: temp, allMarkers: saved);
      expect(name, '임시 장소');
    });

    test('저장된 마커 id → allMarkers에서 이름 조회', () {
      final String name = resolveRoutePointName(
          id: 'marker-a', currentMarker: temp, allMarkers: saved);
      expect(name, '저장된 장소');
    });

    test('null → 현위치', () {
      final String name = resolveRoutePointName(
          id: null, currentMarker: temp, allMarkers: saved);
      expect(name, '현위치');
    });

    test('어디에도 없는 id → 알 수 없음', () {
      final String name = resolveRoutePointName(
          id: 'ghost', currentMarker: temp, allMarkers: saved);
      expect(name, '알 수 없음');
    });
  });
}
