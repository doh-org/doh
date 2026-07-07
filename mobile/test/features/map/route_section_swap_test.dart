import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/route_section.dart';

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
}
