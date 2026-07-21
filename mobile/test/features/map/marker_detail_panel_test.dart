import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doh/features/map/presentation/widgets/marker_detail_panel.dart';

// 패널 높이를 테스트가 정해 엿보기·닫기 경계를 계산 가능하게 함.
// 내용 높이 300 → 엿보기 지점 180(=300-120), 닫기 경계 240(=(180+300)/2)
const double _contentHeight = 300;
const double _peekDy = 180; // 엿보기 상태에서 패널이 내려가 있는 거리

class _Calls {
  int peek = 0;
  int expand = 0;
  int close = 0;
}

Future<_Calls> _pumpPanel(WidgetTester tester, {bool peeked = false}) async {
  final _Calls calls = _Calls();
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          MarkerDetailPanel(
            peeked: peeked,
            onPeek: () => calls.peek++,
            onExpand: () => calls.expand++,
            onClose: () => calls.close++,
            child: Container(height: _contentHeight, color: Colors.white),
          ),
        ],
      ),
    ),
  ));
  await tester.pump(); // 높이 측정(post-frame) 반영
  return calls;
}

// 손잡이 영역(패널 상단 40px) 한가운데 좌표
Offset _handlePoint(WidgetTester tester) {
  final Size screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  return Offset(screen.width / 2, screen.height - _contentHeight + 20);
}

// 던지기(fling)로 오인되지 않게 500px/s 속도로 천천히 드래그
Future<void> _slowDrag(WidgetTester tester, double distance) async {
  final TestGesture gesture = await tester.startGesture(_handlePoint(tester));
  const int steps = 5;
  for (int i = 0; i < steps; i++) {
    await gesture.moveBy(Offset(0, distance / steps));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('손잡이를 끝까지 아래로 끌면 닫힌다', (WidgetTester tester) async {
    final _Calls calls = await _pumpPanel(tester);

    await _slowDrag(tester, 280); // 닫기 경계(240) 아래

    expect(calls.close, 1);
    expect(calls.peek, 0);
  });

  testWidgets('손잡이를 조금만 내리면 닫히지 않고 엿보기로 간다',
      (WidgetTester tester) async {
    final _Calls calls = await _pumpPanel(tester);

    await _slowDrag(tester, 200); // 엿보기(90) 위, 닫기(240) 아래

    expect(calls.peek, 1);
    expect(calls.close, 0);
  });

  testWidgets('살짝 내렸다 놓으면 원래 자리로 돌아온다', (WidgetTester tester) async {
    final _Calls calls = await _pumpPanel(tester);

    await _slowDrag(tester, 50); // 엿보기 경계(90)에도 못 미침

    expect(calls.expand, 1);
    expect(calls.close, 0);
  });

  testWidgets('엿보기 상태에서 손잡이를 탭하면 다시 펼친다', (WidgetTester tester) async {
    final _Calls calls = await _pumpPanel(tester, peeked: true);
    await tester.pumpAndSettle(); // 엿보기 위치로 내려가는 애니메이션 종료 대기

    // 내려간 만큼 손잡이도 아래에 위치
    await tester.tapAt(_handlePoint(tester) + const Offset(0, _peekDy));
    await tester.pump();

    expect(calls.expand, 1);
  });
}
