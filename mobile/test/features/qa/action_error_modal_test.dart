import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/core/errors/app_exception.dart';
import 'package:doh/features/members/domain/entities/trip_member.dart';
import 'package:doh/features/members/domain/repositories/member_repository.dart';
import 'package:doh/features/members/data/repositories/member_repository_impl.dart';
import 'package:doh/features/members/presentation/pages/member_list_page.dart';
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

class _FailingMemberRepo implements MemberRepository {
  @override
  Future<List<TripMember>> getMembers(String tripId) async =>
      const <TripMember>[];

  @override
  Future<Invitation> inviteMember(String tripId, String email) async =>
      throw const NetworkException();

  @override
  Future<void> removeMember(String tripId, String userId) async {}
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
  testWidgets('멤버 초대 실패 → 통일 모달로 안내', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          memberRepositoryProvider.overrideWithValue(_FailingMemberRepo()),
        ],
        child: const MaterialApp(home: MemberListPage(tripId: 't1')),
      ),
    );
    await tester.pumpAndSettle(); // 빈 멤버 목록 렌더

    // 초대 다이얼로그 열기 → 이메일 입력 → 초대
    await tester.tap(find.byIcon(Icons.person_add_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a@b.com');
    await tester.tap(find.widgetWithText(FilledButton, '초대'));
    await tester.pump(); // 비동기 초대 시작
    await tester.pump(const Duration(milliseconds: 300)); // 실패 → 모달 표시

    expect(find.text('초대에 실패했습니다.'), findsOneWidget);
    await _drainAutoDismiss(tester);
  });

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
