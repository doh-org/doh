import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/core/errors/app_exception.dart';
import 'package:doh/core/storage/token_storage.dart';
import 'package:doh/features/members/domain/entities/trip_member.dart';
import 'package:doh/features/members/presentation/pages/member_list_page.dart';
import 'package:doh/features/members/presentation/providers/member_provider.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';
import 'package:doh/features/trips/presentation/pages/trip_list_page.dart';
import 'package:doh/features/trips/presentation/providers/trip_provider.dart';

import '../../core/fake_secure_kv.dart';

// QA 계약: "목록을 불러오지 못했을 때 예외 객체를 화면에 그대로 뿌리지 않는다."
// 어떤 UI(모달/배너)로 고치든 지켜져야 할 불변식이라, 특정 문구가 아니라
// "날것 예외 문자열이 노출되지 않는지"를 검증한다.
// AppException은 toString을 재정의하지 않으므로 '$e'는 "Instance of ..."가 된다.

// authNotifier.build가 secure storage 대신 인메모리 fake를 읽게 하는 override.
// (토큰 없음 → 유저 null → 닉네임 '' 로 안전하게 렌더)
Override _fakeTokenStorage() =>
    tokenStorageProvider.overrideWithValue(TokenStorage(FakeSecureKv()));

// 화면 어디에도 날것 예외 흔적이 없어야 한다.
void _expectNoRawException(WidgetTester tester) {
  expect(find.textContaining('Instance of'), findsNothing,
      reason: '예외 객체가 화면에 그대로 노출됨');
  expect(find.textContaining('Exception'), findsNothing,
      reason: '예외 타입명이 화면에 그대로 노출됨');
  expect(find.textContaining('DioException'), findsNothing,
      reason: 'Dio 예외가 화면에 그대로 노출됨');
}

void main() {
  testWidgets('여행 목록 로드 실패 → 날것 예외를 화면에 뿌리지 않는다',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          _fakeTokenStorage(),
          // 목록 provider가 네트워크 실패를 던지도록 주입
          tripsProvider.overrideWith(
            (Ref ref) => Future<List<Trip>>.error(const NetworkException()),
          ),
        ],
        child: const MaterialApp(home: TripListPage()),
      ),
    );
    await tester.pumpAndSettle();
    // authNotifier.build의 "스플래시 최소 1초" 타이머를 소진시킨다
    // (안 하면 테스트 종료 시 pending timer로 실패)
    await tester.pump(const Duration(seconds: 1));

    _expectNoRawException(tester);
  });

  testWidgets('멤버 목록 로드 실패 → 날것 예외를 화면에 뿌리지 않는다',
      (WidgetTester tester) async {
    const String tripId = 't1';
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          _fakeTokenStorage(),
          membersProvider(tripId).overrideWith(
            (Ref ref) =>
                Future<List<TripMember>>.error(const NetworkException()),
          ),
        ],
        child: const MaterialApp(home: MemberListPage(tripId: tripId)),
      ),
    );
    await tester.pumpAndSettle();

    _expectNoRawException(tester);
  });
}
