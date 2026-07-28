import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/core/errors/app_exception.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:doh/features/trips/domain/repositories/trip_repository.dart';
import 'package:doh/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:doh/features/trips/presentation/pages/trip_create_page.dart';

// QA 계약: 쓰기(액션) 실패는 통일 모달(UpdateErrorDialog)로 안내한다.
// 각 repo가 실패를 던지도록 주입하고, 액션을 눌러 모달 문구가 뜨는지 검증.
//
// 지도(map_page)의 마커삭제·검색 실패는 flutter_naver_map 네이티브 뷰라
// 위젯 테스트에서 지도가 렌더되지 않아 자동화 불가 → 코드리뷰+수동으로 남김.

// ── fakes ──────────────────────────────────────────────
// 모든 쓰기 메서드가 네트워크 실패를 던진다. 조회는 최소 데이터만 반환.
class _FailingTripRepo implements TripRepository {
  const _FailingTripRepo(this._trip);
  final Trip _trip;

  @override
  Future<List<Trip>> getTrips() async => <Trip>[_trip];

  @override
  Future<Trip> getTrip(String tripId) async => _trip;

  @override
  Future<Trip> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async =>
      throw const NetworkException();

  @override
  Future<Trip> updateTrip(
    String tripId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async =>
      throw const NetworkException();

  @override
  Future<void> deleteTrip(String tripId) async => throw const NetworkException();
}

// 편집 모드 프리필용 여행(날짜 있음 → CTA가 검증 통과)
final Trip _trip = Trip(
  id: 't1',
  ownerId: 'u1',
  title: '테스트 여행',
  startDate: DateTime(2026, 1, 1),
  endDate: DateTime(2026, 1, 2),
  createdAt: DateTime(2026, 1, 1),
);

// 통일 모달이 뜬 뒤, 1.5초 자동소멸 타이머를 소진해 펜딩 타이머 경고를 막는다.
Future<void> _drainAutoDismiss(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

void main() {
  testWidgets('여행 수정 실패 → 통일 모달로 안내', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          tripRepositoryProvider.overrideWithValue(_FailingTripRepo(_trip)),
        ],
        child: const MaterialApp(home: TripCreatePage(tripId: 't1')),
      ),
    );
    await tester.pumpAndSettle(); // _loadExisting: 제목·날짜 프리필

    final Finder cta = find.widgetWithText(ElevatedButton, '수정 완료');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pump(); // _submit 시작(스피너)
    await tester.pump(const Duration(milliseconds: 300)); // 실패 → 모달

    expect(find.text('여행을 수정하지 못했어요.'), findsOneWidget);
    await _drainAutoDismiss(tester);
  });

  testWidgets('여행 삭제 실패 → 통일 모달로 안내', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          tripRepositoryProvider.overrideWithValue(_FailingTripRepo(_trip)),
        ],
        child: const MaterialApp(home: TripCreatePage(tripId: 't1')),
      ),
    );
    await tester.pumpAndSettle();

    final Finder delBtn = find.widgetWithText(ElevatedButton, '폴더 삭제');
    await tester.ensureVisible(delBtn);
    await tester.pumpAndSettle();
    await tester.tap(delBtn);
    await tester.pumpAndSettle(); // 삭제 확인 모달

    await tester.tap(find.text('삭제')); // 확인
    await tester.pump(); // _confirmDelete 시작
    await tester.pump(const Duration(milliseconds: 300)); // 실패 → 모달

    expect(find.text('여행을 삭제하지 못했어요.'), findsOneWidget);
    await _drainAutoDismiss(tester);
  });
}
