import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/utils/detail_panel_key.dart';
import 'package:doh/features/map/presentation/widgets/marker_detail_panel.dart';
import 'package:doh/features/map/presentation/widgets/marker_detail_sheet.dart';
import 'package:doh/features/markers/data/repositories/marker_repository_impl.dart';
import 'package:doh/features/markers/domain/entities/category.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';
import 'package:doh/features/markers/domain/repositories/marker_repository.dart';
import 'package:doh/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:doh/features/trips/domain/repositories/trip_repository.dart';

const String _tempId = '__new__';

class _FakeMarkerRepository implements MarkerRepository {
  @override
  Future<List<Category>> getCategories(String tripId) async => <Category>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeTripRepository implements TripRepository {
  @override
  Future<Trip> getTrip(String tripId) async => Trip(
        id: tripId,
        ownerId: 'u',
        title: '여행',
        createdAt: DateTime(2026, 1, 1),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TripMarker _tempMarker(String name) => TripMarker(
      id: _tempId,
      tripId: 't1',
      name: name,
      latitude: 37.0,
      longitude: 127.0,
      source: MarkerSource.search,
      detail: const <String, dynamic>{},
      createdAt: DateTime(2026, 1, 1),
    );

Future<void> _pumpPanel(
  WidgetTester tester,
  TripMarker marker,
  int session,
) async {
  await tester.pumpWidget(ProviderScope(
    overrides: <Override>[
      markerRepositoryProvider.overrideWith((ref) => _FakeMarkerRepository()),
      tripRepositoryProvider.overrideWith((ref) => _FakeTripRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            MarkerDetailPanel(
              key: detailPanelKey(marker.id, session),
              peeked: false,
              onPeek: () {},
              onExpand: () {},
              onClose: () {},
              child: MarkerDetailSheet(
                marker: marker,
                tripId: 't1',
                allMarkers: const <TripMarker>[],
              ),
            ),
          ],
        ),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  test('임시 마커는 id가 같아도 회차가 다르면 키가 달라진다', () {
    expect(detailPanelKey(_tempId, 1), detailPanelKey(_tempId, 1));
    expect(detailPanelKey(_tempId, 1), isNot(detailPanelKey(_tempId, 2)));
  });

  testWidgets('상세 패널이 열린 채 다른 POI를 누르면 두 번째 장소가 표시된다',
      (WidgetTester tester) async {
    await _pumpPanel(tester, _tempMarker('장소1'), 1);
    expect(find.text('장소1'), findsWidgets);

    await _pumpPanel(tester, _tempMarker('장소2'), 2);

    expect(find.text('장소2'), findsWidgets);
    expect(find.text('장소1'), findsNothing);
  });

  testWidgets('회차를 안 올리면 State가 재사용돼 첫 장소가 남는다(버그 재현)',
      (WidgetTester tester) async {
    await _pumpPanel(tester, _tempMarker('장소1'), 1);

    await _pumpPanel(tester, _tempMarker('장소2'), 1);

    expect(find.text('장소1'), findsWidgets);
    expect(find.text('장소2'), findsNothing);
  });
}
