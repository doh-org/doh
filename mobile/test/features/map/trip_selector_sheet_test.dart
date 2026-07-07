import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/trip_selector_sheet.dart';
import 'package:doh/features/trips/domain/entities/trip.dart';

// 폴더 n개 생성 헬퍼
List<Trip> _trips(int n) => List<Trip>.generate(
      n,
      (int i) => Trip(
        id: 't$i',
        ownerId: 'u1',
        title: '여행 $i',
        createdAt: DateTime(2026, 1, 1),
      ),
    );

// 바텀 시트가 갖는 최대 높이 제약을 흉내 (최대 400, 내용이 적으면 더 작게)
Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: child,
          ),
        ),
      ),
    );

void main() {
  // 회귀 테스트: 폴더가 시트 높이보다 많으면 47px 오버플로우가 났던 버그
  testWidgets('폴더가 많아도 오버플로우 없이 스크롤된다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(TripSelectorSheet(
      trips: _trips(20),
      currentTripId: 't0',
      onSelected: (String _) {},
    )));

    // 오버플로우가 나면 프레임워크가 예외를 보고해 테스트가 실패함
    expect(tester.takeException(), isNull);
    // 목록이 스크롤 가능한 ListView로 렌더링되는지 확인
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('폴더가 적으면 내용 높이만큼만 차지한다', (WidgetTester tester) async {
    await tester.pumpWidget(_wrap(TripSelectorSheet(
      trips: _trips(2),
      currentTripId: 't0',
      onSelected: (String _) {},
    )));

    expect(tester.takeException(), isNull);
    // shrinkWrap 덕에 시트가 주어진 400보다 작게 렌더링돼야 함
    final double sheetHeight =
        tester.getSize(find.byType(TripSelectorSheet)).height;
    expect(sheetHeight, lessThan(400));
  });
}
