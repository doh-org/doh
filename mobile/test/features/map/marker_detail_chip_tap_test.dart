import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/marker_detail_panel.dart';
import 'package:doh/features/map/presentation/widgets/marker_detail_sheet.dart';
import 'package:doh/features/markers/data/repositories/marker_repository_impl.dart';
import 'package:doh/features/markers/domain/entities/category.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';
import 'package:doh/features/markers/domain/repositories/marker_repository.dart';
import 'package:doh/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:doh/features/trips/domain/repositories/trip_repository.dart';

// 상세 시트 렌더에 필요한 조회만 채운 가짜 repo (나머지는 미사용)
class _FakeMarkerRepository implements MarkerRepository {
  @override
  Future<List<Category>> getCategories(String tripId) async => <Category>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

// Day 칩이 나오려면 여행에 기간이 있어야 한다(1박 2일)
class _FakeTripRepository implements TripRepository {
  @override
  Future<Trip> getTrip(String tripId) async => Trip(
        id: tripId,
        ownerId: 'u',
        title: '여행',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 2),
        createdAt: DateTime(2026, 1, 1),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final TripMarker _marker = TripMarker(
  id: 'm1',
  tripId: 't1',
  name: '테스트 장소',
  latitude: 37.0,
  longitude: 127.0,
  source: MarkerSource.search,
  detail: const <String, dynamic>{},
  visitDays: const <int>[1],
  createdAt: DateTime(2026, 1, 1),
);

// 지도 화면과 같은 조합: 상세 시트를 드래그 패널 안에 넣어 띄운다.
// 패널의 드래그존이 시트 상단을 덮는 구조라 이 조합이어야 회귀를 잡는다.
Future<void> _pumpPanel(WidgetTester tester) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      markerRepositoryProvider.overrideWith((ref) => _FakeMarkerRepository()),
      tripRepositoryProvider.overrideWith((ref) => _FakeTripRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            MarkerDetailPanel(
              peeked: false,
              onPeek: () {},
              onExpand: () {},
              onClose: () {},
              child: MarkerDetailSheet(
                marker: _marker,
                tripId: 't1',
                allMarkers: <TripMarker>[_marker],
              ),
            ),
          ],
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle(); // 높이 측정(post-frame) + 비동기 provider 반영
}

void main() {
  testWidgets('카테고리 칩 탭 → 편집 시트가 열린다', (WidgetTester tester) async {
    await _pumpPanel(tester);

    // 칩 중심은 패널 상단에서 36px 부근 — 드래그존(옛 40)이 덮으면 탭이 먹히지 않는다
    await tester.tapAt(tester.getRect(find.text('없음')).center);
    await tester.pumpAndSettle();

    expect(find.text('방문 날짜'), findsOneWidget,
        reason: '드래그존이 칩 행을 덮으면 편집 시트가 열리지 않는다');
  });

  testWidgets('칩 사이 간격 탭 → 편집 시트가 열린다', (WidgetTester tester) async {
    await _pumpPanel(tester);

    // 두 칩의 텍스트 사이 = 칩 간격(6px)의 한가운데.
    // deferToChild면 이 지점은 빈 공간이라 탭이 통과한다
    final Rect categoryChip = tester.getRect(find.text('없음'));
    final Rect dayChip = tester.getRect(find.text('Day1'));
    await tester.tapAt(Offset(
      (categoryChip.right + dayChip.left) / 2,
      categoryChip.center.dy,
    ));
    await tester.pumpAndSettle();

    expect(find.text('방문 날짜'), findsOneWidget,
        reason: 'opaque가 아니면 칩 사이 간격은 탭이 통과한다');
  });
}
