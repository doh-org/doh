import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/place_list_sheet.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';

// 에러 배너가 보이는 상태의 시트 생성 헬퍼
Widget _sheet(ScrollController controller) => PlaceListSheet(
      scrollController: controller,
      placeCount: 0,
      tripTitle: '테스트 여행',
      dayCount: 0,
      selectedDay: 0,
      onDaySelected: (int _) {},
      markers: const <TripMarker>[],
      categoryMap: const {},
      hasError: true,
      canEditRoute: false,
      onEditRoute: () {},
      onMarkerTap: (TripMarker _) {},
      onDelete: (TripMarker _) {},
    );

void main() {
  // 회귀 테스트: 에러 배너의 고정 height:50에 두 줄 텍스트가 안 들어가
  // 오버플로우 나던 버그. 큰 글꼴 배율에서 특히 심했음.
  testWidgets('에러 배너: 큰 글꼴 배율에서도 오버플로우 없음', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        // 시스템 글꼴 크기 2배 상황을 흉내
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: Scaffold(body: _sheet(controller)),
      ),
    ));

    // 오버플로우가 나면 프레임워크가 예외를 보고해 테스트가 실패함
    expect(tester.takeException(), isNull);
    expect(find.text('장소 목록을 불러오지 못했습니다'), findsOneWidget);
  });

  testWidgets('에러 배너: 기본 배율에서도 오버플로우 없음', (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: _sheet(controller)),
    ));

    expect(tester.takeException(), isNull);
  });
}
