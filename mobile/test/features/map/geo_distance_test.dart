import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/utils/geo_distance.dart';

void main() {
  group('haversineMeters', () {
    test('같은 좌표 → 0m', () {
      expect(haversineMeters(37.5665, 126.9780, 37.5665, 126.9780), 0);
    });

    test('서울시청 → 강남역 ≈ 8.4km', () {
      // 서울시청(37.5665, 126.9780) → 강남역(37.4979, 126.9276이 아닌 127.0276)
      final double d =
          haversineMeters(37.5665, 126.9780, 37.4979, 127.0276);
      expect(d, greaterThan(8000));
      expect(d, lessThan(9500));
    });

    test('위도 1도 차이 ≈ 111km', () {
      final double d = haversineMeters(37.0, 127.0, 38.0, 127.0);
      expect(d, closeTo(111195, 500)); // 지구 둘레/360
    });

    test('50m 반경 판정 경계: 아주 가까운 두 점', () {
      // 위도 0.0004도 ≈ 44m → 50m 이내
      final double d = haversineMeters(37.5665, 126.9780, 37.5669, 126.9780);
      expect(d, lessThan(50));
    });
  });
}
