import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:doh/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:doh/features/trips/domain/repositories/trip_repository.dart';
import 'package:doh/features/trips/presentation/providers/trip_provider.dart';
import 'package:doh/shared/widgets/bottom_nav_bar.dart';
import 'package:doh/shared/widgets/create_folder_dialog.dart';

// 지도 탭 계약: 폴더가 없으면 자동 생성('내 여행') 대신 안내 모달을 띄우고,
// 모달의 + 버튼이 여행 생성 페이지로 보낸다. 폴더가 있으면 첫 폴더 지도로 이동.

// ── fakes ──────────────────────────────────────────────
// 조회는 주입된 목록을 그대로 반환. 자동 생성이 부활하면 createCalls로 잡는다.
class _FakeTripRepo implements TripRepository {
  _FakeTripRepo(this._trips);
  final List<Trip> _trips;
  int createCalls = 0;

  @override
  Future<List<Trip>> getTrips() async => _trips;

  @override
  Future<Trip> getTrip(String tripId) async => _trips.first;

  @override
  Future<Trip> createTrip({
    required String title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async {
    createCalls++;
    return Trip(id: 'new', ownerId: 'u1', title: title, createdAt: DateTime(2026));
  }

  @override
  Future<Trip> updateTrip(
    String tripId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? coverColor,
  }) async =>
      _trips.first;

  @override
  Future<void> deleteTrip(String tripId) async {}
}

final Trip _trip = Trip(
  id: 't1',
  ownerId: 'u1',
  title: '테스트 여행',
  createdAt: DateTime(2026, 1, 1),
);

// BottomNavBar는 tripsProvider를 read만 하므로, 홈에서 watch로 미리 로드해 둔다
// (실제 앱에서 목록 페이지가 watch하는 상황과 동일).
class _Home extends ConsumerWidget {
  const _Home();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Trip>> trips = ref.watch(tripsProvider);
    return Scaffold(
      body: Center(child: Text(trips.hasValue ? '홈' : '로딩')),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

// 이동 검증용 최소 라우터 — 생성 페이지·지도 페이지는 문구만 있는 스텁.
GoRouter _router() => GoRouter(
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const _Home()),
        GoRoute(
          path: '/trips/create',
          builder: (_, __) => const Scaffold(body: Text('여행 추가 페이지')),
        ),
        GoRoute(
          path: '/trips/:tripId/map',
          builder: (_, GoRouterState s) =>
              Scaffold(body: Text('지도 ${s.pathParameters['tripId']}')),
        ),
      ],
    );

Future<void> _pumpHome(WidgetTester tester, _FakeTripRepo repo) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        tripRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(routerConfig: _router()),
    ),
  );
  await tester.pumpAndSettle(); // tripsProvider 로드 완료까지
}

void main() {
  testWidgets('폴더 없음 → 지도 탭: 자동 생성 없이 안내 모달', (WidgetTester tester) async {
    final _FakeTripRepo repo = _FakeTripRepo(<Trip>[]);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateFolderDialog), findsOneWidget);
    expect(repo.createCalls, 0); // '내 여행' 자동 생성 금지
  });

  testWidgets('안내 모달 + 버튼 → 여행 생성 페이지로 이동', (WidgetTester tester) async {
    final _FakeTripRepo repo = _FakeTripRepo(<Trip>[]);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(CreateFolderDialog),
      matching: find.byIcon(Icons.add),
    ));
    await tester.pumpAndSettle();

    expect(find.text('여행 추가 페이지'), findsOneWidget);
    expect(find.byType(CreateFolderDialog), findsNothing); // 모달 닫힘
  });

  testWidgets('폴더 있음 → 지도 탭: 첫 폴더 지도로 이동', (WidgetTester tester) async {
    final _FakeTripRepo repo = _FakeTripRepo(<Trip>[_trip]);
    await _pumpHome(tester, repo);

    await tester.tap(find.text('지도'));
    await tester.pumpAndSettle();

    expect(find.text('지도 t1'), findsOneWidget);
    expect(find.byType(CreateFolderDialog), findsNothing);
  });
}
