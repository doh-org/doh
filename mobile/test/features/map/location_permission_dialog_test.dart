import 'package:doh/features/map/presentation/widgets/location_permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _DialogHarness extends StatelessWidget {
  const _DialogHarness({required this.onResult});
  final void Function(bool?) onResult;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext ctx) => ElevatedButton(
            onPressed: () async =>
                onResult(await showLocationPermissionDialog(ctx)),
            child: const Text('go'),
          ),
        ),
      ),
    );
  }
}

void main() {
  Future<bool?> runDialog(WidgetTester tester, String tapLabel) async {
    bool? result;
    bool called = false;
    await tester.pumpWidget(
      _DialogHarness(onResult: (bool? r) {
        result = r;
        called = true;
      }),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(tapLabel));
    await tester.pumpAndSettle();
    expect(called, isTrue);
    return result;
  }

  testWidgets('[설정 열기] 탭 → true 반환', (WidgetTester tester) async {
    expect(await runDialog(tester, '설정 열기'), isTrue);
  });

  testWidgets('[닫기] 탭 → false 반환', (WidgetTester tester) async {
    expect(await runDialog(tester, '닫기'), isFalse);
  });
}
