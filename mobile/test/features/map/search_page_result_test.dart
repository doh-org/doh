import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/pages/search_page.dart';
import 'package:doh/features/markers/domain/entities/category.dart';
import 'package:doh/features/markers/domain/entities/marker.dart';
import 'package:doh/features/markers/presentation/providers/marker_provider.dart';
import 'package:doh/shared/widgets/app_back_button.dart';

// 회귀 테스트: 검색 결과 매칭이 없어도 입력 중이던 검색어를 지도로 넘겨야
// "현위치에서 검색"을 할 수 있다. 예전엔 뒤로가기가 아무것도 반환하지 않아
// 검색어가 사라졌고, 그러면 현위치 검색 버튼이 비활성으로 남았다.

const String _tripId = 't1';

TripMarker _marker(String name) => TripMarker(
      id: 'm1',
      tripId: _tripId,
      name: name,
      latitude: 37.5,
      longitude: 127.0,
      source: MarkerSource.longpress,
      detail: const <String, dynamic>{},
      createdAt: DateTime(2026, 1, 1),
    );

// 페이지가 닫힌 뒤에야 반환값을 알 수 있어서, 상자에 담아두고 나중에 꺼내 본다
class _Popped {
  SearchPageResult? value;
}

// SearchPage를 실제로 push해서 띄운다 (반환값을 봐야 하므로 직접 push)
Future<_Popped> _openSearchPage(
  WidgetTester tester, {
  List<TripMarker> markers = const <TripMarker>[],
}) async {
  final _Popped box = _Popped();

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        markerEntitiesProvider(_tripId)
            .overrideWith((Ref ref) => Future<List<TripMarker>>.value(markers)),
        categoriesProvider(_tripId)
            .overrideWith((Ref ref) => Future<List<Category>>.value(const [])),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              box.value = await Navigator.push<SearchPageResult>(
                context,
                MaterialPageRoute<SearchPageResult>(
                  builder: (_) => const SearchPage(tripId: _tripId, trip: null),
                ),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
  return box;
}

void main() {
  testWidgets('뒤로가기 → (null, 검색어)를 반환한다', (WidgetTester tester) async {
    final _Popped box = await _openSearchPage(tester);

    await tester.enterText(find.byType(TextField), '다이소');
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(box.value, isNotNull);
    final (Object? selection, String query) = box.value!;
    expect(selection, isNull, reason: '고른 장소가 없어야 함');
    expect(query, '다이소', reason: '입력 중이던 검색어가 실려 나와야 함');
  });

  testWidgets('시스템 뒤로가기 → PopScope가 검색어를 실어 보낸다',
      (WidgetTester tester) async {
    final _Popped box = await _openSearchPage(tester);

    await tester.enterText(find.byType(TextField), '성수');
    await tester.pumpAndSettle();

    // 시스템 백·스와이프 백은 maybePop을 타고, 그걸 PopScope가 가로챈다
    await Navigator.maybePop(tester.element(find.byType(SearchPage)));
    await tester.pumpAndSettle();

    expect(box.value, isNotNull);
    final (Object? selection, String query) = box.value!;
    expect(selection, isNull);
    expect(query, '성수');
  });

  testWidgets('저장된 마커 탭 → (마커, 검색어)를 반환한다', (WidgetTester tester) async {
    final TripMarker saved = _marker('다이소 성수점');
    final _Popped box =
        await _openSearchPage(tester, markers: <TripMarker>[saved]);

    await tester.enterText(find.byType(TextField), '다이소');
    await tester.pumpAndSettle();

    await tester.tap(find.text('다이소 성수점'));
    await tester.pumpAndSettle();

    expect(box.value, isNotNull);
    final (Object? selection, String query) = box.value!;
    expect(selection, same(saved));
    expect(query, '다이소', reason: '마커를 골라도 검색어는 함께 넘어가야 함');
  });

  testWidgets('빈 검색어로 뒤로가기 → 검색어가 빈 문자열', (WidgetTester tester) async {
    final _Popped box = await _openSearchPage(tester);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(box.value, isNotNull);
    final (Object? selection, String query) = box.value!;
    expect(selection, isNull);
    expect(query, isEmpty, reason: '지도 쪽에서 null 처리로 힌트를 되살린다');
  });
}
