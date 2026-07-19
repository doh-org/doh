import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

TripMarker _marker(Map<String, dynamic> detail) => TripMarker(
      id: 'm1',
      tripId: 't1',
      name: '테스트 장소',
      latitude: 37.0,
      longitude: 127.0,
      source: MarkerSource.search,
      detail: detail,
      createdAt: DateTime(2026, 1, 1),
    );

Future<void> _pumpSheet(WidgetTester tester, TripMarker marker) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      markerRepositoryProvider.overrideWith((ref) => _FakeMarkerRepository()),
      tripRepositoryProvider.overrideWith((ref) => _FakeTripRepository()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: MarkerDetailSheet(
          marker: marker,
          tripId: 't1',
          allMarkers: [marker],
        ),
      ),
    ),
  ));
  await tester.pump(); // 비동기 provider(카테고리·여행) 결과 반영
}

void main() {
  testWidgets('구 키(naver_)만 있는 마커 → 구 키로 주소·전화 표시',
      (WidgetTester tester) async {
    await _pumpSheet(
      tester,
      _marker({'naver_address': '구주소 1', 'naver_phone': '02-000-0000'}),
    );

    expect(find.text('구주소 1'), findsOneWidget);
    expect(find.text('02-000-0000'), findsOneWidget);
  });

  testWidgets('신 키 마커 → 신 키로 주소·전화 표시', (WidgetTester tester) async {
    await _pumpSheet(
      tester,
      _marker({'address': '신주소 1', 'phone': '02-111-1111'}),
    );

    expect(find.text('신주소 1'), findsOneWidget);
    expect(find.text('02-111-1111'), findsOneWidget);
  });
}
