import 'package:doh/core/storage/guest_store.dart';
import 'package:doh/features/markers/data/repositories/marker_local_repository.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';
import 'package:doh/features/routes/data/repositories/route_local_repository.dart';
import 'package:doh/features/routes/domain/entities/route_stop.dart';
import 'package:doh/features/trips/data/repositories/trip_local_repository.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late GuestStore store;

  setUp(() {
    // 매 테스트 독립: 인메모리 prefs로 교체
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    store = GuestStore(SharedPreferencesAsync());
  });

  group('TripLocalRepository', () {
    test('생성→조회 왕복, id·ownerId 로컬 생성', () async {
      final repo = TripLocalRepository(store);
      final Trip created = await repo.createTrip(title: '도쿄 3박');

      expect(created.id, isNotEmpty);
      expect(created.ownerId, 'guest');

      final List<Trip> trips = await repo.getTrips();
      expect(trips.length, 1);
      expect(trips.first.title, '도쿄 3박');
    });

    test('수정은 전달 필드만 바꾸고 미전달은 유지', () async {
      final repo = TripLocalRepository(store);
      final Trip t = await repo.createTrip(title: '부산', description: '원본');

      final Trip updated = await repo.updateTrip(t.id, title: '부산 수정');
      expect(updated.title, '부산 수정');
      expect(updated.description, '원본'); // 미전달 → 유지
    });

    test('삭제 시 마커도 함께 정리', () async {
      final trips = TripLocalRepository(store);
      final markers = MarkerLocalRepository(store);
      final Trip t = await trips.createTrip(title: 'x');
      await markers.createMarker(
        tripId: t.id,
        name: '스타벅스',
        latitude: 37.5,
        longitude: 127.0,
        source: MarkerSource.share,
      );

      await trips.deleteTrip(t.id);
      expect(await trips.getTrips(), isEmpty);
      expect(await markers.getMarkers(t.id, 0), isEmpty);
    });

    test('getTrips markerNum이 로컬 마커 수를 반영', () async {
      final trips = TripLocalRepository(store);
      final markers = MarkerLocalRepository(store);
      final Trip t = await trips.createTrip(title: 'x');
      await markers.createMarker(
        tripId: t.id,
        name: 'a',
        latitude: 1,
        longitude: 1,
        source: MarkerSource.search,
      );

      final List<Trip> list = await trips.getTrips();
      expect(list.single.markerNum, 1);
    });
  });

  group('MarkerLocalRepository', () {
    test('기본 카테고리 5종(식당·카페·관광·숙소·기타)', () async {
      final repo = MarkerLocalRepository(store);
      final cats = await repo.getCategories('any-trip');
      expect(cats.map((c) => c.name).toList(),
          ['식당', '카페', '관광', '숙소', '기타']);
    });

    test('카테고리 해제(clearCategoryId) 반영', () async {
      final repo = MarkerLocalRepository(store);
      final m = await repo.createMarker(
        tripId: 't',
        name: 'a',
        latitude: 1,
        longitude: 1,
        categoryId: 'cat_cafe',
        source: MarkerSource.search,
      );
      expect(m.categoryId, 'cat_cafe');

      final updated =
          await repo.updateMarker('t', m.id, clearCategoryId: true);
      expect(updated.categoryId, isNull);
    });
  });

  group('RouteLocalRepository', () {
    test('마커에서 Day stop 파생 + reorder 반영', () async {
      final markers = MarkerLocalRepository(store);
      final routes = RouteLocalRepository(store);

      final a = await markers.createMarker(
        tripId: 't',
        name: 'A',
        latitude: 1,
        longitude: 1,
        source: MarkerSource.search,
        visitDays: [1],
      );
      final b = await markers.createMarker(
        tripId: 't',
        name: 'B',
        latitude: 2,
        longitude: 2,
        source: MarkerSource.search,
        visitDays: [1],
      );

      List<RouteStop> stops =
          await routes.getDayStops('t', 1, sort: RouteSort.order);
      expect(stops.map((s) => s.markerId), [a.id, b.id]); // 생성순

      await routes.reorder('t', 1, [b.id, a.id]);
      stops = await routes.getDayStops('t', 1, sort: RouteSort.order);
      expect(stops.map((s) => s.markerId), [b.id, a.id]); // 뒤집힘
      expect(stops.map((s) => s.order), [0, 1]); // 연속 재부여
    });

    test('updateStop 방문시간 저장·정렬, 거리/시간은 null', () async {
      final markers = MarkerLocalRepository(store);
      final routes = RouteLocalRepository(store);
      final a = await markers.createMarker(
        tripId: 't',
        name: 'A',
        latitude: 1,
        longitude: 1,
        source: MarkerSource.search,
        visitDays: [1],
      );

      final RouteStop s =
          await routes.updateStop('t', 1, a.id, visitTime: '09:30:00');
      expect(s.visitTime, '09:30:00');
      expect(s.distanceToNext, isNull);
      expect(s.durationToNext, isNull);
    });
  });
}
