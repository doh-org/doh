import 'package:dio/dio.dart';
import 'package:doh/features/routes/data/datasources/route_remote_datasource.dart';
import 'package:doh/features/routes/data/models/route_stop_model.dart';
import 'package:doh/features/routes/data/repositories/route_repository_impl.dart';
import 'package:doh/features/routes/domain/entities/route_stop.dart';
import 'package:flutter_test/flutter_test.dart';

/// updateStop body만 캡처하는 가짜 datasource (Dio 미사용).
class _FakeDatasource extends RouteRemoteDatasource {
  _FakeDatasource() : super(Dio());

  Map<String, dynamic>? lastBody;
  List<String>? lastReorder;

  @override
  Future<RouteStopModel> updateStop(
      String tripId, int day, String markerId, Map<String, dynamic> body) async {
    lastBody = body;
    return RouteStopModel(
        markerId: markerId, name: 'x', latitude: 0, longitude: 0, order: 1);
  }

  @override
  Future<int> reorder(String tripId, int day, List<String> markerIds) async {
    lastReorder = markerIds;
    return markerIds.length;
  }
}

void main() {
  late _FakeDatasource ds;
  late RouteRepositoryImpl repo;

  setUp(() {
    ds = _FakeDatasource();
    repo = RouteRepositoryImpl(ds);
  });

  group('updateStop 3상태 body 매핑', () {
    test('이동수단 설정', () async {
      await repo.updateStop('t', 1, 'm', transport: TransportMode.car);
      expect(ds.lastBody, {'transport_to_next': 'car'});
    });

    test('이동수단 해제(clear)', () async {
      await repo.updateStop('t', 1, 'm', clearTransport: true);
      expect(ds.lastBody, {'transport_to_next': null});
    });

    test('방문시간 설정', () async {
      await repo.updateStop('t', 1, 'm', visitTime: '14:30');
      expect(ds.lastBody, {'visit_time': '14:30'});
    });

    test('미전달 시 빈 body', () async {
      await repo.updateStop('t', 1, 'm');
      expect(ds.lastBody, isEmpty);
    });
  });

  test('reorder는 marker_ids 순서를 그대로 전달', () async {
    final n = await repo.reorder('t', 1, ['a', 'b', 'c']);
    expect(ds.lastReorder, ['a', 'b', 'c']);
    expect(n, 3);
  });
}
