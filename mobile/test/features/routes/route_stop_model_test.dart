import 'package:doh/features/routes/data/models/route_stop_model.dart';
import 'package:doh/features/routes/domain/entities/route_stop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteStopModel.fromJson → toEntity', () {
    test('전체 필드 매핑', () {
      final stop = RouteStopModel.fromJson(<String, dynamic>{
        'marker_id': 'm1',
        'name': '투썸플레이스',
        'latitude': 37.5,
        'longitude': 127.0,
        'category_id': 'c1',
        'order': 2,
        'visit_time': '14:30:00',
        'transport_to_next': 'publictransit',
        'distance_to_next': 1200.5,
        'duration_to_next': 600,
      }).toEntity();

      expect(stop.markerId, 'm1');
      expect(stop.order, 2);
      expect(stop.visitTime, '14:30:00');
      expect(stop.transportToNext, TransportMode.publictransit);
      expect(stop.distanceToNext, 1200.5);
      expect(stop.durationToNext, 600);
    });

    test('null 구간 필드(마지막 stop) 매핑', () {
      final stop = RouteStopModel.fromJson(<String, dynamic>{
        'marker_id': 'm2',
        'name': '끝',
        'latitude': 0,
        'longitude': 0,
        'order': 3,
        'visit_time': null,
        'transport_to_next': null,
        'distance_to_next': null,
        'duration_to_next': null,
      }).toEntity();

      expect(stop.visitTime, isNull);
      expect(stop.transportToNext, isNull);
      expect(stop.distanceToNext, isNull);
    });
  });

  test('RouteSort.query', () {
    expect(RouteSort.visitTime.query, 'visit_time');
    expect(RouteSort.order.query, 'order');
  });
}
